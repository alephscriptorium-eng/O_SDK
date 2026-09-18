#!/usr/bin/env bash
# deploy-teatro.sh — publica UNA obra del Teatro en el volumen de datos del VPS:
#   volumes-dev/teatro/<obra>/  →  /srv/oasis/teatro/<obra>/  →  https://<pub>/teatro/<obra>/
#
# La obra la genera el sidecar (pub/rrss-sidecar/<fuente>/sidecar.py build). La portada del Teatro
# se copia desde pub/site-templates/teatro/. La subida es reanudable (rsync --partial).
#
# Requiere rsync y python3 → en Windows corre dentro de WSL:  npm run devops:teatro:deploy
#   (= bash devops/scripts/teatro-wsl.sh deploy, que pasa las variables a WSL)
#
# Variables (entorno > host.env > default):
#   TEATRO_OBRA          OBLIGATORIA. Nombre de la obra ([a-z0-9-]), p. ej. aleph-cero
#   LOCAL_TEATRO_DIR     árbol local (default: <repo>/volumes-dev/teatro)
#   REMOTE_TEATRO_DIR    destino en el VPS (default: /srv/oasis/teatro)
#   TEATRO_DRY_RUN=1     solo enseña lo que rsync haría (incluido lo que --delete borraría)
#   TEATRO_DELETE=1      espejo exacto DENTRO de <obra>/ (nunca fuera). Revisa antes un DRY_RUN
#   TEATRO_SKIP_ZIP=1    no (re)generar los zips remotos
#   TEATRO_SKIP_VERIFY=1 no ejecutar la verificación post-deploy
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Datos de instancia → devops/hosts/<DEVOPS_HOST>/host.env
# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib-host.sh"
REPO_ROOT="$(cd "$DEVOPS_DIR/.." && pwd)"

OBRA="${TEATRO_OBRA:-}"
[[ "$OBRA" =~ ^[a-z0-9][a-z0-9-]*$ ]] || { echo "ERROR: define TEATRO_OBRA=<obra> ([a-z0-9-])"; exit 2; }
KEY_PATH="${KEY_PATH:-}"
REMOTE_USER="${REMOTE_USER:-}"
REMOTE_HOST="${REMOTE_HOST:-}"
PUB_HOST="${PUB_HOST:-pub.escrivivir.co}"
LOCAL_TEATRO_DIR="${LOCAL_TEATRO_DIR:-$REPO_ROOT/volumes-dev/teatro}"
REMOTE_TEATRO_DIR="${REMOTE_TEATRO_DIR:-/srv/oasis/teatro}"
LOCAL_OBRA="$LOCAL_TEATRO_DIR/$OBRA"
REMOTE_OBRA="$REMOTE_TEATRO_DIR/$OBRA"
SIDECAR="$REPO_ROOT/pub/rrss-sidecar/twitter_x/sidecar.py"
PY="$(command -v python3 || command -v python || true)"

[[ -f "$KEY_PATH" ]]              || { echo "ERROR: clave SSH no encontrada: $KEY_PATH"; exit 1; }
[[ -f "$LOCAL_OBRA/index.html" ]] || { echo "ERROR: no hay obra en $LOCAL_OBRA (npm run teatro:build -- --obra $OBRA)"; exit 1; }
command -v rsync >/dev/null        || { echo "ERROR: rsync no disponible (usa WSL: npm run devops:teatro:deploy)"; exit 1; }
[[ -n "$PY" ]]                     || { echo "ERROR: python3 no disponible"; exit 1; }

TMP_WORK="$(mktemp -d)"
trap 'rm -rf "$TMP_WORK"' EXIT
PUB_KEY_PATH="${PUB_KEY_PATH:-$KEY_PATH.pub}"

# La clave en /mnt/c aparece 0777 en WSL y ssh la rechaza: copia efímera 600.
key_mode="$(stat -c '%a' "$KEY_PATH" 2>/dev/null || echo 600)"
if [[ "$key_mode" != "600" && "$key_mode" != "400" ]]; then
  cat "$KEY_PATH" > "$TMP_WORK/key"; chmod 600 "$TMP_WORK/key"; KEY_PATH="$TMP_WORK/key"
fi
SSH_OPTS="-i $KEY_PATH -o StrictHostKeyChecking=accept-new -o BatchMode=yes"
REMOTE="$REMOTE_USER@$REMOTE_HOST"
rssh() { ssh $SSH_OPTS "$REMOTE" "$@"; }   # shellcheck disable=SC2029

# ── 1. pre-vuelo local: invariantes + manifiesto ──────────────────────────────
echo "[deploy-teatro] pre-vuelo: invariantes de publicación ($OBRA)…"
PYTHONDONTWRITEBYTECODE=1 PYTHONUTF8=1 "$PY" "$SIDECAR" check --dir "$LOCAL_OBRA"
echo "[deploy-teatro] manifiesto sha256 de la obra…"
PYTHONDONTWRITEBYTECODE=1 PYTHONUTF8=1 "$PY" "$SIDECAR" manifest --dir "$LOCAL_OBRA"
N_LOCAL="$(wc -l < "$LOCAL_OBRA/MANIFEST.sha256")"

# Portada del Teatro: fuente versionada en el repo, copiada al árbol a subir.
cp "$REPO_ROOT/pub/site-templates/teatro/index.html" "$LOCAL_TEATRO_DIR/index.html"

echo "[deploy-teatro] preflight → $REMOTE:$REMOTE_OBRA"
rssh "
  set -e
  for d in '$REMOTE_TEATRO_DIR' '$REMOTE_OBRA'; do
    [ -d \"\$d\" ] || mkdir -p \"\$d\" 2>/dev/null || sudo -n mkdir -p \"\$d\"
  done
  sudo -n chown \$(id -un):\$(id -gn) '$REMOTE_TEATRO_DIR' '$REMOTE_OBRA' 2>/dev/null || true
  df -h /srv/oasis | tail -n1
"

# ── 2. rsync: solo la portada y ESTA obra ────────────────────────────────────
RSYNC_FLAGS=(-a --partial --chmod=D755,F644 --info=progress2
  --exclude "/$OBRA.zip" --exclude "/$OBRA-cerebro.zip" --exclude '/*.zip.sha256*'
  --exclude '/MANIFEST.sha256.sig' --exclude '/allowed_signers' --exclude '__pycache__/' --exclude '*.pyc')
[[ "${TEATRO_DELETE:-0}" = "1" ]] && RSYNC_FLAGS+=(--delete)
if [[ "${TEATRO_DRY_RUN:-0}" = "1" ]]; then
  echo "[deploy-teatro] DRY RUN (nada se sube ni se borra):"
  rsync "${RSYNC_FLAGS[@]}" -n --itemize-changes --no-inc-recursive --info=progress0,stats2 \
    -e "ssh $SSH_OPTS" "$LOCAL_OBRA/" "$REMOTE:$REMOTE_OBRA/" > "$TMP_WORK/dry.txt"
  echo "  nuevos (+++++++++):      $(grep -c '^<f+++++++++' "$TMP_WORK/dry.txt" || true)"
  echo "  contenido cambiado:      $(grep -cE '^<f[.c]s' "$TMP_WORK/dry.txt" || true)"
  echo "  solo fecha (sin subida): $(grep -cE '^<f\.\.t' "$TMP_WORK/dry.txt" || true)"
  echo "  a BORRAR en el VPS:      $(grep -c '^\*deleting' "$TMP_WORK/dry.txt" || true)"
  echo "  --- primeros borrados:"; grep '^\*deleting' "$TMP_WORK/dry.txt" | head -25 | sed 's/^/    /'
  echo "  --- borrados por carpeta:"; grep '^\*deleting' "$TMP_WORK/dry.txt" | awk '{print $2}' | cut -d/ -f1-2 | sort | uniq -c | sort -rn | head -12 | sed 's/^/    /'
  grep -E 'Total transferred file size|Total file size|Number of regular files transferred' "$TMP_WORK/dry.txt" | sed 's/^/  /'
  echo "[deploy-teatro] fin del DRY RUN."; exit 0
fi
echo "[deploy-teatro] rsync de la obra (reanudable; relanzar si se corta)…"
rsync "${RSYNC_FLAGS[@]}" -e "ssh $SSH_OPTS" "$LOCAL_OBRA/" "$REMOTE:$REMOTE_OBRA/"
rsync -a --chmod=F644 -e "ssh $SSH_OPTS" "$LOCAL_TEATRO_DIR/index.html" "$REMOTE:$REMOTE_TEATRO_DIR/index.html"

# ── 3. integridad del árbol subido (ANTES de estampar nada) ───────────────────
echo "[deploy-teatro] verificando el árbol remoto contra MANIFEST.sha256 ($N_LOCAL ficheros)…"
rssh "cd '$REMOTE_OBRA' && sha256sum -c --quiet MANIFEST.sha256"

# ── 4. zips remotos: el COMPLETO (descarga principal) y el ligero (inspección) ─
if [[ "${TEATRO_SKIP_ZIP:-0}" != "1" ]]; then
  echo "[deploy-teatro] generando zips remotos…"
  rssh "
    set -e
    cd '$REMOTE_TEATRO_DIR'
    rm -f '$OBRA/$OBRA.zip.tmp' '$OBRA/$OBRA-cerebro.zip.tmp'
    if command -v zip >/dev/null 2>&1; then
      # completo: todo el árbol, sin comprimir (mp4/jpg no comprimen) y sin los propios artefactos
      zip -0 -rq '$OBRA/$OBRA.zip.tmp' '$OBRA' -x '$OBRA/*.zip' '$OBRA/*.zip.tmp' '$OBRA/*.zip.sha256*' '$OBRA/MANIFEST.sha256.sig' '$OBRA/allowed_signers'
      ( cd '$OBRA' && zip -rq '$OBRA-cerebro.zip.tmp' corpus indexes tools AGENTS.md MANIFEST.sha256 data/external_tweets.v2.json data/external_worklist.json data/links_store.json 2>/dev/null || true )
    else
      python3 - <<'PY'
import os, zipfile
obra = '$OBRA'
skip = ('.zip', '.zip.tmp', '.sha256.sig', 'allowed_signers')
brain = ('corpus/', 'indexes/', 'tools/', 'AGENTS.md', 'MANIFEST.sha256', 'data/external_', 'data/links_')
with zipfile.ZipFile(f'{obra}/{obra}.zip.tmp', 'w', zipfile.ZIP_STORED, allowZip64=True) as full, \
     zipfile.ZipFile(f'{obra}/{obra}-cerebro.zip.tmp', 'w', zipfile.ZIP_DEFLATED, allowZip64=True) as light:
    for root, _dirs, files in os.walk(obra):
        for name in sorted(files):
            path = os.path.join(root, name)
            rel = os.path.relpath(path, obra).replace(os.sep, '/')
            if '/' not in rel and (rel.endswith(skip) or '.zip.sha256' in rel):
                continue
            full.write(path, f'{obra}/{rel}')
            if rel.startswith(brain):
                light.write(path, rel)
PY
    fi
    mv '$OBRA/$OBRA.zip.tmp' '$OBRA/$OBRA.zip'
    mv '$OBRA/$OBRA-cerebro.zip.tmp' '$OBRA/$OBRA-cerebro.zip'
    chmod 644 '$OBRA/$OBRA.zip' '$OBRA/$OBRA-cerebro.zip'
    ls -lh '$OBRA/$OBRA.zip' '$OBRA/$OBRA-cerebro.zip'
  "
fi

# ── 5. checksums + letrero ───────────────────────────────────────────────────
echo "[deploy-teatro] checksums + letrero…"
ZIP_SHA="$(rssh "
  set -e
  cd '$REMOTE_OBRA'
  sha256sum '$OBRA.zip' > '$OBRA.zip.sha256'
  sha256sum '$OBRA-cerebro.zip' > '$OBRA-cerebro.zip.sha256'
  chmod 644 *.sha256
  cut -d' ' -f1 '$OBRA.zip.sha256'
")"
echo "[deploy-teatro] SHA-256 de $OBRA.zip: $ZIP_SHA"
rssh "sed -i 's/__ZIP_SHA256__/$ZIP_SHA/g' '$REMOTE_TEATRO_DIR/index.html' '$REMOTE_OBRA/index.html'"

# ── 6. firma ed25519 en local (la privada no viaja) ──────────────────────────
if [[ -f "$PUB_KEY_PATH" ]]; then
  echo "[deploy-teatro] firmando checksums y manifiesto…"
  for f in "$OBRA.zip.sha256" "$OBRA-cerebro.zip.sha256" "MANIFEST.sha256"; do
    rssh "cat '$REMOTE_OBRA/$f'" > "$TMP_WORK/$f"
    ssh-keygen -Y sign -f "$KEY_PATH" -n file -q "$TMP_WORK/$f"
  done
  awk '{print "teatro@escrivivir.co " $1 " " $2}' "$PUB_KEY_PATH" > "$TMP_WORK/allowed_signers"
  scp $SSH_OPTS -q "$TMP_WORK"/*.sig "$TMP_WORK/allowed_signers" "$REMOTE:$REMOTE_OBRA/"
  rssh "chmod 644 '$REMOTE_OBRA'/*.sig '$REMOTE_OBRA/allowed_signers'"
else
  echo "[deploy-teatro] AVISO: sin $PUB_KEY_PATH; se publican checksums sin firma."
fi

# ── 7. verificación post-deploy ──────────────────────────────────────────────
if [[ "${TEATRO_SKIP_VERIFY:-0}" != "1" ]]; then
  echo "[deploy-teatro] verificación pública (https://$PUB_HOST/teatro/$OBRA/)…"
  H="https://$PUB_HOST"; B="$H/teatro/$OBRA"; fail=0
  expect() { # expect <código> <url> [curl args…]
    local want="$1" url="$2"; shift 2
    local got; got="$(curl -s -o /dev/null -w '%{http_code}' "$@" "$url" || echo 000)"
    if [[ "$got" == "$want" ]]; then echo "  ok   $got $url"; else echo "  FAIL $got (esperado $want) $url"; fail=1; fi
  }
  expect 200 "$H/teatro/"
  expect 200 "$B/"
  expect 200 "$B/enlaces/"
  expect 200 "$B/$OBRA.zip.sha256"
  expect 200 "$B/$OBRA-cerebro.zip"
  expect 200 "$B/MANIFEST.sha256"
  MP4="$(grep -m1 '\.mp4$' "$LOCAL_OBRA/MANIFEST.sha256" | sed 's/^[0-9a-f]*  \.\///' || true)"
  [[ -n "$MP4" ]] && expect 206 "$B/$MP4" -r 0-1023
  expect 404 "$B/data/ip-audit.js"
  expect 404 "$B/data/direct-messages.js"
  served="$(curl -s "$B/" | grep -c "$ZIP_SHA" || true)"
  [[ "$served" -ge 1 ]] && echo "  ok   hash estampado en la portada" || { echo "  FAIL hash no estampado"; fail=1; }
  scripts="$(curl -s "$B/" | grep -ci '<script' || true)"
  [[ "$scripts" == "0" ]] && echo "  ok   portada sin <script>" || { echo "  FAIL <script> en la portada"; fail=1; }
  zip_len="$(curl -sI "$B/$OBRA.zip" | tr -d '\r' | awk 'tolower($1)=="content-length:"{print $2}')"
  echo "  info $OBRA.zip content-length=${zip_len:-?}"
  soft="$(curl -s -o /dev/null -w '%{http_code}' "$B/no-existe-$$/")"
  [[ "$soft" == "404" ]] && echo "  ok   404 real bajo /teatro/" || echo "  AVISO soft-404 ($soft): falta el bloque @teatro en el Caddyfile vivo (TEATRO-PROTOCOL §6)"
  modes="$(rssh "find '$REMOTE_OBRA' -perm -o+w | head -3 | wc -l")"
  [[ "$modes" == "0" ]] && echo "  ok   nada world-writable en la obra" || { echo "  FAIL ficheros world-writable en $REMOTE_OBRA"; fail=1; }
  for v in "$H/" "$H/public/status"; do expect 200 "$v"; done
  [[ "$fail" == "0" ]] || { echo "[deploy-teatro] ⛔ verificación con fallos"; exit 1; }
fi

echo "[deploy-teatro] Done · $OBRA · $N_LOCAL ficheros · zip $ZIP_SHA"
