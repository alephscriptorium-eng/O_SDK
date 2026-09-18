#!/usr/bin/env bash
# =============================================================================
# import-identity.sh — importa una identidad SSB existente en el cliente de este repo
# (docs/CLIENT-PROTOCOL.md §2). Copia SOLO lo que no es derivable y deja el volumen listo
# para `client/scripts/sync-only.sh start` (NUNCA para `docker compose up` directo).
#
# Uso (desde la raíz del repo):
#   bash client/scripts/import-identity.sh --from <dir-.ssb-viejo> [--with-blobs] [--force] [--dry-run]
#
# Lista blanca (se copia):  secret · flume/log.offset · gossip.json · keys/ · [blobs/]
# Lista negra (se queda):   config · conn.json · flume/* (índices) · ebt/ · blobs_push/ · socket
#                           · manifest.json · node_modules · *.nul-damaged-bak · oasis-first-contact viejo
# Además crea `oasis-first-contact` con el feed importado y `welcome=done`: en Oasis 1.1.2 es lo que
# impide que la GUI publique el PM de bienvenida a los 3 s (= seq 1 nuevo = FORK del feed).
#
# Con --force aparta también volumes-dev/client-state/banking/wallet-addresses.json (el mapa de
# direcciones ECOin va por feed). La cartera ECOin (volumen docker externo) NUNCA se toca.
#
# Exit: 0 ok · 2 uso · 3 precondición · 4 origen inválido · 5 verificación post-copia · 6 sin docker
# =============================================================================
set -euo pipefail
export MSYS_NO_PATHCONV=1

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$REPO_ROOT"

DST="$REPO_ROOT/volumes-dev/ssb-data"
TS="$(date +%Y%m%d-%H%M%S)"
INSPECT="$SCRIPT_DIR/lib/inspect-log-offset.js"
BACKUP_ROOT="$REPO_ROOT/devops/backups/client"
FEED_RE='^@[A-Za-z0-9+/]{43}=\.ed25519$'
VOLUME_NAME="o-sdk_oasis-ssb-data-dev"

FROM=""; WITH_BLOBS=0; FORCE=0; DRY_RUN=0
die()  { echo "❌ $2" >&2; exit "$1"; }
warn() { echo "⚠️  $*" >&2; }
info() { echo "→ $*"; }
sha()  { sha256sum "$1" | cut -c1-64; }
wpath() { cygpath -m "$1" 2>/dev/null || echo "$1"; }   # rutas para binarios Windows (node) bajo MSYS_NO_PATHCONV

while [ $# -gt 0 ]; do
  case "$1" in
    --from) shift; FROM="${1:-}" ;;
    --from=*) FROM="${1#--from=}" ;;
    --with-blobs) WITH_BLOBS=1 ;;
    --force) FORCE=1 ;;
    --dry-run) DRY_RUN=1 ;;
    -h|--help) sed -n '2,23p' "$0"; exit 0 ;;
    *) die 2 "argumento desconocido: $1 (ver --help)" ;;
  esac
  shift
done
[ -n "$FROM" ] || die 2 "falta --from <dir-.ssb-viejo>"
SRC="$(cygpath -u "$FROM" 2>/dev/null || echo "$FROM")"
SRC="${SRC%/}"
[ -d "$SRC" ] || die 4 "origen no existe: $SRC"

# ---------------------------------------------------------------- 0. precondiciones
command -v docker >/dev/null 2>&1 || die 6 "docker no disponible"
command -v node   >/dev/null 2>&1 || die 6 "node no disponible en el host (lo usa lib/inspect-log-offset.js)"

if [ "$(docker inspect -f '{{.State.Running}}' oasis-client 2>/dev/null || echo false)" = "true" ]; then
  die 3 "oasis-client está corriendo: docker compose stop oasis-client"
fi
if [ -n "$(docker ps -q -f name='^oasis-sync-only$' 2>/dev/null)" ]; then
  die 3 "oasis-sync-only está corriendo: bash client/scripts/sync-only.sh stop"
fi
# el volumen con nombre del compose debe apuntar a ESTE volumes-dev (o no existir aún)
dev="$(docker volume inspect "$VOLUME_NAME" --format '{{index .Options "device"}}' 2>/dev/null || true)"
if [ -n "$dev" ]; then
  want="$(cygpath -w "$DST" 2>/dev/null || echo "$DST")"
  if [ "${dev,,}" != "${want,,}" ]; then
    die 3 "el volumen $VOLUME_NAME apunta a '$dev' y no a '$want': docker volume rm $VOLUME_NAME (con el cliente parado)"
  fi
fi

# ---------------------------------------------------------------- 1. verificar origen
[ -f "$SRC/secret" ]           || die 4 "falta $SRC/secret"
[ -f "$SRC/flume/log.offset" ] || die 4 "falta $SRC/flume/log.offset (para importar solo el secret usa --from con un log vacío... no soportado: ver CLIENT-PROTOCOL §2)"
for f in secret gossip.json; do
  [ -f "$SRC/$f" ] || continue
  [ "$(tr -dc '\000' < "$SRC/$f" | wc -c)" = "0" ] || die 4 "$f contiene bytes NUL (fichero dañado)"
done
FEED="$(grep -o '"id": *"[^"]*"' "$SRC/secret" | head -1 | cut -d'"' -f4)"
PUBK="$(grep -o '"public": *"[^"]*"' "$SRC/secret" | head -1 | cut -d'"' -f4)"
[[ "$FEED" =~ $FEED_RE ]] || die 4 "secret sin un id válido"
[ "@$PUBK" = "$FEED" ]      || die 4 "secret inconsistente: id=$FEED public=$PUBK"

LOG_JSON="$(FULL_SCAN=1 node "$(wpath "$INSPECT")" "$(wpath "$SRC/flume/log.offset")" "$FEED")" || die 4 "log.offset con frames rotos: $LOG_JSON"
MYSEQ="$(node -pe 'JSON.parse(process.argv[1]).mySeq || 0' "$LOG_JSON")"
RECORDS="$(node -pe 'JSON.parse(process.argv[1]).records' "$LOG_JSON")"
[ "$MYSEQ" -gt 0 ] || die 4 "el log no contiene mensajes del feed $FEED"

CAP_NEW="$(grep -o '"shs": *"[^"]*"' src/configs/server-config.json | head -1 | cut -d'"' -f4)"
CAP_OLD="$(grep -o '"shs": *"[^"]*"' "$SRC/config" 2>/dev/null | head -1 | cut -d'"' -f4 || true)"
if [ -n "$CAP_OLD" ] && [ "$CAP_OLD" != "$CAP_NEW" ]; then
  warn "caps.shs del origen ($CAP_OLD) ≠ del repo ($CAP_NEW): ciclo de red distinto; el pub no hará handshake"
fi

echo "=== import-identity · origen verificado ==="
echo "  feed      : $FEED"
echo "  log       : $RECORDS registros · seq propio $MYSEQ · $(node -pe 'JSON.parse(process.argv[1]).fileSize' "$LOG_JSON") bytes"
echo "  gossip    : $([ -f "$SRC/gossip.json" ] && echo "sí ($(stat -c%s "$SRC/gossip.json") B)" || echo "no")"
echo "  keys/     : $([ -d "$SRC/keys" ] && echo "sí" || echo "no")"
echo "  blobs/    : $([ -d "$SRC/blobs" ] && echo "sí ($(du -sh "$SRC/blobs" | cut -f1)) · $([ $WITH_BLOBS = 1 ] && echo "SE COPIAN" || echo "no se copian (--with-blobs)")" || echo "no")"
echo "  destino   : $DST"
if [ $DRY_RUN = 1 ]; then echo "(dry-run: nada copiado)"; exit 0; fi

# ---------------------------------------------------------------- 2. destino
if [ -d "$DST" ] && [ -n "$(ls -A "$DST" 2>/dev/null)" ]; then
  [ $FORCE = 1 ] || die 3 "$DST no está vacío. Con --force se aparta a ssb-data.pre-import-$TS (no se borra nada)"
  mv "$DST" "$DST.pre-import-$TS"
  info "destino anterior apartado en volumes-dev/ssb-data.pre-import-$TS"
fi
mkdir -p "$DST/flume" "$DST/keys" volumes-dev/ai-models volumes-dev/logs volumes-dev/client-state/banking
# El mapa de direcciones ECOin va POR FEED: con otra identidad, el de la anterior no vale y se aparta
# (no se borra). La cartera (volumen docker o-sdk-client-ecoin-data) NO se toca: wallet.dat no depende del feed.
WMAP="volumes-dev/client-state/banking/wallet-addresses.json"
if [ $FORCE = 1 ] && [ -f "$WMAP" ]; then
  mv "$WMAP" "$WMAP.pre-import-$TS"
  info "mapa de direcciones ECOin apartado en $WMAP.pre-import-$TS (la cartera no se toca)"
fi

# ---------------------------------------------------------------- 3. backup previo verificado (identidad + log)
BK="$BACKUP_ROOT/$TS"
mkdir -p "$BK"
cp "$SRC/secret" "$BK/secret"
cp "$SRC/flume/log.offset" "$BK/log.offset"
[ -f "$SRC/gossip.json" ] && cp "$SRC/gossip.json" "$BK/gossip.json"
[ -d "$SRC/keys" ] && cp -r "$SRC/keys" "$BK/keys"
( cd "$BK" && find . -type f ! -name SHA256SUMS.txt -print0 | xargs -0 sha256sum > SHA256SUMS.txt )
( cd "$BK" && sha256sum -c --quiet SHA256SUMS.txt ) || die 5 "el backup en $BK no verifica"
info "backup verificado en devops/backups/client/$TS (gitignored; cópialo fuera de la máquina)"

# ---------------------------------------------------------------- 4. copia selectiva
cp "$SRC/secret" "$DST/secret"
cp "$SRC/flume/log.offset" "$DST/flume/log.offset"
[ -f "$SRC/gossip.json" ] && cp "$SRC/gossip.json" "$DST/gossip.json"
[ -d "$SRC/keys" ] && cp -r "$SRC/keys/." "$DST/keys/"
if [ $WITH_BLOBS = 1 ] && [ -d "$SRC/blobs" ]; then
  info "copiando blobs…"
  if command -v robocopy >/dev/null 2>&1; then
    set +e
    robocopy "$(cygpath -w "$SRC/blobs")" "$(cygpath -w "$DST/blobs")" /E /R:1 /W:1 /NFL /NDL /NJH /NJS /NP >/dev/null
    rc=$?; set -e
    [ $rc -lt 8 ] || die 5 "robocopy devolvió $rc"
  else
    cp -r "$SRC/blobs" "$DST/blobs"
  fi
fi
printf '%s\n%s\n%s\n' "$FEED" "$(date -u +%Y-%m-%dT%H:%M:%S.000Z)" "welcome=done" > "$DST/oasis-first-contact"

# ---------------------------------------------------------------- 5. verificación post-copia
[ "$(sha "$SRC/secret")" = "$(sha "$DST/secret")" ] || die 5 "secret difiere tras la copia"
[ "$(sha "$SRC/flume/log.offset")" = "$(sha "$DST/flume/log.offset")" ] || die 5 "log.offset difiere tras la copia"
if [ -f "$SRC/gossip.json" ]; then
  [ "$(sha "$SRC/gossip.json")" = "$(sha "$DST/gossip.json")" ] || die 5 "gossip.json difiere tras la copia"
fi
node "$(wpath "$INSPECT")" "$(wpath "$DST/flume/log.offset")" "$FEED" >/dev/null || die 5 "log.offset copiado no pasa la inspección"
if [ $WITH_BLOBS = 1 ] && [ -d "$SRC/blobs" ]; then
  n_src="$(find "$SRC/blobs" -type f | wc -l)"; n_dst="$(find "$DST/blobs" -type f | wc -l)"
  [ "$n_src" = "$n_dst" ] || die 5 "nº de blobs: origen $n_src ≠ destino $n_dst"
  # content-addressed: sha256(fichero) == nombre. Blobs dañados (p. ej. rellenos de NUL por un disco
  # averiado) no se importan: son re-descargables de la red (blobs.want); importarlos solo los serviría rotos.
  bad=0; checked=0
  while read -r b; do
    checked=$((checked+1)); [ "$(sha "$b")" = "$(basename "$b")" ] || bad=$((bad+1))
  done < <(find "$DST/blobs" -type f | shuf -n 20 2>/dev/null)
  if [ "$bad" -gt 0 ]; then
    warn "blobs: $bad de $checked muestreados NO cuadran con su hash (origen dañado). No se importan: se retira volumes-dev/ssb-data/blobs; la red los re-sirve."
    rm -rf "$DST/blobs"; WITH_BLOBS=0
  fi
fi
[ "$(head -1 "$DST/oasis-first-contact")" = "$FEED" ] || die 5 "flag oasis-first-contact mal escrito"

# ---------------------------------------------------------------- 6. manifiesto
MAN="$DST/.import-$TS.txt"
{
  echo "import-identity $TS"
  echo "origen=$SRC"
  echo "feed=$FEED"
  echo "o-sdk=$(git rev-parse --short HEAD 2>/dev/null || echo '?') oasis=$(node -pe 'require("./src/server/package.json").version')"
  echo "log=$LOG_JSON"
  echo "backup=$BK"
  ( cd "$DST" && sha256sum secret flume/log.offset oasis-first-contact $( [ -f gossip.json ] && echo gossip.json ) )
  if [ $WITH_BLOBS = 1 ] && [ -d "$DST/blobs" ]; then
    echo "blobs_files=$(find "$DST/blobs" -type f | wc -l) blobs_bytes=$(du -sb "$DST/blobs" | cut -f1)"
  fi
} > "$MAN"

echo
echo "✅ identidad importada: $FEED · seq propio en el log: $MYSEQ"
echo "   manifiesto: volumes-dev/ssb-data/.import-$TS.txt"
echo "   SIGUIENTE (obligatorio): bash client/scripts/sync-only.sh start"
echo "   NUNCA 'docker compose up' / 'npm run up' hasta que sync-only status diga SYNC-OK."
