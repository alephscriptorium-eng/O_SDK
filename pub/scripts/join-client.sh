#!/usr/bin/env bash
set -euo pipefail

USES="${1:-1}"
CLIENT_URL="${2:-}"
# shellcheck disable=SC1091
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"
load_pub_env

TARGET_CLIENT_URL="${CLIENT_URL:-${OASIS_CLIENT_URL:-http://localhost:3000}}"
INVITE_STDERR="$(mktemp)"
if ! INVITE_CODE="$(bash "$SCRIPT_DIR/invite.sh" "$USES" 2>"$INVITE_STDERR" | tr -d '\r')"; then
  INVITE_ERROR="$(tr -d '\r' < "$INVITE_STDERR")"
  rm -f "$INVITE_STDERR"
  echo "No se pudo generar un invite usable para el cliente local."
  if printf '%s' "$INVITE_ERROR" | grep -qi 'no public ip address'; then
    echo '`ssb-invite` necesita un host/IP públicos; el pub local está funcionando, pero los invites reales llegarán cuando usemos dominio o VPS.'
  else
    echo "Detalle: $INVITE_ERROR"
  fi
  exit 1
fi
rm -f "$INVITE_STDERR"

HTTP_CODE="$(curl -sS -o /tmp/oasis_pub_join_client.out -w '%{http_code}' -L -X POST "${TARGET_CLIENT_URL%/}/settings/invite/accept" --data-urlencode "invite=${INVITE_CODE}")"

if [ "$HTTP_CODE" -lt 200 ] || [ "$HTTP_CODE" -ge 400 ]; then
  echo "No se pudo unir el cliente Oasis en $TARGET_CLIENT_URL (HTTP $HTTP_CODE)."
  echo "Invite generado: $INVITE_CODE"
  exit 1
fi

echo "Cliente Oasis unido al pub correctamente via $TARGET_CLIENT_URL"
echo "Invite utilizado: $INVITE_CODE"
