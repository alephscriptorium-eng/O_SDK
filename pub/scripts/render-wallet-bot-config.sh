#!/usr/bin/env bash
# render-wallet-bot-config.sh — rellena pub/config/wallet-bot/oasis-config.json.tpl (WP-O102).
#
# Uso:
#   render-wallet-bot-config.sh <env-file> [--out <ruta>]     renderiza
#   render-wallet-bot-config.sh <env-file> [--out <ruta>] --check   solo valida un destino existente
#
# Lee del env-file SOLO estas claves (no hace source del fichero):
#   OASIS_ECOIN_RPC_USER, OASIS_ECOIN_RPC_PASS   hex, `openssl rand -hex 32`
#   OASIS_WALLET_BOT_PUB_ID                      vacio = motor de RBU APAGADO; feed del bot = ENCENDIDO
#   OASIS_WALLET_BOT_OASIS_CONFIG_FILE           destino (relativo a pub/ si no es absoluto)
#
# El destino es un bind de FICHERO del contenedor oasis-pub-wallet-bot: se escribe IN PLACE
# (cat >, nunca mv: cambiar el inodo rompe el bind) y queda a 400. Si Docker arranco antes
# del render habra creado un DIRECTORIO en esa ruta: se aborta, no se arregla solo.
# El resumen que imprime no contiene secretos.

set -euo pipefail
umask 077

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PUB_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
TEMPLATE="$PUB_DIR/config/wallet-bot/oasis-config.json.tpl"

RE_HEX='^[0-9a-f]{32,128}$'
RE_FEED='^@[A-Za-z0-9+/]{43}=\.ed25519$'

die() { echo "render-wallet-bot-config: ERROR: $*" >&2; exit 1; }

usage() {
  sed -n '2,8p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
  exit "${1:-2}"
}

ENV_FILE=""
OUT=""
CHECK=0
while [ $# -gt 0 ]; do
  case "$1" in
    --out) [ $# -ge 2 ] || die "--out necesita una ruta"; OUT="$2"; shift 2 ;;
    --out=*) OUT="${1#--out=}"; shift ;;
    --check) CHECK=1; shift ;;
    -h|--help) usage 0 ;;
    -*) die "opcion desconocida: $1" ;;
    *) [ -z "$ENV_FILE" ] || die "sobra el argumento: $1"; ENV_FILE="$1"; shift ;;
  esac
done
[ -n "$ENV_FILE" ] || usage 2
[ -f "$ENV_FILE" ] || die "no existe el env-file: $ENV_FILE"
[ -f "$TEMPLATE" ] || die "no existe la plantilla: $TEMPLATE"

# Extrae UNA clave del env-file: ultima asignacion, sin CR, sin comillas envolventes.
env_get() {
  local key="$1" line val
  line="$(grep -E "^[[:space:]]*(export[[:space:]]+)?${key}=" "$ENV_FILE" | tail -n 1 || true)"
  val="${line#*=}"
  val="${val%$'\r'}"
  case "$val" in
    \"*\") val="${val#\"}"; val="${val%\"}" ;;
    \'*\') val="${val#\'}"; val="${val%\'}" ;;
  esac
  printf '%s' "$val"
}

is_absolute() { [[ "$1" = /* ]] || [[ "$1" =~ ^[A-Za-z]:[/\\] ]]; }

mask() { local v="$1"; printf '%s…(%d)' "${v:0:4}" "${#v}"; }

validate_creds() {
  local user="$1" pass="$2"
  [ -n "$user" ] || die "OASIS_ECOIN_RPC_USER vacio (genera con: openssl rand -hex 32)"
  [ -n "$pass" ] || die "OASIS_ECOIN_RPC_PASS vacio (genera con: openssl rand -hex 32)"
  [ "$user" != "ecoinrpc" ] || die "OASIS_ECOIN_RPC_USER es el default 'ecoinrpc': prohibido"
  [ "$pass" != "ecoinrpc" ] || die "OASIS_ECOIN_RPC_PASS es el default 'ecoinrpc': prohibido"
  [[ "$user" =~ $RE_HEX ]] || die "OASIS_ECOIN_RPC_USER no es hex en minusculas de 32-128 caracteres"
  [[ "$pass" =~ $RE_HEX ]] || die "OASIS_ECOIN_RPC_PASS no es hex en minusculas de 32-128 caracteres"
  [ "$user" != "$pass" ] || die "OASIS_ECOIN_RPC_USER y OASIS_ECOIN_RPC_PASS son iguales"
}

validate_pub_id() {
  local id="$1"
  [ -z "$id" ] || [[ "$id" =~ $RE_FEED ]] || die "OASIS_WALLET_BOT_PUB_ID mal formado (esperado @<43 base64>=.ed25519 o vacio)"
}

# Valor de una clave string del JSON renderizado (formato de una clave por linea).
json_str() { sed -n "s/^[[:space:]]*\"$2\":[[:space:]]*\"\\(.*\\)\",\\{0,1\\}[[:space:]]*\$/\\1/p" "$1" | head -n 1; }

validate_json() {
  local f="$1"
  if command -v node >/dev/null 2>&1; then
    node -e 'JSON.parse(require("fs").readFileSync(process.argv[1],"utf8"))' "$f" 2>/dev/null \
      || die "el resultado no parsea como JSON: $f"
  elif command -v python3 >/dev/null 2>&1; then
    python3 -c 'import json,sys; json.load(open(sys.argv[1], encoding="utf-8"))' "$f" 2>/dev/null \
      || die "el resultado no parsea como JSON: $f"
  else
    echo "render-wallet-bot-config: AVISO: sin node ni python3; JSON no verificado con parser" >&2
  fi
}

validate_rendered() {
  local f="$1"
  [ -s "$f" ] || die "el destino esta vacio: $f"
  if grep -Eq '__[A-Z0-9_]+__' "$f"; then die "quedan marcadores __…__ sin sustituir en $f"; fi
  validate_json "$f"
  validate_creds "$(json_str "$f" user)" "$(json_str "$f" pass)"
  validate_pub_id "$(json_str "$f" pubId)"
}

summary() {
  local f="$1" id
  id="$(json_str "$f" pubId)"
  echo "  destino : $f"
  echo "  permisos: $(stat -c '%a' "$f" 2>/dev/null || echo '?')"
  echo "  url     : $(json_str "$f" url)"
  echo "  user    : $(mask "$(json_str "$f" user)")"
  echo "  pass    : (oculta, $(json_str "$f" pass | tr -d '\n' | wc -c | tr -d ' ') caracteres)"
  if [ -n "$id" ]; then
    echo "  pubId   : $id  (motor de RBU ENCENDIDO)"
  else
    echo "  pubId   : (vacío: motor APAGADO)"
  fi
}

# --- destino -----------------------------------------------------------------
if [ -z "$OUT" ]; then
  OUT="$(env_get OASIS_WALLET_BOT_OASIS_CONFIG_FILE)"
  [ -n "$OUT" ] || die "sin --out y sin OASIS_WALLET_BOT_OASIS_CONFIG_FILE en $ENV_FILE"
  is_absolute "$OUT" || OUT="$PUB_DIR/$OUT"
fi
if [ -d "$OUT" ]; then
  die "el destino es un DIRECTORIO: $OUT
  (Docker lo crea si se hace 'up' antes del render). Para el servicio, bórralo a mano
  (rmdir) y repite el render; este script no lo borra."
fi

if [ "$CHECK" -eq 1 ]; then
  [ -f "$OUT" ] || die "--check: no existe el destino: $OUT"
  validate_rendered "$OUT"
  perms="$(stat -c '%a' "$OUT" 2>/dev/null || echo '?')"
  case "${OSTYPE:-}" in
    msys*|cygwin*) : ;;  # NTFS no representa 400
    *) [ "$perms" = "400" ] || die "--check: permisos $perms en $OUT (esperado 400)" ;;
  esac
  echo "render-wallet-bot-config: CHECK OK"
  summary "$OUT"
  exit 0
fi

# --- render ------------------------------------------------------------------
RPC_USER="$(env_get OASIS_ECOIN_RPC_USER)"
RPC_PASS="$(env_get OASIS_ECOIN_RPC_PASS)"
PUB_ID="$(env_get OASIS_WALLET_BOT_PUB_ID)"
validate_creds "$RPC_USER" "$RPC_PASS"
validate_pub_id "$PUB_ID"

[ -d "$(dirname "$OUT")" ] || die "no existe el directorio del destino: $(dirname "$OUT")"

# Delimitador «|»: los feed id llevan / y +. Los valores ya validados no contienen | & ni \.
# El programa de sed entra por -f <(printf) (printf es builtin): los secretos no salen en `ps`.
RENDERED="$(sed -f <(printf 's|__ECOIN_RPC_USER__|%s|g\ns|__ECOIN_RPC_PASS__|%s|g\ns|__WALLET_BOT_PUB_ID__|%s|g\n' \
  "$RPC_USER" "$RPC_PASS" "$PUB_ID") "$TEMPLATE")"
[ -n "$RENDERED" ] || die "el render salio vacio"

if [ -e "$OUT" ]; then
  [ -f "$OUT" ] || die "el destino existe y no es un fichero regular: $OUT"
  chmod u+w "$OUT"
fi
printf '%s\n' "$RENDERED" > "$OUT"   # in place: conserva el inodo del bind
chmod 400 "$OUT"
unset RENDERED RPC_USER RPC_PASS

validate_rendered "$OUT"
echo "render-wallet-bot-config: OK"
summary "$OUT"
echo "  aplicar : docker compose ... up -d --no-deps oasis-wallet-bot (el bind :ro se relee al arrancar)"
