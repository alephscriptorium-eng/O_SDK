#!/usr/bin/env bash
# retro-codes.sh — ejecuta pub/tools/tribe-codes.js DENTRO del contenedor del bot secretaría (WP-O137).
# Los códigos de acceso de las tribus sembradas: listarlos, imprimirlos en una hoja con QR, o generar uno de un uso.
#
#   bash pub/scripts/retro-codes.sh [--template campamento] [--ledger <ruta en el bot>] [--pub-id @…] list [--show] [--json]
#   bash pub/scripts/retro-codes.sh [...] sheet --out <directorio del host> [--brand <marca.json del host>]
#   bash pub/scripts/retro-codes.sh [...] one-use <id de plantilla> [--yes]      (--yes publica: irreversible, PERMISO)
#
# `sheet` genera dentro del bot (/tmp) y lo saca con `docker cp` al directorio del host: imprímelo y bórralo.
# `list` enmascara los códigos salvo con --show. Nada de esto se escribe en ledger ni en logs.
# Contenedor: OASIS_RETRO_BOT_CONTAINER (por defecto oasis-pub-retro-bot). Solo lectura salvo `one-use --yes`.
set -euo pipefail
PUB_ID="${OASIS_PUB_ID:-}"; TEMPLATE="campamento"; LEDGER=""; OUT=""; BRAND=""; REST=()
while [ $# -gt 0 ]; do
  case "$1" in
    --pub-id) PUB_ID="$2"; shift 2 ;;
    --template) TEMPLATE="$2"; shift 2 ;;
    --ledger) LEDGER="$2"; shift 2 ;;
    --out) OUT="$2"; shift 2 ;;
    --brand) BRAND="$2"; shift 2 ;;
    -h|--help) sed -n 2,11p "$0"; exit 0 ;;
    *) REST+=("$1"); shift ;;
  esac
done
[ "${#REST[@]}" -gt 0 ] || { sed -n 2,11p "$0"; exit 2; }
CTR="${OASIS_RETRO_BOT_CONTAINER:-oasis-pub-retro-bot}"
export MSYS_NO_PATHCONV=1
TAG="$(date -u +%Y%m%dT%H%M%SZ)"
ARGS="--template $TEMPLATE"; [ -n "$LEDGER" ] && ARGS="$ARGS --ledger $LEDGER"
run() { docker exec -i -u oasis -e HOME=/home/oasis -e OASIS_PUB_ID="$PUB_ID" "$CTR" sh -lc "cd /app/src/server && node /app/pub/tools/tribe-codes.js $*"; }
case "${REST[0]}" in
  sheet)
    [ -n "$OUT" ] || { echo "sheet: falta --out <directorio del host>" >&2; exit 2; }
    IN="/tmp/codigos-$TAG"
    if [ -n "$BRAND" ]; then
      docker exec -i -u oasis "$CTR" sh -lc "mkdir -p $IN && cat > $IN/marca.json" < "$BRAND"
      ARGS="$ARGS --brand $IN/marca.json"
    fi
    run "${REST[*]} $ARGS --out $IN"
    mkdir -p "$OUT"
    # En Git Bash, docker (binario de Windows) necesita la ruta del host en forma Windows (MSYS_NO_PATHCONV no traduce /c/…).
    HOST_OUT="$OUT"; command -v cygpath >/dev/null 2>&1 && HOST_OUT="$(cygpath -w "$OUT")"
    docker cp "$CTR:$IN/." "$HOST_OUT/" >/dev/null
    docker exec -u oasis "$CTR" rm -rf "$IN"
    rm -f "$OUT/marca.json"
    echo "hoja en $OUT/hoja-codigos.html (en el bot no queda copia). Imprímela y borra el directorio." ;;
  list|one-use) run "${REST[*]} $ARGS" ;;
  *) echo "orden desconocida: ${REST[0]} (list|sheet|one-use)" >&2; exit 2 ;;
esac
