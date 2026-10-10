#!/usr/bin/env bash
# retro-seed.sh — ejecuta template-seed.js --hot DENTRO del contenedor del bot retro (WP-O131).
# El seeder necesita las dependencias de la imagen (/app/src/server/node_modules) y el socket del sbot:
# por eso corre con `docker exec` como `oasis` y HOME=/home/oasis (como oasis, no como root: ssb_config
# resolvería ~/.ssb = /root/.ssb). Dry-run por defecto; cada `--yes <bloque>` publica SOLO ese bloque.
#
#   bash pub/scripts/retro-seed.sh [--env pub/.env.local] [--pub-id @…] [--template campamento] [--evidence <tag>] [--yes <bloque>]...
#
# --pub-id: feed id del pub (gate «nunca con la identidad del pub»). Si falta, se mide con whoami.sh, que da el
#   pub de .env.local: con el bot REAL en la máquina operadora (D-O33) ese es el desechable y el gate pubConnected
#   exige el pub real al que está conectado: pásalo SIEMPRE (--pub-id '@…pub real…').
# Deshacer una siembra: pub/scripts/retro-tombstone.sh (TEMPLATE-PROTOCOL §9).
# Evidencia: /app/logs/seed-<tag>.json dentro del bot = <OASIS_RETRO_BOT_LOGS_DIR>/seed-<tag>.json fuera.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="pub/.env.local"; PUB_ID="${OASIS_PUB_ID:-}"; TEMPLATE="campamento"; TAG="$(date -u +%Y%m%dT%H%M%SZ)"; YES=()
while [ $# -gt 0 ]; do
  case "$1" in
    --env) ENV_FILE="$2"; shift 2 ;;
    --pub-id) PUB_ID="$2"; shift 2 ;;
    --template) TEMPLATE="$2"; shift 2 ;;
    --evidence) TAG="$2"; shift 2 ;;
    --yes) YES+=(--yes "$2"); shift 2 ;;
    -h|--help) sed -n 2,11p "$0"; exit 0 ;;
    *) echo "argumento desconocido: $1" >&2; exit 2 ;;
  esac
done
CTR="${OASIS_RETRO_BOT_CONTAINER:-oasis-pub-retro-bot}"
if [ -z "$PUB_ID" ]; then
  PUB_ID="$(bash "$HERE/env-run.sh" "$(basename "$ENV_FILE")" whoami.sh 2>/dev/null | grep -oE '@[A-Za-z0-9+/]+=\.ed25519' | head -1 || true)"
fi
[ -n "$PUB_ID" ] || { echo "no sé el feed id del pub: pásalo con --pub-id" >&2; exit 2; }
export MSYS_NO_PATHCONV=1
exec docker exec -i -u oasis -e HOME=/home/oasis -e OASIS_PUB_ID="$PUB_ID" "$CTR" sh -lc \
  "cd /app/src/server && node /app/pub/tools/template-seed.js --template /app/pub/templates/${TEMPLATE}.json \
   --assets /app/pub/assets/${TEMPLATE} --hot --evidence /app/logs/seed-${TAG}.json ${YES[*]:-}"
