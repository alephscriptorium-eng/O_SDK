#!/usr/bin/env bash
# =============================================================================
# guard-destroy.sh — guarda previa a los comandos destructivos del cliente
# (`npm run downDELETEVOLS`, `npm run cleanDELETEVOLS` → `docker compose down -v …`; WP-O103).
# No borra nada: explica qué sobrevive y qué se pierde, exige confirmación y REHÚSA (exit 1) si la
# cartera ECOin del cliente tiene una wallet.dat sin backup reciente en el host.
#
# Uso (desde la raíz del repo; lo llaman los scripts npm):
#   bash client/scripts/guard-destroy.sh && docker compose down -v
#   GUARD_CONFIRM=BORRAR bash client/scripts/guard-destroy.sh      # no interactivo
#
# Reglas:
#   1. Si existe el volumen de la cartera con wallet.dat y NO hay un backup de ESE volumen de
#      menos de 24 h en devops/backups/client-wallet/ → rehúsa: npm run client:wallet:backup.
#      Si no se puede mirar dentro del volumen, se asume que hay cartera (fail-closed).
#   2. Hay que teclear BORRAR (o GUARD_CONFIRM=BORRAR). Sin terminal y sin variable → rehúsa.
#
# Variables (para el drill):
#   ECOIN_VOLUME         volumen de la cartera (default o-sdk-client-ecoin-data)
#   ECOIN_CONTAINER      contenedor de ecoind  (default ecoin-wallet)
#   ECOIN_IMAGE          imagen para mirar dentro del volumen si el contenedor no existe
#   WALLET_BACKUP_ROOT   backups de la cartera (default <repo>/devops/backups/client-wallet)
#   GUARD_DATA_DIR       raíz de los binds     (default volumes-dev; drill: volumes-dev/drill)
#   GUARD_MAX_AGE_MIN    antigüedad máxima del backup en minutos (default 1440 = 24 h)
#
# Exit: 0 confirmado · 1 rehusado · 2 uso
# =============================================================================
set -euo pipefail
export MSYS_NO_PATHCONV=1

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$REPO_ROOT"

VOLUME="${ECOIN_VOLUME:-o-sdk-client-ecoin-data}"
CONTAINER="${ECOIN_CONTAINER:-ecoin-wallet}"
BACKUP_ROOT="${WALLET_BACKUP_ROOT:-$REPO_ROOT/devops/backups/client-wallet}"
DATA_DIR="${GUARD_DATA_DIR:-volumes-dev}"
MAX_AGE_MIN="${GUARD_MAX_AGE_MIN:-1440}"
IN_DATADIR="/home/ecoin/.ecoin"

refuse() { echo "❌ $*" >&2; echo "   No se ha borrado nada." >&2; exit 1; }
warn()   { echo "⚠️  $*" >&2; }

case "${1:-}" in
  -h|--help) sed -n '2,27p' "$0"; exit 0 ;;
  "") ;;
  *) echo "❌ argumento desconocido: $1 (ver --help)" >&2; exit 2 ;;
esac
[[ "$MAX_AGE_MIN" =~ ^[1-9][0-9]*$ ]] || { echo "❌ GUARD_MAX_AGE_MIN debe ser un entero ≥ 1" >&2; exit 2; }

# ---------------------------------------------------------------- 1. qué sobrevive y qué se pierde
echo "=== guard-destroy · vas a ejecutar un comando destructivo (docker compose down -v …) ==="
echo
echo "SOBREVIVE (no lo toca «down -v»):"
for d in ssb-data ai-models logs client-state; do
  if [ -d "$DATA_DIR/$d" ]; then
    case "$d" in
      ssb-data)     note="identidad SSB (secret), log y blobs" ;;
      ai-models)    note="modelo de IA (.gguf)" ;;
      logs)         note="logs" ;;
      client-state) note="oasis-config.json de la GUI y estado del banking (mapa de direcciones)" ;;
    esac
    echo "  - $DATA_DIR/$d/  ← $note (directorio del host; solo se borra el objeto-volumen que lo apunta)"
  fi
done
HAVE_DOCKER=0
if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then HAVE_DOCKER=1; fi
VOL_EXISTS=0
if [ $HAVE_DOCKER = 1 ] && docker volume inspect "$VOLUME" >/dev/null 2>&1; then VOL_EXISTS=1; fi
if [ $VOL_EXISTS = 1 ]; then
  echo "  - volumen docker $VOLUME ← cartera ECOin (wallet.dat + cadena). Es EXTERNO: «down -v» no lo borra."
else
  echo "  - (el volumen de la cartera $VOLUME no existe$([ $HAVE_DOCKER = 1 ] || echo ' o docker no responde'))"
fi
echo
echo "SE PIERDE:"
echo "  - contenedores, red y objetos-volumen del proyecto (se recrean con «npm run up»)"
echo "  - todo lo escrito en la capa del contenedor fuera de los directorios de arriba"
echo "  - con cleanDELETEVOLS, además: imágenes y caché sin usar (docker system prune -f)"
echo
echo "NUNCA: «docker volume prune», «docker system prune --volumes», «docker volume rm $VOLUME»:"
echo "       esos SÍ borran la cartera. Y $DATA_DIR/ssb-data es tu identidad: no lo borres a mano."
echo

# ---------------------------------------------------------------- 2. cartera sin backup reciente → rehúsa
wallet_state() {  # → yes | no | unknown
  local img=""
  if docker inspect "$CONTAINER" >/dev/null 2>&1; then
    img="$(docker inspect -f '{{.Image}}' "$CONTAINER" | tr -d '\r')"
  elif [ -n "${ECOIN_IMAGE:-}" ]; then
    img="$ECOIN_IMAGE"
  else
    img="$(docker images --format '{{.Repository}}:{{.Tag}}' 2>/dev/null | tr -d '\r' \
           | grep -E '^(o-sdk[-_a-z]*ecoin[-_a-z]*|oasis-pub-ecoin):' | grep -v '<none>' | head -n 1 || true)"
  fi
  [ -n "$img" ] || { echo unknown; return 0; }
  local rc=0
  docker run --rm --network none -v "$VOLUME:/w:ro" --entrypoint sh "$img" \
    -c '[ -r /w ] || exit 3; [ -f /w/wallet.dat ]' >/dev/null 2>&1 || rc=$?
  case $rc in 0) echo yes ;; 1) echo no ;; *) echo unknown ;; esac
}
recent_backup() {  # imprime el backup más reciente (< MAX_AGE_MIN) de ESTE volumen, o nada
  [ -d "$BACKUP_ROOT" ] || return 0
  local m d
  while IFS= read -r m; do
    d="$(dirname "$m")"
    grep -q "\"volume\": *\"$VOLUME\"" "$m" 2>/dev/null || continue
    [ -n "$(find "$d" -maxdepth 1 -type f -name 'wallet-*.dat' -size +0 -print -quit 2>/dev/null)" ] || continue
    ( cd "$d" && tr -d '\r' < SHA256SUMS.txt | sha256sum -c --quiet - ) >/dev/null 2>&1 || continue
    echo "$d"; return 0   # el primero basta (y sin «| head»: con pipefail sería un SIGPIPE)
  done < <(find "$BACKUP_ROOT" -mindepth 2 -maxdepth 2 -type f -name MANIFEST.json -mmin "-$MAX_AGE_MIN" 2>/dev/null | sort -r)
}

if [ $VOL_EXISTS = 1 ]; then
  WS="$(wallet_state)"
  if [ "$WS" = no ]; then
    echo "Cartera: el volumen $VOLUME existe pero aún no contiene wallet.dat."
  else
    [ "$WS" = yes ] || warn "no se pudo mirar dentro de $VOLUME: se asume que contiene una wallet.dat"
    BK="$(recent_backup)"
    if [ -z "$BK" ]; then
      refuse "el volumen $VOLUME contiene una wallet.dat y no hay un backup verificado de menos de $((MAX_AGE_MIN / 60)) h en ${BACKUP_ROOT#"$REPO_ROOT"/}/.
   Haz primero:  npm run client:wallet:backup   (y copia el resultado fuera de la máquina)"
    fi
    echo "Cartera: backup reciente y verificado → ${BK#"$REPO_ROOT"/}"
  fi
elif [ $HAVE_DOCKER = 0 ]; then
  refuse "docker no responde: no se puede comprobar si hay una cartera sin backup"
fi
echo

# ---------------------------------------------------------------- 3. confirmación
ANSWER="${GUARD_CONFIRM:-}"
if [ -z "$ANSWER" ]; then
  if [ -t 0 ]; then
    read -r -p "Escribe BORRAR para continuar: " ANSWER || ANSWER=""
  else
    refuse "sin terminal y sin GUARD_CONFIRM=BORRAR: no se confirma nada por ti"
  fi
fi
[ "$ANSWER" = "BORRAR" ] || refuse "confirmación incorrecta (había que escribir BORRAR, en mayúsculas)"
echo "✅ confirmado: continúa el comando destructivo."
