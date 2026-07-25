#!/usr/bin/env bash
set -euo pipefail

USES="${1:-1}"
# shellcheck disable=SC1091
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"
load_pub_env

HOST="${OASIS_PUB_HOST:-localhost}"
HTTP_PORT="${OASIS_PUB_HTTP_PORT:-80}"
PANEL_PORT="${PUB_PANEL_PORT:-8787}"
WEB_URL="https://${HOST}"
if [ "${OASIS_PUB_WEB_HOST:-}" = "http://localhost" ] || [ "$HOST" = "localhost" ]; then
  WEB_URL="http://${HOST}:${HTTP_PORT}"
fi

PUB_ID="$(bash "$SCRIPT_DIR/whoami.sh" | tr -d '\r' | node -e "const fs=require('fs');const input=fs.readFileSync(0,'utf8').trim(); try { const parsed = JSON.parse(input); console.log(parsed.id || input); } catch { console.log(input); }")"
INVITE_STDERR="$(mktemp)"
INVITE_CODE=""
if INVITE_CODE="$(bash "$SCRIPT_DIR/invite.sh" "$USES" 2>"$INVITE_STDERR" | tr -d '\r')"; then
  HAS_INVITE="true"
else
  HAS_INVITE="false"
  INVITE_ERROR="$(tr -d '\r' < "$INVITE_STDERR")"
fi
rm -f "$INVITE_STDERR"

echo "PUB local listo para prueba"
echo "- Web: $WEB_URL"
echo "- Panel API: http://127.0.0.1:${PANEL_PORT}"
echo "- SSB: ${HOST}:${OASIS_PUB_SSB_PORT:-8008}"
echo "- Feed ID: $PUB_ID"
if [ "$HAS_INVITE" = "true" ]; then
  echo "- Invite (${USES} uso/s): $INVITE_CODE"
else
  echo "- Invite: no disponible con la configuración local actual"
  if printf '%s' "${INVITE_ERROR:-}" | grep -qi 'no public ip address'; then
    echo '  ↳ `ssb-invite` exige una dirección pública utilizable. En local puedes validar el pub, logs y panel; para invites reales usa un dominio/IP públicos o una IP accesible desde otra máquina.'
  elif [ -n "${INVITE_ERROR:-}" ]; then
    echo "  ↳ Error: ${INVITE_ERROR}"
  fi
fi
echo
if [ "$HAS_INVITE" = "true" ]; then
  echo "Si ya tienes el cliente Oasis local, puedes intentar unirlo con:"
  echo "npm run pub:local:join-client"
else
  echo "Para pruebas locales inmediatas, abre la landing y el panel; para unir otro cliente por invite, configura un host público o mueve este perfil al VPS."
fi
