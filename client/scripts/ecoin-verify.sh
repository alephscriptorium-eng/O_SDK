#!/usr/bin/env bash
# =============================================================================
# ecoin-verify.sh — comprueba los criterios de aceptación de ECOin en el cliente (WP-O103;
# docs/CLIENT-PROTOCOL.md «ECOin en el cliente»). SOLO LECTURA: no publica nada, no llama a
# ninguna ruta de la GUI (abrir `/` o `/banking` puede publicar la dirección) y no imprime secretos.
#
# Uso (desde la raíz del repo, con el cliente en marcha):
#   bash client/scripts/ecoin-verify.sh [--expect-wallet-msgs N]
#   CLIENT_CONTAINER=oasis-client-drill ECOIN_CONTAINER=ecoin-wallet-drill HOST_GUI_PORT=3100 \
#     bash client/scripts/ecoin-verify.sh --expect-wallet-msgs 1                  # drill
#
# Comprobaciones (PASS / FAIL / SKIP / INFO):
#   V1  `docker port` de ecoind vacío (ni RPC ni P2P publicados en el host)
#   V2  el host NO alcanza 127.0.0.1:7474 / :7408 / :12000
#   V3  RPC por DNS de servicio desde el cliente: 200 con las credenciales de su entorno,
#       401 con ecoinrpc:ecoinrpc; credenciales ≠ valores públicos por defecto
#   V4  wallet.url / user / pass (y walletPub.pubId) de /app/src/configs/oasis-config.json
#       iguales a ECOIN_RPC_* / OASIS_WALLET_PUB_ID del contenedor (solo se imprime la URL)
#   V5  symlinks: src/configs/oasis-config.json → $OASIS_CLIENT_STATE_DIR/oasis-config.json y
#       src/configs/wallet-addresses.json → $OASIS_BANKING_DIR/wallet-addresses.json
#   V6  nº de mensajes `type: wallet` del feed propio en el log local; con --expect-wallet-msgs N
#       es PASS solo si son exactamente N (el CA del WP es N = 1 tras cualquier nº de recreates)
#   V0  (informativo) puerto de la GUI en el host
#
# En modo «solo dirección» (ECOIN_RPC_URL vacía en el cliente) V3 se comprueba solo si ecoind
# está en marcha, y V4 exige wallet.url = "" (ningún RPC saliente).
#
# Variables: CLIENT_CONTAINER (default oasis-client) · ECOIN_CONTAINER (default ecoin-wallet)
#            HOST_GUI_PORT (default 3000) · ECOIN_SERVICE_URL (default http://ecoin-wallet:7474)
#
# Exit: 0 sin FAIL · 1 algún FAIL · 2 uso · 6 sin docker
# =============================================================================
set -euo pipefail
export MSYS_NO_PATHCONV=1

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$REPO_ROOT"

CLIENT="${CLIENT_CONTAINER:-oasis-client}"
ECOIN="${ECOIN_CONTAINER:-ecoin-wallet}"
GUI_PORT="${HOST_GUI_PORT:-3000}"
SERVICE_URL="${ECOIN_SERVICE_URL:-http://ecoin-wallet:7474}"
COUNTER="$SCRIPT_DIR/lib/count-feed-type.js"
EXPECT=""
NPASS=0; NFAIL=0; NSKIP=0

die()  { echo "❌ $2" >&2; exit "$1"; }
pass() { NPASS=$((NPASS+1)); echo "PASS  $*"; }
fail() { NFAIL=$((NFAIL+1)); echo "FAIL  $*"; }
skip() { NSKIP=$((NSKIP+1)); echo "SKIP  $*"; }
note() { echo "INFO  $*"; }

while [ $# -gt 0 ]; do
  case "$1" in
    --expect-wallet-msgs) shift; EXPECT="${1:-}" ;;
    --expect-wallet-msgs=*) EXPECT="${1#--expect-wallet-msgs=}" ;;
    -h|--help) sed -n '2,32p' "$0"; exit 0 ;;
    *) die 2 "argumento desconocido: $1 (ver --help)" ;;
  esac
  shift
done
[ -z "$EXPECT" ] || [[ "$EXPECT" =~ ^[0-9]+$ ]] || die 2 "--expect-wallet-msgs necesita un entero ≥ 0"

command -v docker >/dev/null 2>&1 || die 6 "docker no disponible"
docker info >/dev/null 2>&1       || die 6 "el demonio de docker no responde"

running() { [ "$(docker inspect -f '{{.State.Running}}' "$1" 2>/dev/null || echo false)" = "true" ]; }
cexec()   { docker exec "$CLIENT" "$@" 2>/dev/null | tr -d '\r'; }

CLIENT_UP=0; running "$CLIENT" && CLIENT_UP=1
ECOIN_UP=0;  running "$ECOIN"  && ECOIN_UP=1
echo "=== ecoin-verify · cliente=$CLIENT ($([ $CLIENT_UP = 1 ] && echo en marcha || echo PARADO)) · ecoind=$ECOIN ($([ $ECOIN_UP = 1 ] && echo en marcha || echo parado)) ==="

# El modo lo dicta el entorno REAL del contenedor del cliente (no el .env del host).
ENV_URL=""; WIRING=""
if [ $CLIENT_UP = 1 ]; then
  ENV_URL="$(cexec sh -c 'printf %s "${ECOIN_RPC_URL-}"')"
  WIRING="$(cexec sh -c 'printf %s "${OASIS_WALLET_WIRING-}"')"
fi
MODE="address"; [ -z "$ENV_URL" ] || MODE="own"
note "modo: $MODE (ECOIN_RPC_URL del cliente = '$ENV_URL')"
note "V0 GUI en el host: $(docker port "$CLIENT" 3000/tcp 2>/dev/null | tr -d '\r' | head -n 1 || true) (esperado :$GUI_PORT)"

# ---------------------------------------------------------------- V1 docker port vacío
if docker inspect "$ECOIN" >/dev/null 2>&1; then
  PORTS="$(docker port "$ECOIN" 2>/dev/null | tr -d '\r' || true)"
  if [ -z "$PORTS" ]; then pass "V1 $ECOIN no publica ningún puerto en el host"
  else fail "V1 $ECOIN publica puertos: $(echo "$PORTS" | tr '\n' ' ')"; fi
else
  skip "V1 no existe el contenedor $ECOIN"
fi

# ---------------------------------------------------------------- V2 el host no alcanza los puertos
probe_host() {  # 0 = algo acepta la conexión
  if command -v timeout >/dev/null 2>&1; then
    timeout 3 bash -c "exec 3<>/dev/tcp/127.0.0.1/$1" >/dev/null 2>&1
  else
    node -e 'const s=require("net").connect(+process.argv[1],"127.0.0.1");s.setTimeout(3000);s.on("connect",()=>process.exit(0));s.on("error",()=>process.exit(1));s.on("timeout",()=>process.exit(1));' "$1" >/dev/null 2>&1
  fi
}
for p in 7474 7408 12000; do
  if probe_host "$p"; then fail "V2 el host alcanza 127.0.0.1:$p (algo escucha: ¿puerto publicado u otro stack?)"
  else pass "V2 el host no alcanza 127.0.0.1:$p"; fi
done

# ---------------------------------------------------------------- V3 RPC por DNS de servicio
if [ $CLIENT_UP = 0 ]; then
  skip "V3 $CLIENT parado: no se puede probar el RPC desde dentro"
elif [ $ECOIN_UP = 0 ]; then
  if [ "$MODE" = own ]; then fail "V3 modo own pero $ECOIN no está en marcha (npm run ecoin:up)"
  else skip "V3 modo address y $ECOIN parado: nada que probar"; fi
else
  RPC_BODY='{"jsonrpc":"1.0","id":"verify","method":"getinfo","params":[]}'
  # Todo ocurre DENTRO del cliente con SU entorno: las credenciales no salen del contenedor.
  CODE_OK="$(docker exec -e V_URL="${ENV_URL:-$SERVICE_URL}" -e V_BODY="$RPC_BODY" "$CLIENT" sh -c \
    'curl -s -o /dev/null -m 10 -w "%{http_code}" --user "${ECOIN_RPC_USER-}:${ECOIN_RPC_PASS-}" -H "content-type: text/plain;" --data-binary "$V_BODY" "$V_URL"' 2>/dev/null | tr -d '\r' || true)"
  CODE_DEF="$(docker exec -e V_URL="${ENV_URL:-$SERVICE_URL}" -e V_BODY="$RPC_BODY" "$CLIENT" sh -c \
    'curl -s -o /dev/null -m 10 -w "%{http_code}" --user "ecoinrpc:ecoinrpc" -H "content-type: text/plain;" --data-binary "$V_BODY" "$V_URL"' 2>/dev/null | tr -d '\r' || true)"
  [ "$CODE_OK" = 200 ]  && pass "V3 RPC ${ENV_URL:-$SERVICE_URL} desde $CLIENT con las credenciales del entorno → 200" \
                        || fail "V3 RPC ${ENV_URL:-$SERVICE_URL} desde $CLIENT con las credenciales del entorno → '${CODE_OK:-sin respuesta}' (esperado 200)"
  [ "$CODE_DEF" = 401 ] && pass "V3 RPC con ecoinrpc:ecoinrpc → 401" \
                        || fail "V3 RPC con ecoinrpc:ecoinrpc → '${CODE_DEF:-sin respuesta}' (esperado 401)"
  WEAK="$(cexec sh -c 'u="${ECOIN_RPC_USER-}"; p="${ECOIN_RPC_PASS-}"; case "$u" in ""|ecoinrpc|CHANGE_ME*) echo weak; exit;; esac; case "$p" in ""|ecoinrpc|CHANGE_ME*) echo weak; exit;; esac; [ "${#p}" -ge 32 ] && echo ok || echo short')"
  case "$WEAK" in
    ok)    pass "V3 credenciales generadas (≠ ecoinrpc; contraseña ≥ 32 caracteres)" ;;
    short) fail "V3 la contraseña RPC tiene menos de 32 caracteres" ;;
    *)     fail "V3 credenciales vacías o públicas por defecto en el entorno de $CLIENT" ;;
  esac
fi

# ---------------------------------------------------------------- V4 config cableada · V5 symlinks
if [ $CLIENT_UP = 0 ]; then
  skip "V4 $CLIENT parado"; skip "V5 $CLIENT parado"
else
  if [ "$WIRING" = manual ]; then
    skip "V4 OASIS_WALLET_WIRING=manual: el entrypoint no cablea (manda lo tecleado en /settings/wallet)"
  else
    V4="$(docker exec -i "$CLIENT" node - <<'NODE' 2>/dev/null | tr -d '\r' || true
const fs = require('fs');
const e = process.env;
let c;
try { c = JSON.parse(fs.readFileSync('/app/src/configs/oasis-config.json', 'utf8')); }
catch (err) { console.log('ERR no se pudo leer oasis-config.json: ' + err.message); process.exit(0); }
const w = c.wallet || {};
const wantUrl = e.ECOIN_RPC_URL || '';
const r = [];
r.push((w.url || '') === wantUrl ? 'OK url=' + JSON.stringify(w.url || '') : 'KO url=' + JSON.stringify(w.url || '') + ' (entorno: ' + JSON.stringify(wantUrl) + ')');
if (e.ECOIN_RPC_URL !== undefined) {
  r.push((w.user || '') === (e.ECOIN_RPC_USER || '') ? 'OK user coincide' : 'KO user distinto del entorno');
  r.push((w.pass || '') === (e.ECOIN_RPC_PASS || '') ? 'OK pass coincide' : 'KO pass distinta del entorno');
} else {
  r.push('KO ECOIN_RPC_URL no está definida en el contenedor (el entrypoint no cablea)');
}
r.push(c.walletPub ? 'KO queda la clave obsoleta walletPub en oasis-config.json (recrea el contenedor: el entrypoint la retira)' : 'OK sin walletPub (el banco se autodescubre desde Oasis 1.1.3)');
if (e.OASIS_WALLET_FEE) r.push(String(w.fee) === String(e.OASIS_WALLET_FEE) ? 'OK fee=' + w.fee : 'KO fee=' + JSON.stringify(w.fee) + ' (entorno: ' + e.OASIS_WALLET_FEE + ')');
console.log(r.join('\n'));
NODE
)"
    if [ -z "$V4" ]; then fail "V4 no se pudo inspeccionar la config dentro de $CLIENT"; fi
    while IFS= read -r line; do
      [ -n "$line" ] || continue
      case "$line" in
        OK*)  pass "V4 ${line#OK }" ;;
        NA*)  note "V4 ${line#NA }" ;;
        *)    fail "V4 ${line#K[O] }" ;;
      esac
    done <<< "$V4"
  fi

  V5="$(cexec sh -c '
    s="${OASIS_CLIENT_STATE_DIR-}"
    [ -n "$s" ] || { echo "KO OASIS_CLIENT_STATE_DIR no definida en el contenedor"; exit 0; }
    [ -z "${OASIS_BANKING_DIR-}" ] && echo "OK OASIS_BANKING_DIR no definida (estado bancario en ~/.ssb/oasis/banking)" || echo "KO OASIS_BANKING_DIR definida: en Oasis 1.1.4 parte el estado en dos mapas de direcciones"
    chk() { t="$(readlink "$1" 2>/dev/null || true)"
      if [ "$t" = "$2" ] && [ -f "$2" ]; then echo "OK $1 → $2"
      elif [ -z "$t" ]; then echo "KO $1 no es un symlink (estado en la capa efímera)"
      else echo "KO $1 → $t (esperado $2$([ -f "$2" ] || echo "; el destino no existe"))"; fi; }
    chk /app/src/configs/oasis-config.json "$s/oasis-config.json"
    [ ! -e /app/src/configs/wallet-addresses.json ] && [ ! -L /app/src/configs/wallet-addresses.json ] && echo "OK sin mapa de direcciones en src/configs" || echo "KO queda /app/src/configs/wallet-addresses.json (resto de 1.1.2: state-manager lo migraría)"
    m=/home/oasis/.ssb/oasis/banking/wallet-addresses.json; [ -L "$m" ] && echo "KO $m es un symlink" || true' || true)"
  [ -n "$V5" ] || fail "V5 no se pudieron inspeccionar los symlinks dentro de $CLIENT"
  while IFS= read -r line; do
    [ -n "$line" ] || continue
    case "$line" in OK*) pass "V5 ${line#OK }" ;; *) fail "V5 ${line#KO }" ;; esac
  done <<< "$V5"
fi

# ---------------------------------------------------------------- V6 mensajes `wallet` del feed propio
if [ $CLIENT_UP = 0 ]; then
  skip "V6 $CLIENT parado (a mano: node client/scripts/lib/count-feed-type.js <dir-.ssb> wallet)"
else
  V6="$(docker exec -i "$CLIENT" node - /home/oasis/.ssb wallet < "$COUNTER" 2>/dev/null | tr -d '\r' | tail -n 1 || true)"
  COUNT="$(printf '%s' "$V6" | grep -o '"count":[0-9]*' | cut -d: -f2 || true)"
  DISTINCT="$(printf '%s' "$V6" | grep -o '"distinct":[0-9]*' | cut -d: -f2 || true)"
  FEED="$(printf '%s' "$V6" | grep -o '"feed":"[^"]*"' | cut -d'"' -f4 || true)"
  if [ -z "$COUNT" ] || ! printf '%s' "$V6" | grep -q '"ok":true'; then
    fail "V6 no se pudo contar en el log (¿sbot escribiendo? reintenta): ${V6:-sin salida}"
  elif [ -n "$EXPECT" ]; then
    [ "$COUNT" = "$EXPECT" ] && pass "V6 $COUNT mensaje(s) wallet de $FEED (esperado $EXPECT; direcciones distintas: $DISTINCT)" \
                             || fail "V6 $COUNT mensaje(s) wallet de $FEED (esperado $EXPECT; direcciones distintas: $DISTINCT)"
  else
    note "V6 $COUNT mensaje(s) wallet de $FEED (direcciones distintas: $DISTINCT). Usa --expect-wallet-msgs N para exigirlo"
    [ "$COUNT" -le 1 ] || echo "⚠️  más de un mensaje wallet: POST /banking/addresses no es idempotente y los mensajes son irreversibles" >&2
  fi
fi

echo
echo "=== resultado: $NPASS PASS · $NFAIL FAIL · $NSKIP SKIP ==="
[ $NFAIL = 0 ]
