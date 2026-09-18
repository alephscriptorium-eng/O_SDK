#!/usr/bin/env bash
# =============================================================================
# backup-wallet.sh — copia de seguridad y restauración de la cartera ECOin del CLIENTE
# (servicio `ecoin-wallet`, volumen docker externo o-sdk-client-ecoin-data; WP-O103,
# docs/CLIENT-PROTOCOL.md «ECOin en el cliente»). Hermano local de devops/scripts/backup-ecoin.sh.
#
# wallet.dat ES el dinero y ES la dirección publicada en tu feed: quien la tiene, gasta; si se
# pierde sin copia, la dirección del mensaje `wallet` (permanente) queda huérfana para siempre.
# El volumen nombrado vive dentro de la VM de Docker Desktop (WSL2): un «factory reset» o un
# `docker volume prune` se lo llevan. La copia en el host es OBLIGATORIA, y antes de publicar.
#
# Uso (desde la raíz del repo):
#   bash client/scripts/backup-wallet.sh                 # caliente (ecoind en marcha)
#   bash client/scripts/backup-wallet.sh --cold          # frío: stop → copia → start
#   bash client/scripts/backup-wallet.sh --verify <dir>  # recomprueba los sha256 de un backup
#   bash client/scripts/backup-wallet.sh --restore <dir> # restaura (aparta la actual; NUNCA sobrescribe)
#
# Modos:
#   (por defecto)   CALIENTE. `ecoind backupwallet` a /home/ecoin/.ecoin/backups/ dentro del
#                   contenedor → docker cp al host → sha256 contenedor == host o aborta → se borra
#                   la copia del contenedor. ecoind no se para.
#   --cold          FRÍO. docker stop (cierre limpio de BDB; respeta stop_grace_period) → copia de
#                   wallet.dat → docker start (también si la copia falla: trap).
#   --verify DIR    sha256sum -c del SHA256SUMS.txt. Solo lectura, sin docker.
#   --restore DIR   verifica DIR → para ecoind → deja la copia junto a la cartera y comprueba su
#                   sha256 DENTRO del volumen → aparta la actual a wallet.dat.pre-restore-<TS>
#                   (en el mismo volumen; no se borra nada) → coloca la copia → arranca → espera
#                   al RPC y lista las direcciones. Requiere que el contenedor exista
#                   (npm run ecoin:up al menos una vez).
#
# Destino: devops/backups/client-wallet/<TS-UTC>/ (700; ignorado por git) con
#   wallet-<TS>.dat (600) · SHA256SUMS.txt · MANIFEST.json (getinfo.blocks, direcciones, imagen,
#   volumen) · RESTORE.txt
#
# Avisos: la cartera NO está cifrada → el backup es material de claves en claro: muévelo a
# almacenamiento cifrado fuera de la máquina. El keypool rota con los envíos: repite el backup
# tras ~50 envíos o direcciones nuevas, y SIEMPRE antes de publicar una dirección.
#
# Variables (para el drill):
#   ECOIN_CONTAINER      contenedor de ecoind  (default ecoin-wallet; drill: ecoin-wallet-drill)
#   WALLET_BACKUP_ROOT   destino en el host    (default <repo>/devops/backups/client-wallet)
#
# Exit: 0 ok · 1 error · 2 uso
# =============================================================================
set -euo pipefail
umask 077
export MSYS_NO_PATHCONV=1

PROGRAM_NAME="$(basename "$0")"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$REPO_ROOT"

CONTAINER="${ECOIN_CONTAINER:-ecoin-wallet}"
IN_DATADIR="/home/ecoin/.ecoin"           # datadir visto desde dentro del contenedor
BACKUP_ROOT="${WALLET_BACKUP_ROOT:-$REPO_ROOT/devops/backups/client-wallet}"
COLD=0; VERIFY_DIR=""; RESTORE_DIR=""
NEED_START=0; IN_TMP=""

usage() {
  cat <<EOF
uso: $PROGRAM_NAME [--cold] | --verify <dir> | --restore <dir>
  (por defecto)  caliente: ecoind backupwallet → docker cp → sha256 contenedor == host
                 → devops/backups/client-wallet/<TS-UTC>/ (no versionado)
  --cold         stop $CONTAINER → copia wallet.dat → start (también si falla)
  --verify DIR   sha256sum -c de un backup existente (solo lectura)
  --restore DIR  aparta la cartera actual a wallet.dat.pre-restore-<TS> (NUNCA sobrescribe),
                 coloca la del backup, verifica sha256 y arranca
Variables: ECOIN_CONTAINER (default ecoin-wallet) · WALLET_BACKUP_ROOT
La cartera NO está cifrada: el backup es material de claves. Muévelo a almacenamiento cifrado.
Haz el backup ANTES de publicar la dirección y repítelo tras muchos envíos (keypool).
EOF
}

log()  { printf '[%s] %s\n' "$PROGRAM_NAME" "$*"; }
warn() { printf '[%s] AVISO: %s\n' "$PROGRAM_NAME" "$*" >&2; }
die()  { printf '[%s] ERROR: %s\n' "$PROGRAM_NAME" "$*" >&2; exit 1; }
need_cmd() { command -v "$1" >/dev/null 2>&1 || die "falta el comando: $1"; }
wpath() { cygpath -m "$1" 2>/dev/null || echo "$1"; }   # rutas de host para docker.exe bajo MSYS_NO_PATHCONV
sha()  { sha256sum "$1" | cut -c1-64; }

while (($#)); do
  case "$1" in
    --cold) COLD=1 ;;
    --verify)  shift; VERIFY_DIR="${1:-}";  [[ -n "$VERIFY_DIR"  ]] || { usage >&2; exit 2; } ;;
    --restore) shift; RESTORE_DIR="${1:-}"; [[ -n "$RESTORE_DIR" ]] || { usage >&2; exit 2; } ;;
    --help|-h) usage; exit 0 ;;
    *) printf '[%s] ERROR: opción desconocida: %s\n' "$PROGRAM_NAME" "$1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done
if [[ -n "$VERIFY_DIR" && -n "$RESTORE_DIR" ]] || { [[ "$COLD" == 1 ]] && [[ -n "$VERIFY_DIR$RESTORE_DIR" ]]; }; then
  usage >&2; exit 2
fi

need_cmd sha256sum

verify_dir() {  # verify_dir <dir> → deja en WALLET_FILE el nombre de la cartera del backup
  local d="$1" n
  [[ -d "$d" ]] || die "no existe el directorio: $d"
  [[ -f "$d/SHA256SUMS.txt" ]] || die "no hay SHA256SUMS.txt en $d"
  ( cd "$d" && tr -d '\r' < SHA256SUMS.txt | sha256sum -c --quiet - ) || die "verificación FALLIDA en $d"
  n="$(find "$d" -maxdepth 1 -type f -name 'wallet-*.dat' | wc -l | tr -d ' ')"
  [[ "$n" == 1 ]] || die "se esperaba exactamente un wallet-*.dat en $d (hay $n)"
  WALLET_FILE="$(basename "$(find "$d" -maxdepth 1 -type f -name 'wallet-*.dat')")"
  grep -q " [ *]\?$WALLET_FILE\$" <(tr -d '\r' < "$d/SHA256SUMS.txt") || die "$WALLET_FILE no figura en SHA256SUMS.txt"
  [[ -s "$d/$WALLET_FILE" ]] || die "$WALLET_FILE tiene tamaño 0"
}

# --- --verify: solo lectura, sin docker ---------------------------------------------
if [[ -n "$VERIFY_DIR" ]]; then
  verify_dir "${VERIFY_DIR%/}"
  log "OK: ${VERIFY_DIR%/} íntegro ($WALLET_FILE)"
  exit 0
fi

need_cmd docker
docker info >/dev/null 2>&1 || die "el demonio de docker no responde (¿Docker Desktop arrancado?)"

ctr_exists()  { docker inspect "$CONTAINER" >/dev/null 2>&1; }
is_running()  { [[ "$(docker inspect -f '{{.State.Running}}' "$CONTAINER" 2>/dev/null || true)" == "true" ]]; }
rpc()         { docker exec "$CONTAINER" ecoind "$@" 2>/dev/null | tr -d '\r'; }
json_or_null() { case "$1" in "{"*|"["*) printf '%s' "$1" ;; *) printf 'null' ;; esac; }
# helper <script-sh>: contenedor efímero con la MISMA imagen y los MISMOS volúmenes que $CONTAINER,
# sin red y sin ecoind; sirve con $CONTAINER parado. stdin se pasa tal cual.
helper() {
  docker run --rm -i --network none --volumes-from "$CONTAINER" --entrypoint sh "$IMAGE_ID" -c "$1"
}
wait_rpc() {  # hasta ~3 min
  local i
  for i in $(seq 1 60); do
    rpc getinfo 2>/dev/null | grep -q '"blocks"' && return 0
    is_running || return 1
    sleep 3
  done
  return 1
}

cleanup() {
  if [[ -n "$IN_TMP" ]]; then
    docker exec "$CONTAINER" rm -f -- "$IN_TMP" >/dev/null 2>&1 || true
  fi
  if [[ "$NEED_START" == 1 ]]; then
    warn "arrancando $CONTAINER tras un fallo a mitad de la operación"
    docker start "$CONTAINER" >/dev/null || warn "NO se pudo arrancar $CONTAINER: arráncalo a mano"
  fi
  return 0
}
trap cleanup EXIT

ctr_exists || die "no existe el contenedor $CONTAINER (npm run ecoin:up; para el drill: ECOIN_CONTAINER=ecoin-wallet-drill)"
IMAGE_ID="$(docker inspect -f '{{.Image}}' "$CONTAINER" | tr -d '\r')"
IMAGE="$(docker inspect -f '{{.Config.Image}}' "$CONTAINER" | tr -d '\r') $IMAGE_ID"
VOLUME="$(docker inspect -f "{{range .Mounts}}{{if eq .Destination \"$IN_DATADIR\"}}{{.Name}}{{end}}{{end}}" "$CONTAINER" | tr -d '\r')"
[[ -n "$VOLUME" ]] || die "$CONTAINER no monta un volumen nombrado en $IN_DATADIR: no es la cartera del cliente"

# El destino en el host no puede ser versionable.
case "$BACKUP_ROOT" in
  "$REPO_ROOT"/*)
    git -C "$REPO_ROOT" check-ignore -q "$BACKUP_ROOT/x" 2>/dev/null \
      || die "${BACKUP_ROOT#"$REPO_ROOT"/} NO está ignorado por git: no se escribe material de claves en una ruta versionable" ;;
esac

TS="$(date -u +%Y%m%dT%H%M%SZ)"

# =============================================================================== --restore
if [[ -n "$RESTORE_DIR" ]]; then
  RESTORE_DIR="${RESTORE_DIR%/}"
  verify_dir "$RESTORE_DIR"
  SRC="$RESTORE_DIR/$WALLET_FILE"
  WANT="$(sha "$SRC")"
  log "backup verificado: $SRC (sha256 ${WANT:0:16}…)"
  log "destino: volumen $VOLUME (contenedor $CONTAINER)"

  if is_running; then
    log "parando $CONTAINER (cierre limpio de BDB; respeta stop_grace_period)…"
    NEED_START=1   # si falla ANTES de tocar la cartera, el trap lo rearranca
    docker stop "$CONTAINER" >/dev/null
  fi
  # 1) la copia entra con nombre temporal y se verifica DENTRO del volumen; aún no se ha tocado nada.
  NEW="wallet.dat.restore-$TS.tmp"
  helper "umask 077; cat > '$IN_DATADIR/$NEW'" < "$SRC" || die "no se pudo copiar la cartera al volumen"
  GOT="$(helper "sha256sum '$IN_DATADIR/$NEW'" | tr -d '\r' | cut -c1-64)"
  if [[ "$GOT" != "$WANT" ]]; then
    helper "rm -f -- '$IN_DATADIR/$NEW'" || true
    die "sha256 dentro del volumen ($GOT) ≠ backup ($WANT): no se ha tocado la cartera actual"
  fi
  # 2) apartar la actual y colocar la nueva, en un solo paso; si el segundo mv falla se deshace.
  #    Desde aquí el trap ya NO rearranca solo: ecoind sin wallet.dat crearía una cartera nueva.
  NEED_START=0
  ASIDE="wallet.dat.pre-restore-$TS"
  helper "set -e; cd '$IN_DATADIR'
    [ ! -e '$ASIDE' ] || { echo 'ya existe $ASIDE' >&2; exit 1; }
    if [ -e wallet.dat ]; then mv -n wallet.dat '$ASIDE'; [ ! -e wallet.dat ] || exit 1; fi
    if ! mv -n '$NEW' wallet.dat; then [ ! -e '$ASIDE' ] || mv -n '$ASIDE' wallet.dat; exit 1; fi
    chmod 600 wallet.dat" \
    || die "no se pudo colocar la cartera; la anterior sigue en su sitio (o en $ASIDE). ecoind NO se arranca: revisa el volumen $VOLUME"
  GOT="$(helper "sha256sum '$IN_DATADIR/wallet.dat'" | tr -d '\r' | cut -c1-64)"
  [[ "$GOT" == "$WANT" ]] || die "wallet.dat restaurada NO coincide con el backup ($GOT): ecoind NO se arranca. La anterior está en $ASIDE"
  log "cartera restaurada (sha256 OK). La anterior, si la había, queda en el volumen como $ASIDE"

  log "arrancando $CONTAINER"
  docker start "$CONTAINER" >/dev/null || die "no se pudo arrancar $CONTAINER: arráncalo a mano"
  if wait_rpc; then
    echo
    log "RPC arriba. Direcciones de la cartera restaurada:"
    rpc getaddressesbyaccount '' || true
    echo
    log "comprueba que la dirección publicada en tu feed es tuya:"
    log "  docker exec $CONTAINER ecoind validateaddress <dirección>   # \"ismine\" : true"
    log "si el saldo no cuadra tras sincronizar: reiniciar ecoind con -rescan."
  else
    warn "el RPC no respondió en ~3 min: docker logs $CONTAINER"
  fi
  exit 0
fi

# =============================================================================== backup
RUNNING=0; is_running && RUNNING=1
if [[ "$COLD" == 0 && "$RUNNING" == 0 ]]; then
  die "$CONTAINER no está en marcha: el modo caliente necesita el RPC (npm run ecoin:up, o usa --cold)"
fi

GETINFO="null"; ADDRESSES="null"; BLOCKS="null"
if [[ "$RUNNING" == 1 ]]; then
  GETINFO="$(json_or_null "$(rpc getinfo || true)")"
  ADDRESSES="$(json_or_null "$(rpc getaddressesbyaccount '' || true)")"
  if [[ "$GETINFO" == "null" ]]; then
    warn "getinfo no respondió (¿RPC aún arrancando?); manifiesto sin estado de la cadena"
  else
    BLOCKS="$(printf '%s' "$GETINFO" | grep -o '"blocks" *: *[0-9]*' | grep -o '[0-9]*$' | head -n 1 || true)"
    BLOCKS="${BLOCKS:-null}"
  fi
fi

TARGET_DIR="$BACKUP_ROOT/$TS"
[[ ! -e "$TARGET_DIR" ]] || die "ya existe $TARGET_DIR"
mkdir -p "$TARGET_DIR"
chmod 700 "$TARGET_DIR" 2>/dev/null || true

if [[ "$COLD" == 1 ]]; then
  MODE="cold"
  WALLET_FILE="wallet-$TS.cold.dat"
  if [[ "$RUNNING" == 1 ]]; then
    log "parando $CONTAINER (cierre limpio de BDB; respeta stop_grace_period)…"
    NEED_START=1
    docker stop "$CONTAINER" >/dev/null
  else
    warn "$CONTAINER ya estaba parado: se copia wallet.dat y NO se arranca"
  fi
  IN_SRC="$IN_DATADIR/wallet.dat"
  IN_SHA="$(helper "sha256sum '$IN_SRC'" | tr -d '\r' | cut -c1-64)" || die "no existe wallet.dat en el volumen $VOLUME"
else
  MODE="hot"
  WALLET_FILE="wallet-$TS.dat"
  IN_SRC="$IN_DATADIR/backups/$WALLET_FILE"
  log "ecoind backupwallet → $IN_SRC"
  docker exec "$CONTAINER" sh -c "umask 077; mkdir -p '$IN_DATADIR/backups'" || die "no se pudo crear backups/ en el datadir"
  IN_TMP="$IN_SRC"
  docker exec "$CONTAINER" ecoind backupwallet "$IN_SRC" >/dev/null || die "backupwallet falló"
  IN_SHA="$(docker exec "$CONTAINER" sha256sum "$IN_SRC" | tr -d '\r' | cut -c1-64)"
fi
[[ "$IN_SHA" =~ ^[0-9a-f]{64}$ ]] || die "no se pudo calcular el sha256 en el contenedor"

log "docker cp $CONTAINER:$IN_SRC → host"
docker cp "$CONTAINER:$IN_SRC" "$(wpath "$TARGET_DIR/$WALLET_FILE")" >/dev/null || die "docker cp falló"
[[ -s "$TARGET_DIR/$WALLET_FILE" ]] || die "la copia llegó con tamaño 0"
HOST_SHA="$(sha "$TARGET_DIR/$WALLET_FILE")"
[[ "$HOST_SHA" == "$IN_SHA" ]] || die "sha256 no coincide: contenedor=$IN_SHA host=$HOST_SHA"
chmod 600 "$TARGET_DIR/$WALLET_FILE" 2>/dev/null || true

if [[ "$MODE" == hot ]]; then
  docker exec "$CONTAINER" rm -f -- "$IN_SRC" || warn "no se pudo borrar $IN_SRC del contenedor (bórralo a mano)"
  IN_TMP=""
elif [[ "$NEED_START" == 1 ]]; then
  log "arrancando $CONTAINER"
  docker start "$CONTAINER" >/dev/null || die "no se pudo arrancar $CONTAINER: arráncalo a mano YA"
  NEED_START=0
fi

# --- sumas, manifiesto, RESTORE ----------------------------------------------------------
( cd "$TARGET_DIR" && sha256sum "$WALLET_FILE" > SHA256SUMS.txt && sha256sum -c --quiet SHA256SUMS.txt ) || die "SHA256SUMS no verifica"
WALLET_BYTES="$(wc -c < "$TARGET_DIR/$WALLET_FILE" | tr -d ' ')"
OPERATOR="${USER:-${USERNAME:-$(id -un 2>/dev/null || printf 'unknown')}}"

cat > "$TARGET_DIR/MANIFEST.json" <<EOF
{
  "createdAtUtc": "$TS",
  "operator": "$OPERATOR",
  "role": "client-wallet",
  "mode": "$MODE",
  "container": "$CONTAINER",
  "volume": "$VOLUME",
  "image": "$IMAGE",
  "walletFile": "$WALLET_FILE",
  "walletBytes": $WALLET_BYTES,
  "walletSha256": "$HOST_SHA",
  "encrypted": false,
  "blocks": $BLOCKS,
  "getinfo": $GETINFO,
  "addresses": $ADDRESSES
}
EOF

cat > "$TARGET_DIR/RESTORE.txt" <<EOF
Cartera ECOin del cliente — backup
==================================

Creado (UTC): $TS
Origen:       contenedor $CONTAINER · volumen docker $VOLUME
Modo:         $MODE
Fichero:      $WALLET_FILE ($WALLET_BYTES bytes)
sha256:       $HOST_SHA

Comprobar la copia:
  bash client/scripts/backup-wallet.sh --verify <este directorio>

Restaurar (NUNCA se borra ni se pisa la wallet.dat actual: se aparta dentro del volumen):
  npm run ecoin:up                                   # el contenedor tiene que existir
  bash client/scripts/backup-wallet.sh --restore <este directorio>
  docker exec $CONTAINER ecoind validateaddress <dirección publicada>   # "ismine" : true

A mano, si el script no está disponible:
  docker stop $CONTAINER
  docker run --rm --network none --volumes-from $CONTAINER --entrypoint sh <imagen> -c \\
    'cd /home/ecoin/.ecoin && mv -n wallet.dat wallet.dat.pre-restore-\$(date -u +%Y%m%dT%H%M%SZ)'
  docker cp $WALLET_FILE $CONTAINER:/home/ecoin/.ecoin/wallet.dat
  docker run --rm --network none --user 0 --volumes-from $CONTAINER --entrypoint sh <imagen> -c \\
    'chown 1000:1000 /home/ecoin/.ecoin/wallet.dat && chmod 600 /home/ecoin/.ecoin/wallet.dat'
  docker start $CONTAINER

Nota de seguridad:
  La cartera NO está cifrada: este fichero es material de claves en claro. Quien lo tenga, gasta.
  Git lo ignora, pero sigue siendo un secreto: muévelo a almacenamiento cifrado FUERA de la máquina
  (el volumen docker se pierde con un factory reset de Docker Desktop / WSL2).
  El keypool rota: repite el backup tras muchos envíos o direcciones nuevas.
EOF
chmod 600 "$TARGET_DIR"/* 2>/dev/null || true

echo
log "backup completo ($MODE)"
printf '  Carpeta:   %s\n' "${TARGET_DIR#"$REPO_ROOT"/}"
printf '  Cartera:   %s (%s bytes)\n' "$WALLET_FILE" "$WALLET_BYTES"
printf '  sha256:    %s (contenedor == host)\n' "$HOST_SHA"
printf '  blocks:    %s\n' "$BLOCKS"
echo
warn "la cartera NO está cifrada: este backup es material de claves en claro."
warn "git lo ignora, pero sigue siendo un secreto: cópialo a almacenamiento cifrado fuera de la máquina."
warn "el keypool rota con los envíos: repite el backup tras muchos envíos y SIEMPRE antes de publicar una dirección."
