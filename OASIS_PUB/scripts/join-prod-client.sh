#!/usr/bin/env bash
set -euo pipefail

INVITE_CODE="${1:-${INVITE:-}}"
CLIENT_URL="${2:-${OASIS_CLIENT_URL:-http://localhost:3000}}"

if [ -z "$INVITE_CODE" ]; then
  echo "Usage: INVITE='host:port:@key~secret' bash OASIS_PUB/scripts/join-prod-client.sh"
  echo "   or: bash OASIS_PUB/scripts/join-prod-client.sh 'host:port:@key~secret' [client_url]"
  exit 2
fi

HTTP_CODE="$(curl -sS -o /tmp/oasis_prod_join_client.out -w '%{http_code}' -L -X POST \
  "${CLIENT_URL%/}/settings/invite/accept" \
  -H "Referer: ${CLIENT_URL%/}/invites" \
  --data-urlencode "invite=${INVITE_CODE}")"

if [ "$HTTP_CODE" -lt 200 ] || [ "$HTTP_CODE" -ge 400 ]; then
  echo "No se pudo unir el cliente Oasis en $CLIENT_URL (HTTP $HTTP_CODE)."
  echo "Invite usado: $INVITE_CODE"
  if [ "$HTTP_CODE" = "500" ]; then
    echo "Nota: HTTP 500 puede indicar pub ya federado; comprueba gossip.json y logs SHS."
  fi
  exit 1
fi

echo "Cliente Oasis unido al pub de producción via $CLIENT_URL"
echo "Invite utilizado: $INVITE_CODE"
