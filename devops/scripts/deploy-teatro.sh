#!/usr/bin/env bash
# deploy-teatro.sh — sube el contenido del Teatro (obras estáticas pesadas)
# al volumen de datos del VPS: /srv/oasis/teatro → https://pub.escrivivir.co/teatro/
#
# El árbol local lo genera build_site.py (segundo cerebro TWITTER_FILM); la
# portada del Teatro se copia desde pub/site-templates/teatro/. La subida es
# reanudable (rsync --partial): si se corta, relanzar.
#
# Requiere rsync. En Windows no viene con Git Bash: ejecutar dentro de WSL,
#   wsl -d Ubuntu -- bash /mnt/c/S_LAB/o-sdk/devops/scripts/deploy-teatro.sh
#
# Variables (entorno > host.env > default):
#   LOCAL_TEATRO_DIR   árbol local a subir (default: /mnt/c/S_META/LORE/deploy/teatro)
#   REMOTE_TEATRO_DIR  destino en el VPS (default: /srv/oasis/teatro)
#   TEATRO_DELETE=1    añade --delete al rsync (espejo exacto; cuidado)
#   TEATRO_SKIP_ZIP=1  no (re)generar el zip remoto
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Datos de instancia → devops/hosts/<DEVOPS_HOST>/host.env
# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib-host.sh"
REPO_ROOT="$(cd "$DEVOPS_DIR/.." && pwd)"

KEY_PATH="${KEY_PATH:-}"
REMOTE_USER="${REMOTE_USER:-}"
REMOTE_HOST="${REMOTE_HOST:-}"
LOCAL_TEATRO_DIR="${LOCAL_TEATRO_DIR:-/mnt/c/S_META/LORE/deploy/teatro}"
REMOTE_TEATRO_DIR="${REMOTE_TEATRO_DIR:-/srv/oasis/teatro}"

[[ -f "$KEY_PATH" ]]          || { echo "ERROR: SSH key not found: $KEY_PATH"; exit 1; }
[[ -d "$LOCAL_TEATRO_DIR" ]]  || { echo "ERROR: Local teatro dir not found: $LOCAL_TEATRO_DIR"; exit 1; }
command -v rsync >/dev/null   || { echo "ERROR: rsync no disponible (usar WSL)"; exit 1; }

TMP_WORK="$(mktemp -d)"
trap 'rm -rf "$TMP_WORK"' EXIT

PUB_KEY_PATH="${PUB_KEY_PATH:-$KEY_PATH.pub}"

# La clave en /mnt/c aparece 0777 en WSL y ssh la rechaza: copia efímera 600.
key_mode="$(stat -c '%a' "$KEY_PATH" 2>/dev/null || echo 600)"
if [[ "$key_mode" != "600" && "$key_mode" != "400" ]]; then
  cat "$KEY_PATH" > "$TMP_WORK/key"
  chmod 600 "$TMP_WORK/key"
  KEY_PATH="$TMP_WORK/key"
fi
SSH_OPTS="-i $KEY_PATH -o StrictHostKeyChecking=accept-new -o BatchMode=yes"

# Portada del Teatro: fuente versionada en el repo, copiada al árbol a subir.
cp "$REPO_ROOT/pub/site-templates/teatro/index.html" "$LOCAL_TEATRO_DIR/index.html"

echo "[deploy-teatro] preflight → $REMOTE_USER@$REMOTE_HOST:$REMOTE_TEATRO_DIR"
# shellcheck disable=SC2029
ssh $SSH_OPTS "$REMOTE_USER@$REMOTE_HOST" "
  set -e
  if [ ! -d '$REMOTE_TEATRO_DIR' ]; then
    mkdir -p '$REMOTE_TEATRO_DIR' 2>/dev/null || sudo -n mkdir -p '$REMOTE_TEATRO_DIR'
    sudo -n chown \$(id -un):\$(id -gn) '$REMOTE_TEATRO_DIR' 2>/dev/null || true
  fi
  df -h /srv/oasis | tail -n1
"

echo "[deploy-teatro] rsync (reanudable; relanzar si se corta)…"
DELETE_FLAG=()
[[ "${TEATRO_DELETE:-0}" = "1" ]] && DELETE_FLAG=(--delete)
rsync -a --partial --info=progress2 "${DELETE_FLAG[@]}" \
  --exclude 'aleph-cero.zip' \
  -e "ssh $SSH_OPTS" \
  "$LOCAL_TEATRO_DIR/" \
  "$REMOTE_USER@$REMOTE_HOST:$REMOTE_TEATRO_DIR/"

if [[ "${TEATRO_SKIP_ZIP:-0}" != "1" ]]; then
  echo "[deploy-teatro] generando zip remoto (segundo cerebro verbatim)…"
  # shellcheck disable=SC2029
  ssh $SSH_OPTS "$REMOTE_USER@$REMOTE_HOST" "
    set -e
    cd '$REMOTE_TEATRO_DIR/aleph-cero'
    rm -f aleph-cero.zip.tmp
    if command -v zip >/dev/null 2>&1; then
      zip -rq aleph-cero.zip.tmp corpus indexes tools AGENTS.md second-brain.md data
    else
      python3 -m zipfile -c aleph-cero.zip.tmp corpus indexes tools AGENTS.md second-brain.md data
    fi
    mv aleph-cero.zip.tmp aleph-cero.zip
    ls -lh aleph-cero.zip
  "
fi

# ── integridad: checksum en el letrero + firma ssh de la clave del VPS ──
echo "[deploy-teatro] checksum + letrero…"
# shellcheck disable=SC2029
ZIP_SHA="$(ssh $SSH_OPTS "$REMOTE_USER@$REMOTE_HOST" "
  set -e
  cd '$REMOTE_TEATRO_DIR/aleph-cero'
  sha256sum aleph-cero.zip > aleph-cero.zip.sha256
  cut -d' ' -f1 aleph-cero.zip.sha256
")"
echo "[deploy-teatro] SHA-256: $ZIP_SHA"
# shellcheck disable=SC2029
ssh $SSH_OPTS "$REMOTE_USER@$REMOTE_HOST" "
  set -e
  sed -i 's/__ZIP_SHA256__/$ZIP_SHA/g' \
    '$REMOTE_TEATRO_DIR/index.html' '$REMOTE_TEATRO_DIR/aleph-cero/index.html'
"

if [[ -f "$PUB_KEY_PATH" ]]; then
  echo "[deploy-teatro] firmando el .sha256 en local (la privada no viaja)…"
  # shellcheck disable=SC2029
  ssh $SSH_OPTS "$REMOTE_USER@$REMOTE_HOST" \
    "cat '$REMOTE_TEATRO_DIR/aleph-cero/aleph-cero.zip.sha256'" \
    > "$TMP_WORK/aleph-cero.zip.sha256"
  ssh-keygen -Y sign -f "$KEY_PATH" -n file -q "$TMP_WORK/aleph-cero.zip.sha256"
  awk '{print "teatro@escrivivir.co " $1 " " $2}' "$PUB_KEY_PATH" \
    > "$TMP_WORK/allowed_signers"
  scp $SSH_OPTS -q \
    "$TMP_WORK/aleph-cero.zip.sha256.sig" "$TMP_WORK/allowed_signers" \
    "$REMOTE_USER@$REMOTE_HOST:$REMOTE_TEATRO_DIR/aleph-cero/"
else
  echo "[deploy-teatro] AVISO: sin $PUB_KEY_PATH; se publica checksum sin firma."
fi

echo "[deploy-teatro] Done."
