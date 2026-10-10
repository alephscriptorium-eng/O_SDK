#!/usr/bin/env bash
# retro-tombstone.sh — ejecuta seed-tombstone.js (deshacer de una siembra --hot) DENTRO del contenedor del bot
# retro (WP-O135, D-O33, docs/PUB/TEMPLATE-PROTOCOL.md §9). Gemelo de retro-seed.sh: corre como `oasis` con
# HOME=/home/oasis y habla con el sbot por su socket. Dry-run por defecto; cada `--yes <bloque>` retira SOLO ese
# bloque (orden: clearnet entrada maps wiki mailing events calendars rooms invites subtribes tribes).
#
#   bash pub/scripts/retro-tombstone.sh --pub-id @… [--ledger /home/oasis/.ssb/oasis/keys/plantilla-campamento.json] \
#        [--evidence <tag>] [--yes <bloque>]...
#
# --pub-id es OBLIGATORIO y debe ser el del pub REAL con el que está conectado el bot (desde la máquina
# operadora el pub de .env.local es el desechable: no sirve). Evidencia: /app/logs/tombstone-<tag>.jsonl dentro
# del bot = <OASIS_RETRO_BOT_LOGS_DIR>/tombstone-<tag>.jsonl fuera; copiar al dosier de la instancia al cerrar.
set -euo pipefail
PUB_ID="${OASIS_PUB_ID:-}"; LEDGER="/home/oasis/.ssb/oasis/keys/plantilla-campamento.json"; TAG="$(date -u +%Y%m%dT%H%M%SZ)"; YES=()
while [ $# -gt 0 ]; do
  case "$1" in
    --pub-id) PUB_ID="$2"; shift 2 ;;
    --ledger) LEDGER="$2"; shift 2 ;;
    --evidence) TAG="$2"; shift 2 ;;
    --yes) YES+=(--yes "$2"); shift 2 ;;
    --skip) YES+=(--skip "$2"); shift 2 ;;   # <bloque>:<id> no retirable: queda en el ledger con motivo
    -h|--help) sed -n 2,12p "$0"; exit 0 ;;
    *) echo "argumento desconocido: $1" >&2; exit 2 ;;
  esac
done
[ -n "$PUB_ID" ] || { echo "falta --pub-id (feed id del pub real al que está conectado el bot)" >&2; exit 2; }
CTR="${OASIS_RETRO_BOT_CONTAINER:-oasis-pub-retro-bot}"
export MSYS_NO_PATHCONV=1
exec docker exec -i -u oasis -e HOME=/home/oasis -e OASIS_PUB_ID="$PUB_ID" "$CTR" sh -lc \
  "cd /app/src/server && node /app/pub/tools/seed-tombstone.js --ledger '$LEDGER' --evidence /app/logs/tombstone-${TAG}.jsonl ${YES[*]:-}"
