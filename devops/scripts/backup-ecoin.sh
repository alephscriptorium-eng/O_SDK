#!/usr/bin/env bash
# =============================================================================
# backup-ecoin.sh — copia de seguridad de la cartera ECOin del hub-wallet
# (`oasis-pub-ecoin`, datadir /srv/oasis/ecoin, wallet.dat uid 1000 / 600).
#
# wallet.dat ES el dinero: quien la tiene, gasta. La cartera NO está cifrada
# (sin `encryptwallet`: el motor de RBU del wallet-bot no puede desbloquearla),
# así que cada backup es material de claves en claro. Cartera caliente, saldo
# pequeño, y el backup a almacenamiento cifrado fuera de la máquina.
# Doc viva: docs/PUB/ECOIN-PROTOCOL.md (cartera/backup, rollback).
#
# Uso:
#   bash devops/scripts/backup-ecoin.sh [--local] [--cold]
#   bash devops/scripts/backup-ecoin.sh --verify <dir>
#
# Modos:
#   (por defecto)   CALIENTE. `ecoind backupwallet` dentro del contenedor →
#                   <datadir>/backups/wallet-<TS>.dat → se trae por ssh
#                   (sudo cat) → sha256 remoto == local o aborta → aborta si
#                   tamaño 0 → conserva solo las 3 copias remotas más recientes
#                   DENTRO de <datadir>/backups/. ecoind no se para.
#   --cold          FRÍO. docker stop (respeta stop_grace_period: cierre limpio
#                   de BDB) → copia wallet.dat → docker start (también si la
#                   copia falla). Para el rollback N2 y antes de un upgrade.
#   --verify <dir>  sha256sum -c del SHA256SUMS.txt de un backup ya hecho.
#                   Solo lectura, sin SSH.
#   --local         mismo flujo contra el contenedor local y
#                   ${OASIS_ECOIN_LOCAL_DIR:-<repo>/volumes-dev/ecoin}, sin ssh
#                   ni sudo (gate G5).
#
# Destino: devops/backups/ecoin/<TS-UTC>/ (700; ignorado por git) con
#   wallet-<TS>.dat (600) · SHA256SUMS.txt · BACKUP_METADATA.json (getinfo:
#   blocks/connections/balance, direcciones de la cuenta "", imagen) · RESTORE.txt
#
# Guardas: datadir vacío, "/", "/srv" o "/srv/oasis" → se rechaza. Ningún rm
# fuera de <datadir>/backups/. NUNCA se borra ni se pisa wallet.dat: restaurar
# = apartar la actual a wallet.dat.bak-<fecha> (ver RESTORE.txt).
#
# Instancia: lib-host.sh (DEVOPS_HOST → devops/hosts/<nombre>/host.env:
# REMOTE_USER, REMOTE_HOST, KEY_FILE/KEY_PATH). Variables opcionales:
#   ECOIN_DATA          datadir remoto de ecoind (default /srv/oasis/ecoin)
#   ECOIN_CONTAINER     contenedor (default oasis-pub-ecoin)
#   LOCAL_BACKUP_ROOT   destino local (default devops/backups/ecoin)
#   ECOIN_BACKUP_KEEP   copias remotas a conservar en backups/ (default 3)
# =============================================================================
set -euo pipefail
umask 077
export MSYS_NO_PATHCONV=1

PROGRAM_NAME="$(basename "$0")"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Datos de instancia → devops/hosts/<DEVOPS_HOST>/host.env
# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib-host.sh"
REPO_ROOT="$(cd "$DEVOPS_DIR/.." && pwd)"

CONTAINER="${ECOIN_CONTAINER:-oasis-pub-ecoin}"
IN_DATADIR="/home/ecoin/.ecoin"          # datadir visto desde dentro del contenedor
LOCAL_BACKUP_ROOT="${LOCAL_BACKUP_ROOT:-$DEVOPS_DIR/backups/ecoin}"
KEEP="${ECOIN_BACKUP_KEEP:-3}"
LOCAL=0
COLD=0
VERIFY_DIR=""
TMP_WORK=""
NEED_START=0

usage() {
  cat <<EOF
uso: $PROGRAM_NAME [--local] [--cold] | --verify <dir>
  (por defecto)  caliente: ecoind backupwallet → devops/backups/ecoin/<TS-UTC>/ (sha256 remoto == local)
  --cold         stop $CONTAINER → copia wallet.dat → start
  --verify DIR   sha256sum -c de un backup existente
  --local        contra el contenedor local y \${OASIS_ECOIN_LOCAL_DIR:-<repo>/volumes-dev/ecoin} (sin ssh)
La cartera NO está cifrada: el backup es material de claves. Muévelo a almacenamiento cifrado.
EOF
}

log()  { printf '[%s] %s\n' "$PROGRAM_NAME" "$*"; }
warn() { printf '[%s] AVISO: %s\n' "$PROGRAM_NAME" "$*" >&2; }
die()  { printf '[%s] ERROR: %s\n' "$PROGRAM_NAME" "$*" >&2; exit 1; }
need_cmd() { command -v "$1" >/dev/null 2>&1 || die "falta el comando: $1"; }

while (($#)); do
  case "$1" in
    --local) LOCAL=1 ;;
    --cold)  COLD=1 ;;
    --verify) shift; VERIFY_DIR="${1:-}"; [[ -n "$VERIFY_DIR" ]] || die "--verify necesita un directorio" ;;
    --help|-h) usage; exit 0 ;;
    *) die "opción desconocida: $1 (--help)" ;;
  esac
  shift
done

need_cmd sha256sum

# --- --verify: solo lectura, sin host -----------------------------------------
if [[ -n "$VERIFY_DIR" ]]; then
  [[ -f "$VERIFY_DIR/SHA256SUMS.txt" ]] || die "no hay SHA256SUMS.txt en $VERIFY_DIR"
  ( cd "$VERIFY_DIR" && sha256sum -c SHA256SUMS.txt ) || die "verificación FALLIDA en $VERIFY_DIR"
  log "OK: $VERIFY_DIR íntegro"
  exit 0
fi

# --- dónde se ejecuta ------------------------------------------------------------
cleanup() {
  # Si --cold paró el contenedor y algo falló antes del start, se arranca igual.
  if [[ "$NEED_START" == 1 ]]; then
    warn "arrancando $CONTAINER tras un fallo a mitad de --cold"
    rsh "docker start '$CONTAINER'" >/dev/null || warn "NO se pudo arrancar $CONTAINER: arráncalo a mano"
  fi
  [[ -n "$TMP_WORK" ]] && rm -rf "$TMP_WORK"
  return 0
}
trap cleanup EXIT

if [[ "$LOCAL" == 1 ]]; then
  DATADIR="${OASIS_ECOIN_LOCAL_DIR:-$REPO_ROOT/volumes-dev/ecoin}"
  SUDO=""
  WHERE="local"
  need_cmd docker
else
  DATADIR="${ECOIN_DATA:-/srv/oasis/ecoin}"
  SUDO="sudo -n"
  need_cmd ssh
  KEY_PATH="${KEY_PATH:-}"
  REMOTE_USER="${REMOTE_USER:-}"
  REMOTE_HOST="${REMOTE_HOST:-}"
  [[ -n "$REMOTE_USER" && -n "$REMOTE_HOST" ]] || die "REMOTE_USER/REMOTE_HOST vacíos (¿DEVOPS_HOST / host.env?)"
  [[ -f "$KEY_PATH" ]] || die "clave SSH no encontrada: $KEY_PATH"
  # La clave en /mnt/c aparece 0777 en WSL y ssh la rechaza: copia efímera 600.
  key_mode="$(stat -c '%a' "$KEY_PATH" 2>/dev/null || echo 600)"
  if [[ "$key_mode" != "600" && "$key_mode" != "400" ]]; then
    TMP_WORK="$(mktemp -d)"
    cat "$KEY_PATH" > "$TMP_WORK/key"
    chmod 600 "$TMP_WORK/key"
    KEY_PATH="$TMP_WORK/key"
  fi
  SSH_OPTS=(-i "$KEY_PATH" -o StrictHostKeyChecking=accept-new -o BatchMode=yes -o ConnectTimeout=15)
  WHERE="$REMOTE_USER@$REMOTE_HOST"
fi

# Guardas del datadir: con nombre, nunca una raíz compartida.
DATADIR="${DATADIR%/}"
case "$DATADIR" in
  ""|"/"|"/srv"|"/srv/oasis") die "datadir inválido: '$DATADIR'" ;;
esac
[[ "$DATADIR" != *"'"* ]] || die "datadir con comilla simple: '$DATADIR'"
[[ "$KEEP" =~ ^[1-9][0-9]*$ ]] || die "ECOIN_BACKUP_KEEP debe ser un entero ≥ 1"

# rsh <cmd>: ejecuta una línea de shell en el host del contenedor (local o VPS).
rsh() {
  if [[ "$LOCAL" == 1 ]]; then bash -c "$1"; else ssh "${SSH_OPTS[@]}" "$REMOTE_USER@$REMOTE_HOST" "$1"; fi
}
# fetch <ruta-en-host> <destino-local>: trae un fichero y exige sha256 igual.
fetch() {
  local src="$1" dst="$2" rh lh
  rsh "$SUDO cat '$src'" > "$dst"
  [[ -s "$dst" ]] || die "la copia llegó con tamaño 0: $src"
  rh="$(rsh "$SUDO sha256sum '$src'" | awk '{print $1}')"
  lh="$(sha256sum "$dst" | awk '{print $1}')"
  [[ -n "$rh" && "$rh" == "$lh" ]] || die "sha256 no coincide ($src): origen=$rh local=$lh"
  chmod 600 "$dst" 2>/dev/null || true
}
is_running() { [[ "$(rsh "docker inspect -f '{{.State.Running}}' '$CONTAINER' 2>/dev/null" || true)" == "true" ]]; }
rpc() { rsh "docker exec '$CONTAINER' ecoind $1" 2>/dev/null | tr -d '\r'; }
# json_or_null <texto>: deja pasar solo lo que parece JSON ({…} o […]).
json_or_null() { case "$1" in "{"*|"["*) printf '%s' "$1" ;; *) printf 'null' ;; esac; }

# --- estado y metadatos (antes de parar nada) --------------------------------------
RUNNING=0; is_running && RUNNING=1
if [[ "$COLD" == 0 && "$RUNNING" == 0 ]]; then
  die "$CONTAINER no está en marcha en $WHERE: el modo caliente necesita el RPC (o usa --cold)"
fi
rsh "$SUDO test -f '$DATADIR/wallet.dat'" || die "no existe $DATADIR/wallet.dat en $WHERE"

GETINFO="null"; ADDRESSES="null"; IMAGE="unknown"
if [[ "$RUNNING" == 1 ]]; then
  GETINFO="$(json_or_null "$(rpc getinfo || true)")"
  ADDRESSES="$(json_or_null "$(rpc 'getaddressesbyaccount ""' || true)")"
  [[ "$GETINFO" != "null" ]] || warn "getinfo no respondió (¿RPC aún arrancando?); metadatos sin estado de la cadena"
fi
IMAGE="$(rsh "docker inspect -f '{{.Config.Image}} {{.Image}}' '$CONTAINER' 2>/dev/null" | tr -d '\r' || true)"
IMAGE="${IMAGE:-unknown}"

TS="$(date -u +%Y%m%dT%H%M%SZ)"
TARGET_DIR="$LOCAL_BACKUP_ROOT/$TS"
mkdir -p "$TARGET_DIR"
chmod 700 "$TARGET_DIR" 2>/dev/null || true

# --- copia ---------------------------------------------------------------------
if [[ "$COLD" == 1 ]]; then
  MODE="cold"
  WALLET_FILE="wallet-$TS.cold.dat"
  if [[ "$RUNNING" == 1 ]]; then
    log "parando $CONTAINER (cierre limpio de BDB; respeta stop_grace_period)…"
    NEED_START=1
    rsh "docker stop '$CONTAINER'" >/dev/null
  else
    warn "$CONTAINER ya estaba parado: se copia wallet.dat y NO se arranca"
  fi
  log "copiando $DATADIR/wallet.dat"
  fetch "$DATADIR/wallet.dat" "$TARGET_DIR/$WALLET_FILE"
  if [[ "$NEED_START" == 1 ]]; then
    log "arrancando $CONTAINER"
    rsh "docker start '$CONTAINER'" >/dev/null || die "no se pudo arrancar $CONTAINER: arráncalo a mano YA"
    NEED_START=0
  fi
else
  MODE="hot"
  WALLET_FILE="wallet-$TS.dat"
  log "ecoind backupwallet → $DATADIR/backups/$WALLET_FILE"
  rsh "docker exec '$CONTAINER' sh -c 'umask 077; mkdir -p $IN_DATADIR/backups'" || die "no se pudo crear backups/ en el datadir"
  rsh "docker exec '$CONTAINER' ecoind backupwallet '$IN_DATADIR/backups/$WALLET_FILE'" || die "backupwallet falló"
  fetch "$DATADIR/backups/$WALLET_FILE" "$TARGET_DIR/$WALLET_FILE"
  # Retención: solo dentro de backups/ (cd o nada), solo wallet-*.dat, las $KEEP más recientes se quedan.
  rsh "docker exec '$CONTAINER' sh -c 'cd $IN_DATADIR/backups || exit 1; ls -1 wallet-*.dat 2>/dev/null | sort -r | tail -n +$((KEEP + 1)) | while read -r f; do rm -f -- \"\$f\"; done'" \
    || warn "no se pudo aplicar la retención en $DATADIR/backups (revísalo a mano)"
fi

# --- sumas, metadatos, RESTORE ---------------------------------------------------
( cd "$TARGET_DIR" && sha256sum "$WALLET_FILE" > SHA256SUMS.txt && sha256sum -c --quiet SHA256SUMS.txt ) || die "SHA256SUMS no verifica"
WALLET_BYTES="$(wc -c < "$TARGET_DIR/$WALLET_FILE" | tr -d ' ')"
WALLET_SHA="$(awk '{print $1}' "$TARGET_DIR/SHA256SUMS.txt")"
OPERATOR="${USER:-${USERNAME:-$(id -un 2>/dev/null || printf 'unknown')}}"

cat > "$TARGET_DIR/BACKUP_METADATA.json" <<EOF
{
  "createdAtUtc": "$TS",
  "operator": "$OPERATOR",
  "where": "$WHERE",
  "mode": "$MODE",
  "container": "$CONTAINER",
  "image": "$IMAGE",
  "datadir": "$DATADIR",
  "walletFile": "$WALLET_FILE",
  "walletBytes": $WALLET_BYTES,
  "walletSha256": "$WALLET_SHA",
  "encrypted": false,
  "getinfo": $GETINFO,
  "addresses": $ADDRESSES
}
EOF

cat > "$TARGET_DIR/RESTORE.txt" <<EOF
Cartera ECOin del hub-wallet — backup
=====================================

Creado (UTC): $TS
Origen:       $WHERE · $CONTAINER · $DATADIR
Modo:         $MODE
Fichero:      $WALLET_FILE ($WALLET_BYTES bytes)
sha256:       $WALLET_SHA

Antes de nada, comprueba la copia:
  bash devops/scripts/backup-ecoin.sh --verify <este directorio>

Restaurar (en el host del contenedor; NUNCA se borra la wallet.dat actual):
  1. Parar ecoind (cierre limpio de BDB):
       docker stop $CONTAINER
  2. Apartar la cartera actual, sin borrarla:
       sudo mv $DATADIR/wallet.dat $DATADIR/wallet.dat.bak-\$(date -u +%Y%m%dT%H%M%SZ)
  3. Subir $WALLET_FILE al host y copiarla en su sitio con dueño y permisos:
       sudo install -o 1000 -g 1000 -m 600 $WALLET_FILE $DATADIR/wallet.dat
     (equivale a: cp + chown 1000:1000 + chmod 600)
  4. Arrancar:
       docker start $CONTAINER
  5. Verificar saldo y dirección (la dirección publicada debe seguir siendo tuya):
       docker exec $CONTAINER ecoind getbalance
       docker exec $CONTAINER ecoind getaddressesbyaccount ""
       docker exec $CONTAINER ecoind validateaddress <dirección>   # ismine: true
     Si el saldo no cuadra tras sincronizar: reiniciar ecoind con -rescan.

Nota de seguridad:
  La cartera NO está cifrada (el motor de RBU no puede desbloquearla), así que
  este fichero es material de claves en claro: quien lo tenga, gasta.
  Muévelo a almacenamiento cifrado fuera de la máquina cuanto antes.
EOF
chmod 600 "$TARGET_DIR"/* 2>/dev/null || true

echo
log "backup completo ($MODE)"
printf '  Carpeta local: %s\n' "$TARGET_DIR"
printf '  Cartera:       %s (%s bytes)\n' "$WALLET_FILE" "$WALLET_BYTES"
printf '  sha256:        %s\n' "$WALLET_SHA"
echo
warn "la cartera NO está cifrada (el motor de RBU no puede desbloquearla): este backup es material de claves."
warn "git lo ignora, pero sigue siendo un secreto: muévelo a almacenamiento cifrado cuanto antes."
