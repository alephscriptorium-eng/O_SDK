#!/usr/bin/env bash
# =============================================================================
# ecoin-init.sh — prepara ECOin en el cliente (docs/CLIENT-PROTOCOL.md «ECOin en el cliente»;
# WP-O103). Idempotente. NUNCA pisa credenciales que ya existan.
#
# Uso (desde la raíz del repo):
#   bash client/scripts/ecoin-init.sh --mode address|own [--pub-id <feed>]
#   bash client/scripts/ecoin-init.sh --ensure [--pub-id <feed>]
#   bash client/scripts/ecoin-init.sh --print
#
#   --mode address  solo dirección: COMPOSE_PROFILES sin «ecoin» y ECOIN_RPC_URL= (vacía): el
#                   cliente no hace ningún RPC. La cartera se arranca a mano (npm run ecoin:up)
#                   solo para obtener la dirección y hacer el backup.
#   --mode own      cartera propia: COMPOSE_PROFILES con «ecoin» y
#                   ECOIN_RPC_URL=http://ecoin-wallet:7474 (DNS de servicio; sin puertos al host).
#   --ensure        crea lo que falte (credenciales, volumen, directorios) SIN cambiar el modo.
#                   Es lo que se hace también cuando no se pasa ni --mode ni --ensure.
#   --pub-id FEED   OASIS_WALLET_PUB_ID (el banco; p. ej. bot-2). Se valida el formato del feed.
#   --print         estado actual SIN secretos (ni usuario ni contraseña). No escribe nada.
#
# Qué hace:
#   1. .env de la RAÍZ del repo (600, ignorado por git): si faltan, genera ECOIN_RPC_USER
#      («oasis-» + 8 hex) y ECOIN_RPC_PASS (48 hex). Si el .env ya existe solo añade/actualiza
#      COMPOSE_PROFILES, ECOIN_RPC_URL y OASIS_WALLET_PUB_ID; el resto de líneas no se toca.
#   2. Volumen docker EXTERNO de la cartera (etiqueta o-sdk.role=client-wallet) si no existe.
#      `docker compose down -v` no borra volúmenes externos. PROHIBIDO `docker volume prune`.
#   3. mkdir -p volumes-dev/client-state (oasis-config.json de la GUI; el banking vive en ssb-data/oasis desde 1.1.3).
#
# Variables (para el drill; los valores por defecto son los del cliente real):
#   ECOIN_ENV_FILE   fichero env            (default <repo>/.env; drill: client/.env.drill)
#   ECOIN_VOLUME     volumen de la cartera  (default o-sdk-client-ecoin-data; drill: o-sdk-drill-ecoin-data)
#   ECOIN_STATE_DIR  estado del cliente     (default <repo>/volumes-dev/client-state; drill: volumes-dev/drill/client-state)
#
# Exit: 0 ok · 2 uso · 3 precondición (env versionable, credencial débil) · 6 sin docker
# =============================================================================
set -euo pipefail
umask 077
export MSYS_NO_PATHCONV=1

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$REPO_ROOT"

ENV_FILE="${ECOIN_ENV_FILE:-$REPO_ROOT/.env}"
VOLUME="${ECOIN_VOLUME:-o-sdk-client-ecoin-data}"
STATE_DIR="${ECOIN_STATE_DIR:-$REPO_ROOT/volumes-dev/client-state}"
# rutas relativas → relativas a la raíz del repo (p. ej. ECOIN_ENV_FILE=client/.env.drill)
case "$ENV_FILE"  in /*|[A-Za-z]:*) ;; *) ENV_FILE="$REPO_ROOT/$ENV_FILE" ;; esac
case "$STATE_DIR" in /*|[A-Za-z]:*) ;; *) STATE_DIR="$REPO_ROOT/$STATE_DIR" ;; esac
VOLUME_LABEL="o-sdk.role=client-wallet"
OWN_URL="http://ecoin-wallet:7474"
FEED_RE='^@[A-Za-z0-9+/]{43}=\.ed25519$'

MODE=""; ENSURE=0; PUB_ID=""; PUB_ID_SET=0; PRINT=0
die()  { echo "❌ $2" >&2; exit "$1"; }
warn() { echo "⚠️  $*" >&2; }
info() { echo "→ $*"; }

while [ $# -gt 0 ]; do
  case "$1" in
    --mode) shift; MODE="${1:-}" ;;
    --mode=*) MODE="${1#--mode=}" ;;
    --ensure) ENSURE=1 ;;
    --pub-id) shift; PUB_ID="${1:-}"; PUB_ID_SET=1 ;;
    --pub-id=*) PUB_ID="${1#--pub-id=}"; PUB_ID_SET=1 ;;
    --print) PRINT=1 ;;
    -h|--help) sed -n '2,34p' "$0"; exit 0 ;;
    *) die 2 "argumento desconocido: $1 (ver --help)" ;;
  esac
  shift
done
case "$MODE" in ""|address|own) ;; *) die 2 "--mode debe ser address u own (recibido: '$MODE')" ;; esac
[ -z "$MODE" ] || [ $ENSURE = 0 ] || die 2 "--ensure no cambia el modo: no se combina con --mode"
if [ $PUB_ID_SET = 1 ]; then
  [[ "$PUB_ID" =~ $FEED_RE ]] || die 2 "--pub-id no es un feed SSB válido (@<43 base64>=.ed25519)"
fi

# ---------------------------------------------------------------- utilidades del env
# env_has CLAVE · env_get CLAVE (última aparición, sin CR ni comillas) · env_set CLAVE VALOR
env_has() { [ -f "$ENV_FILE" ] && grep -qE "^$1=" "$ENV_FILE"; }
env_get() {
  [ -f "$ENV_FILE" ] || return 0
  local v
  v="$(grep -E "^$1=" "$ENV_FILE" | tail -n 1 | cut -d= -f2- | tr -d '\r' || true)"
  v="${v%\"}"; v="${v#\"}"; v="${v%\'}"; v="${v#\'}"
  printf '%s' "$v"
}
env_set() {  # sustituye TODAS las líneas CLAVE= por una sola, o la añade al final; no toca nada más
  local key="$1" val="$2" tmp
  if env_has "$key"; then
    tmp="$(mktemp "${ENV_FILE}.XXXXXX")"
    K="$key" V="$val" awk 'BEGIN{k=ENVIRON["K"]"="; v=ENVIRON["V"]; done=0}
      index($0,k)==1 { if(!done){print k v; done=1}; next } {print}' "$ENV_FILE" > "$tmp"
    cat "$tmp" > "$ENV_FILE"; rm -f "$tmp"
  else
    [ ! -s "$ENV_FILE" ] || [ -z "$(tail -c 1 "$ENV_FILE")" ] || printf '\n' >> "$ENV_FILE"
    printf '%s=%s\n' "$key" "$val" >> "$ENV_FILE"
  fi
}
rand_hex() {  # rand_hex <nº de bytes> → 2n caracteres hex
  local n="$1" out=""
  out="$(openssl rand -hex "$n" 2>/dev/null || true)"
  if [ "${#out}" -ne $((n * 2)) ] && [ -r /dev/urandom ]; then
    out="$(head -c "$n" /dev/urandom | od -An -tx1 | tr -d ' \n\r' || true)"
  fi
  if [ "${#out}" -ne $((n * 2)) ] && command -v node >/dev/null 2>&1; then
    out="$(node -e 'process.stdout.write(require("crypto").randomBytes(+process.argv[1]).toString("hex"))' "$n" || true)"
  fi
  [ "${#out}" -eq $((n * 2)) ] && [[ "$out" =~ ^[0-9a-f]+$ ]] || die 3 "no hay fuente de aleatoriedad (openssl, /dev/urandom ni node)"
  printf '%s' "$out"
}
is_weak() { case "$1" in ""|ecoinrpc|CHANGE_ME_VIA_RPC_USER|CHANGE_ME_VIA_RPC_PASS) return 0 ;; *) return 1 ;; esac; }
profiles_with()    { local p="$1"; case ",$p," in *,ecoin,*) printf '%s' "$p" ;; ",,") printf 'ecoin' ;; *) printf '%s,ecoin' "$p" ;; esac; }
profiles_without() { printf '%s' "$1" | tr ',' '\n' | grep -vx 'ecoin' | grep -v '^$' | paste -sd, - || true; }
current_mode() {
  local url prof; url="$(env_get ECOIN_RPC_URL)"; prof="$(env_get COMPOSE_PROFILES)"
  if [ ! -f "$ENV_FILE" ]; then echo "sin-inicializar"
  elif [ -n "$url" ]; then case ",$prof," in *,ecoin,*) echo "own" ;; *) echo "own (¡sin perfil ecoin en COMPOSE_PROFILES!)" ;; esac
  else case ",$prof," in *,ecoin,*) echo "address (con el perfil ecoin encendido: la cartera arranca, el cliente no la usa)" ;; *) echo "address" ;; esac
  fi
}
volume_exists() { docker volume inspect "$VOLUME" >/dev/null 2>&1; }

# ---------------------------------------------------------------- --print (solo lectura, sin secretos)
print_state() {
  local rel="${ENV_FILE#"$REPO_ROOT"/}"
  echo "=== ecoin-init · estado (sin secretos) ==="
  if [ -f "$ENV_FILE" ]; then
    echo "  env              : $rel (permisos $(stat -c '%a' "$ENV_FILE" 2>/dev/null || echo '?'))"
    local k v
    for k in ECOIN_RPC_USER ECOIN_RPC_PASS; do
      v="$(env_get "$k")"
      if [ -z "$v" ]; then echo "  $k   : AUSENTE"
      elif is_weak "$v"; then echo "  $k   : DÉBIL (valor público por defecto: ecoind no arrancará)"
      else echo "  $k   : definida (${#v} caracteres; no se muestra)"; fi
    done
    echo "  ECOIN_RPC_URL    : '$(env_get ECOIN_RPC_URL)'"
    echo "  COMPOSE_PROFILES : '$(env_get COMPOSE_PROFILES)'"
    echo "  OASIS_WALLET_PUB_ID : '$(env_get OASIS_WALLET_PUB_ID)'"
  else
    echo "  env              : $rel NO existe"
  fi
  echo "  modo             : $(current_mode)"
  if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
    if volume_exists; then
      echo "  volumen cartera  : $VOLUME (existe; etiquetas: $(docker volume inspect "$VOLUME" --format '{{range $k,$v := .Labels}}{{$k}}={{$v}} {{end}}' 2>/dev/null | tr -d '\r'))"
    else
      echo "  volumen cartera  : $VOLUME NO existe"
    fi
  else
    echo "  volumen cartera  : (docker no disponible: no se puede comprobar)"
  fi
  echo "  estado cliente   : ${STATE_DIR#"$REPO_ROOT"/} $([ -d "$STATE_DIR" ] && echo '(existe)' || echo 'NO existe')"
}
if [ $PRINT = 1 ]; then print_state; exit 0; fi

# ---------------------------------------------------------------- 0. precondiciones
command -v docker >/dev/null 2>&1 || die 6 "docker no disponible"
docker info >/dev/null 2>&1       || die 6 "el demonio de docker no responde (¿Docker Desktop arrancado?)"
# Un env con credenciales DENTRO del repo tiene que estar ignorado por git.
case "$ENV_FILE" in
  "$REPO_ROOT"/*)
    # Ruta RELATIVA y cd: bajo MSYS_NO_PATHCONV=1 git.exe no entiende /c/... (ni en -C ni como argumento).
    ( cd "$REPO_ROOT" && git check-ignore -q -- "${ENV_FILE#"$REPO_ROOT"/}" ) 2>/dev/null \
      || die 3 "${ENV_FILE#"$REPO_ROOT"/} NO está ignorado por git: no se escriben credenciales en un fichero versionable" ;;
esac

# ---------------------------------------------------------------- 1. env: credenciales (solo si faltan)
NEW_ENV=0
if [ ! -f "$ENV_FILE" ]; then
  NEW_ENV=1
  mkdir -p "$(dirname "$ENV_FILE")"
  {
    echo "# Generado por client/scripts/ecoin-init.sh ($(date -u +%Y-%m-%dT%H:%M:%SZ)). NO versionar. Plantilla: .env.example"
    echo "# Credenciales del RPC de la cartera ECOin del cliente (ecoin-wallet). No se regeneran nunca:"
    echo "# si las cambias, cámbialas aquí y recrea ecoin-wallet y oasis-client a la vez."
  } > "$ENV_FILE"
  info "creado ${ENV_FILE#"$REPO_ROOT"/}"
fi
chmod 600 "$ENV_FILE" 2>/dev/null || true

for k in ECOIN_RPC_USER ECOIN_RPC_PASS; do
  cur="$(env_get "$k")"
  if [ -z "$cur" ]; then
    if [ "$k" = ECOIN_RPC_USER ]; then env_set "$k" "oasis-$(rand_hex 4)"; else env_set "$k" "$(rand_hex 24)"; fi
    info "$k generada (no se muestra)"
  elif is_weak "$cur"; then
    die 3 "$k tiene un valor público por defecto en ${ENV_FILE#"$REPO_ROOT"/}. No se pisa: bórrala o cámbiala a mano y reejecuta (ecoind no arranca con ella)"
  else
    info "$k ya existe: no se toca"
  fi
done
unset cur

# ---------------------------------------------------------------- 2. env: modo y banco
if [ "$MODE" = own ]; then
  env_set COMPOSE_PROFILES "$(profiles_with "$(env_get COMPOSE_PROFILES)")"
  env_set ECOIN_RPC_URL "$OWN_URL"
elif [ "$MODE" = address ]; then
  env_set COMPOSE_PROFILES "$(profiles_without "$(env_get COMPOSE_PROFILES)")"
  env_set ECOIN_RPC_URL ""
else
  # --ensure / sin modo: solo se añaden las claves que falten, con el valor por defecto (address)
  env_has COMPOSE_PROFILES || env_set COMPOSE_PROFILES ""
  env_has ECOIN_RPC_URL    || env_set ECOIN_RPC_URL ""
fi
[ $PUB_ID_SET = 1 ] && warn "--pub-id ya no hace nada: desde Oasis 1.1.3 el cliente descubre el banco por los anuncios de los pubs"
chmod 600 "$ENV_FILE" 2>/dev/null || true

# ---------------------------------------------------------------- 3. volumen externo de la cartera
if volume_exists; then
  info "volumen $VOLUME ya existe: no se toca"
else
  docker volume create --label "$VOLUME_LABEL" "$VOLUME" >/dev/null
  info "volumen $VOLUME creado (externo, etiqueta $VOLUME_LABEL)"
fi

# ---------------------------------------------------------------- 4. estado persistente del cliente
mkdir -p "$STATE_DIR"

echo
print_state
echo
case "$(current_mode)" in
  own*)
    echo "SIGUIENTE: npm run ecoin:up  → esperar a que sincronice → npm run client:wallet:backup"
    echo "           (el backup va ANTES de publicar la dirección: el mensaje «wallet» es irreversible)." ;;
  *)
    echo "Modo «solo dirección»: el cliente no hace RPC (ECOIN_RPC_URL vacía). Para obtener una dirección"
    echo "de una wallet.dat propia: npm run ecoin:up → npm run ecoin:address → npm run client:wallet:backup."
    echo "Para saldo/envíos/historial en la GUI: bash client/scripts/ecoin-init.sh --mode own" ;;
esac
warn "la cartera vive en el volumen docker $VOLUME: PROHIBIDO «docker volume prune» / «docker system prune --volumes»."
