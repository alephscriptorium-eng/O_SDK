#!/usr/bin/env bash
# =============================================================================
# test-invite.sh — Gate PARTE 0.3: probar el camino invite → follow-back.
#
# Valida el MECANISMO de que el pub sigue de vuelta a quien redime su invite.
# (No confunde con el "verde" del directorio, que además exige que un pub raíz
#  nos siga — eso es discoverability, paso social con La Plaza.)
#
# Modos:
#   diagnose
#       Solo SSH al pub. Crea un invite y verifica formato + que quede
#       registrado en el sbot. No necesita cliente. (Escribe en el pub.)
#
#   redeem <CLIENT_URL>
#       Necesita un cliente Oasis corriendo (p.ej. http://localhost:3000).
#       1) obtiene un invite fresco del pub,
#       2) lo redime en el cliente vía POST /settings/invite/accept,
#       3) verifica el follow-back: el pub publica contact→<cliente> following:true.
#
# Env SSH (reutiliza la convención de pub-federation.sh):
#   REMOTE_USER=debian  REMOTE_HOST=92.243.24.163
#   KEY_PATH=devops/.ssh/gandi_pub_ed25519
#   PUB_CONTAINER=oasis-pub-scriptorium
# =============================================================================
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# Datos de instancia → devops/hosts/<DEVOPS_HOST>/host.env
# shellcheck disable=SC1091
source "$(dirname "${BASH_SOURCE[0]}")/lib-host.sh"
REMOTE_USER="${REMOTE_USER:-}"
REMOTE_HOST="${REMOTE_HOST:-}"
KEY_PATH="${KEY_PATH:-}"
PUB_CONTAINER="${PUB_CONTAINER:-oasis-pub}"
SSB_ADMIN="node /app/pub/tools/ssb-admin.js"

ssh_pub() {
  ssh -i "$KEY_PATH" -o StrictHostKeyChecking=accept-new -o BatchMode=yes -o ConnectTimeout=15 \
    "$REMOTE_USER@$REMOTE_HOST" "$1"
}
exec_pub() { ssh_pub "docker exec $PUB_CONTAINER sh -lc '$1'"; }

create_invite() { exec_pub "$SSB_ADMIN invite.create ${1:-1} 2>/dev/null" | grep -oE '[^[:space:]\"]+:[0-9]+:@[A-Za-z0-9+/]+=\.ed25519~[A-Za-z0-9+/]+=?' | head -1; }
pub_feed()      { exec_pub "$SSB_ADMIN whoami 2>/dev/null" | grep -oE '@[A-Za-z0-9+/]+=\.ed25519' | head -1; }
# nº de mensajes contact (following) que el PUB ha emitido (proxy de a cuántos sigue)
pub_follow_count() { exec_pub "grep -a -c '\"type\":\"contact\"' /home/oasis/.ssb/flume/log.offset 2>/dev/null" | tr -dc '0-9'; }

mode="${1:-diagnose}"

case "$mode" in
  diagnose)
    echo "=== test-invite: diagnose (pub $PUB_CONTAINER @ $REMOTE_HOST) ==="
    inv="$(create_invite 1)"
    if [ -n "$inv" ]; then
      echo "  invite creado: ${inv%~*}~…(seed oculto)"
      echo "  formato: OK (host:port:@feedid.ed25519~seed)"
    else
      echo "  [FALLO] invite.create no devolvió un invite bien formado"
      exit 1
    fi
    echo "  registrados en .ssb/invites:"
    exec_pub "cat /home/oasis/.ssb/invites 2>/dev/null | wc -l | tr -dc 0-9" | sed 's/^/    líneas=/'
    echo
    echo "  Nota: el redeem real necesita un cliente → 'test-invite.sh redeem <URL>'."
    ;;

  redeem)
    CLIENT_URL="${2:-http://localhost:3000}"
    echo "=== test-invite: redeem contra $CLIENT_URL ==="
    before="$(pub_follow_count)"; before="${before:-0}"
    echo "  contacts del pub (antes): $before"
    inv="$(create_invite 1)"
    [ -n "$inv" ] || { echo "  [FALLO] no pude crear invite"; exit 1; }
    echo "  invite: ${inv%~*}~…"
    echo "  redimiendo en el cliente…"
    code="$(curl -s -o /dev/null -w '%{http_code}' --max-time 30 \
      -X POST "$CLIENT_URL/settings/invite/accept" \
      --data-urlencode "invite=$inv" || echo 000)"
    echo "  POST /settings/invite/accept → HTTP $code"
    # dar tiempo a que el pub procese invite.use y publique el follow
    sleep 6
    after="$(pub_follow_count)"; after="${after:-0}"
    echo "  contacts del pub (después): $after"
    if [ "$after" -gt "$before" ]; then
      echo "  ✓ FOLLOW-BACK detectado (el pub siguió al redentor). Mecanismo OK."
    else
      echo "  ⚠ sin follow-back detectado aún (revisa logs del pub / reintenta)."
    fi
    echo
    echo "  Recordatorio: esto valida el mecanismo, NO pone verde el directorio"
    echo "  (para el verde hace falta que un pub raíz — La Plaza — nos siga)."
    ;;

  *)
    echo "uso: test-invite.sh [diagnose | redeem <CLIENT_URL>]"; exit 2 ;;
esac
