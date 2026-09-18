#!/usr/bin/env bash
# =============================================================================
# ecoin-disk.sh — control de disco, cartera y memoria del hub-wallet del pub
# (`oasis-pub-ecoin` = ecoind 0.0.4 · `oasis-pub-wallet-bot` = bot-2).
#
# Hermano de hub-disk.sh (mismo patrón run_h / --local / --json). El hub-wallet
# guarda su estado bajo /srv/oasis/ecoin (datadir de ecoind: cadena + wallet.dat)
# y /srv/oasis/oasis-wallet-bot/{ssb-data,logs,banking,config}.
# Estrictamente READ-ONLY: NO tiene subcomando prune. ecoind 0.7 no sabe podar
# la cadena (no hay -prune): si la cadena aprieta, la salida es más disco o un
# resync desde bootstrap.dat, nunca borrar blk*.dat a mano. La cartera se copia
# con backup-ecoin.sh, no desde aquí.
# Doc viva: docs/PUB/ECOIN-PROTOCOL.md (disco, memoria, cartera).
#
# Uso:
#   bash devops/scripts/ecoin-disk.sh [--local] <subcomando> [--json]
#
# Subcomandos:
#   status        df -h de / y /srv/oasis · du de blk*.dat, blkindex.dat,
#                 database/ y total del datadir · wallet.dat (presencia, tamaño,
#                 permisos, owner) · getinfo (blocks, connections, balance) ·
#                 du del flume y de banking/ del wallet-bot · docker stats de
#                 oasis-pub-ecoin y oasis-pub-wallet-bot.   [read-only]
#   check         umbrales ECOIN_DISK_SOFT_PCT (75) / ECOIN_DISK_HARD_PCT (90)
#                 sobre /srv/oasis Y / + FAIL si wallet.dat existe y no es 600
#                 → exit 0 ok · 1 soft · 2 hard o FAIL · 3 no se pudo medir.
#                 Si wallet.dat aún no existe lo dice y no falla.
#                 [read-only; deploy-status.sh y cron]
#   --json        una línea JSON para el journal (devops/logs/ecoin-disk.jsonl):
#                 {ts, srvOasisPct, rootPct, ecoinChainBytes, walletDatBytes,
#                  blocks, connections, balance, botFlumeBytes, ecoinMemMiB,
#                  botMemMiB}. También `status --json`. Lo que no se puede
#                 medir (contenedor parado) sale como null.
#
# Flag global:
#   --local       en vez de SSH al VPS ejecuta los mismos comandos en local
#                 contra ECOIN_DATA=${OASIS_ECOIN_LOCAL_DIR:-<repo>/volumes-dev/ecoin}
#                 y BOT_DATA=${OASIS_WALLET_BOT_LOCAL_DIR:-<repo>/volumes-dev/oasis-wallet-bot}
#                 (gates locales, sin VPS). Si los directorios o los contenedores
#                 no existen avisa, no falla. En --local los permisos de
#                 wallet.dat solo generan AVISO (NTFS/Git Bash no expresa 600).
#
# Cadencia (como hub-disk): `--json` en el cierre del deploy (línea base), a
# las 24 h, a los 7 días y después SEMANAL; `check` en cada deploy-status.
#
# Instancia: lib-host.sh (DEVOPS_HOST → devops/hosts/<nombre>/host.env:
# REMOTE_USER, REMOTE_HOST, KEY_FILE/KEY_PATH). Variables opcionales:
#   ECOIN_DATA          datadir de ecoind (default /srv/oasis/ecoin)
#   ECOIN_BOT_DATA      estado del wallet-bot (default /srv/oasis/oasis-wallet-bot)
#   ECOIN_DATA_MOUNT    punto de montaje del volumen de datos (default /srv/oasis)
#   ECOIN_DISK_SOFT_PCT / ECOIN_DISK_HARD_PCT   umbrales de check (75 / 90)
# =============================================================================
set -uo pipefail
export MSYS_NO_PATHCONV=1

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Datos de instancia → devops/hosts/<DEVOPS_HOST>/host.env
# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib-host.sh"
REPO_ROOT="$(cd "$DEVOPS_DIR/.." && pwd)"

SOFT="${ECOIN_DISK_SOFT_PCT:-75}"
HARD="${ECOIN_DISK_HARD_PCT:-90}"

usage() {
  cat <<EOF
uso: ecoin-disk.sh [--local] status [--json] | check | --json
  --local   ejecuta en local contra \${OASIS_ECOIN_LOCAL_DIR:-<repo>/volumes-dev/ecoin} (sin SSH)
  check     exit 0 ok · 1 ≥ ECOIN_DISK_SOFT_PCT ($SOFT) · 2 ≥ ECOIN_DISK_HARD_PCT ($HARD) o wallet.dat ≠ 600 · 3 sin medida
  (sin prune: ecoind 0.7 no poda la cadena)
EOF
}

# ---------------------------------------------------------------------------
# Flags globales y subcomando
# ---------------------------------------------------------------------------
LOCAL=0
JSON=0
CMD=""
while [ $# -gt 0 ]; do
  case "$1" in
    --local) LOCAL=1 ;;
    --json)  JSON=1 ;;
    -h|--help) usage; exit 0 ;;
    *) if [ -z "$CMD" ]; then CMD="$1"; else echo "ERROR: argumento inesperado: $1" >&2; usage; exit 2; fi ;;
  esac
  shift
done
if [ -z "$CMD" ]; then
  if [ "$JSON" = 1 ]; then CMD="json"; else CMD="status"; fi
elif [ "$CMD" = "status" ] && [ "$JSON" = 1 ]; then
  CMD="json"
fi

# ---------------------------------------------------------------------------
# Dónde se ejecuta: local (--local) o VPS por SSH (lib-host.sh)
# ---------------------------------------------------------------------------
TMP_WORK=""
cleanup() { [ -n "$TMP_WORK" ] && rm -rf "$TMP_WORK"; }
trap cleanup EXIT

if [ "$LOCAL" = 1 ]; then
  ECOIN_DATA="${OASIS_ECOIN_LOCAL_DIR:-$REPO_ROOT/volumes-dev/ecoin}"
  BOT_DATA="${OASIS_WALLET_BOT_LOCAL_DIR:-$REPO_ROOT/volumes-dev/oasis-wallet-bot}"
  DATA_MOUNT="${ECOIN_DATA_MOUNT:-$REPO_ROOT}"
  ROOT_MOUNT="$REPO_ROOT"
  SUDO=""
  WHERE="local"
  if [ ! -d "$ECOIN_DATA" ]; then
    echo "AVISO: $ECOIN_DATA no existe todavía (el ecoin local aún no ha arrancado); los du saldrán a 0." >&2
  fi
else
  ECOIN_DATA="${ECOIN_DATA:-/srv/oasis/ecoin}"
  BOT_DATA="${ECOIN_BOT_DATA:-/srv/oasis/oasis-wallet-bot}"
  DATA_MOUNT="${ECOIN_DATA_MOUNT:-/srv/oasis}"
  ROOT_MOUNT="/"
  SUDO="sudo -n"
  KEY_PATH="${KEY_PATH:-}"
  REMOTE_USER="${REMOTE_USER:-}"
  REMOTE_HOST="${REMOTE_HOST:-}"
  WHERE="$REMOTE_USER@$REMOTE_HOST"
  [ -n "$REMOTE_USER" ] && [ -n "$REMOTE_HOST" ] || { echo "ERROR: REMOTE_USER/REMOTE_HOST vacíos (¿DEVOPS_HOST / host.env?)" >&2; exit 3; }
  [ -f "$KEY_PATH" ] || { echo "ERROR: clave SSH no encontrada: $KEY_PATH" >&2; exit 3; }
  # La clave en /mnt/c aparece 0777 en WSL y ssh la rechaza: copia efímera 600.
  key_mode="$(stat -c '%a' "$KEY_PATH" 2>/dev/null || echo 600)"
  if [ "$key_mode" != "600" ] && [ "$key_mode" != "400" ]; then
    TMP_WORK="$(mktemp -d)"
    cat "$KEY_PATH" > "$TMP_WORK/key"
    chmod 600 "$TMP_WORK/key"
    KEY_PATH="$TMP_WORK/key"
  fi
  SSH_OPTS="-i $KEY_PATH -o StrictHostKeyChecking=accept-new -o BatchMode=yes -o ConnectTimeout=15"
fi

# Guardas: el script solo lee, pero un datadir sin nombre es un error de config.
ECOIN_DATA="${ECOIN_DATA%/}"
case "$ECOIN_DATA" in
  ""|"/"|"/srv"|"/srv/oasis") echo "ERROR: ECOIN_DATA inválido: '$ECOIN_DATA'" >&2; exit 3 ;;
esac

# run_h <cuerpo>: ejecuta el cuerpo con `bash -s` en local o en el VPS. El
# cuerpo se escribe con comillas simples ('EOF') y recibe las variables por el
# preludio: idéntico en ambos modos → lo que se prueba en local es lo que corre.
run_h() {
  local prelude body
  prelude="$(printf 'set -uo pipefail\nexport MSYS_NO_PATHCONV=1\nECOIN_DATA=%q; BOT_DATA=%q; DATA_MOUNT=%q; ROOT_MOUNT=%q; SUDO=%q; LOCAL=%q\n' \
    "$ECOIN_DATA" "$BOT_DATA" "$DATA_MOUNT" "$ROOT_MOUNT" "$SUDO" "$LOCAL")"
  body="$prelude
$COMMON_FN
$1"
  if [ "$LOCAL" = 1 ]; then
    printf '%s\n' "$body" | bash -s
  else
    # shellcheck disable=SC2086
    printf '%s\n' "$body" | ssh $SSH_OPTS "$REMOTE_USER@$REMOTE_HOST" bash -s
  fi
}

# Funciones compartidas por todos los cuerpos (se envían junto al preludio).
# shellcheck disable=SC2016
COMMON_FN='
EC=oasis-pub-ecoin
BOT=oasis-pub-wallet-bot
pct(){ df -P "$1" 2>/dev/null | awk '"'"'NR==2{gsub("%","",$5); print $5}'"'"'; }
bytes(){ if $SUDO test -e "$1" 2>/dev/null; then $SUDO du -sb "$1" 2>/dev/null | cut -f1; else echo 0; fi; }
# cadena = blk*.dat + blkindex.dat + database/ (el glob lo expande quien puede leer el datadir 700)
chain_bytes(){ v="$($SUDO sh -c '"'"'du -cb "$0"/blk*.dat "$0"/blkindex.dat "$0"/database 2>/dev/null | tail -n 1 | cut -f1'"'"' "$ECOIN_DATA" 2>/dev/null)"; echo "${v:-0}"; }
wallet_stat(){ $SUDO stat -c "%a %u %s" "$ECOIN_DATA/wallet.dat" 2>/dev/null || true; }
running(){ docker ps --format "{{.Names}}" 2>/dev/null | grep -qx "$1"; }
getinfo(){ if running "$EC"; then docker exec "$EC" ecoind getinfo 2>/dev/null | tr -d "\r"; fi; }
# jf <campo>: valor escalar de una línea "campo" : valor del JSON de getinfo
jf(){ sed -n "s/^[[:space:]]*\"$1\"[[:space:]]*:[[:space:]]*\([^,]*\),\{0,1\}[[:space:]]*\$/\1/p" | head -n 1; }
num(){ case "$1" in ""|*[!0-9.-]*) echo null ;; *) echo "$1" ;; esac; }
mem_mib(){ docker stats --no-stream --format "{{.MemUsage}}" "$1" 2>/dev/null | awk '"'"'{v=$1; u=v; gsub(/[0-9.]/,"",u); sub(/[A-Za-z]+$/,"",v); m=v; if(u=="GiB")m=v*1024; else if(u=="KiB")m=v/1024; else if(u=="B")m=v/1048576; else if(u=="GB")m=v*953.674; else if(u=="kB")m=v/1048.576; else if(u=="MB")m=v/1.048576; printf "%d\n", m}'"'"'; }
'

# ---------------------------------------------------------------------------
# Subcomandos
# ---------------------------------------------------------------------------
case "$CMD" in
  status)
    echo "=== ECOIN DISK · $WHERE · ECOIN_DATA=$ECOIN_DATA ==="
    run_h "$(cat <<'EOF'
echo "-- df --"
df -h "$ROOT_MOUNT" "$DATA_MOUNT" 2>/dev/null | awk 'NR==1 || !seen[$0]++'
echo
echo "-- cadena (du; ecoind 0.7 no poda) --"
if $SUDO test -d "$ECOIN_DATA" 2>/dev/null; then
  $SUDO sh -c 'du -ch "$0"/blk*.dat 2>/dev/null | tail -n 1 | sed "s/total\$/blk*.dat/"' "$ECOIN_DATA"
  for d in "$ECOIN_DATA/blkindex.dat" "$ECOIN_DATA/database" "$ECOIN_DATA"; do
    if $SUDO test -e "$d" 2>/dev/null; then $SUDO du -sh "$d" 2>/dev/null || echo "?	$d"; else echo "0	$d (no existe)"; fi
  done
  echo "cadena (blk*.dat + blkindex.dat + database/) = $(chain_bytes) bytes"
else
  echo "0	$ECOIN_DATA (no existe)"
fi
echo
echo "-- wallet.dat --"
ws="$(wallet_stat)"
if [ -n "$ws" ]; then
  set -- $ws
  echo "presente · permisos=$1 · owner uid=$2 · $3 bytes"
  [ "$1" = "600" ] || echo "AVISO: wallet.dat debería ser 600 (uid 1000)"
else
  echo "(wallet.dat no existe en $ECOIN_DATA — ecoind la crea en el primer arranque)"
fi
echo
echo "-- getinfo --"
gi="$(getinfo)"
if [ -n "$gi" ]; then
  echo "blocks=$(printf '%s\n' "$gi" | jf blocks) connections=$(printf '%s\n' "$gi" | jf connections) balance=$(printf '%s\n' "$gi" | jf balance)"
else
  echo "(oasis-pub-ecoin no está en marcha o el RPC aún no responde)"
fi
echo
echo "-- wallet-bot (du) --"
for d in "$BOT_DATA/ssb-data/flume" "$BOT_DATA/banking" "$BOT_DATA/logs"; do
  if $SUDO test -d "$d" 2>/dev/null; then $SUDO du -sh "$d" 2>/dev/null || echo "?	$d"; else echo "0	$d (no existe)"; fi
done
echo
echo "-- docker stats --"
cs=""
for c in "$EC" "$BOT"; do if running "$c"; then cs="$cs $c"; fi; done
if [ -n "$cs" ]; then
  # shellcheck disable=SC2086
  docker stats --no-stream --format 'table {{.Name}}\t{{.MemUsage}}\t{{.CPUPerc}}' $cs 2>/dev/null || echo "(docker stats falló)"
else
  echo "(ni oasis-pub-ecoin ni oasis-pub-wallet-bot están en marcha)"
fi
EOF
)"
    ;;

  check)
    out="$(run_h "$(cat <<'EOF'
ws="$(wallet_stat)"
echo "$(pct "$DATA_MOUNT") $(pct "$ROOT_MOUNT") ${ws%% *}"
EOF
)")"
    # shellcheck disable=SC2086
    set -- $out
    p="${1:-}"; r="${2:-}"; wmode="${3:-}"
    if [ -z "$p" ] || [ -z "$r" ] || ! [ "$p" -ge 0 ] 2>/dev/null || ! [ "$r" -ge 0 ] 2>/dev/null; then
      echo "ecoin-disk check: no se pudo medir ($WHERE)"
      exit 3
    fi
    m=$(( p > r ? p : r ))
    verdict="OK"
    [ "$m" -ge "$SOFT" ] && verdict="SOFT"
    [ "$m" -ge "$HARD" ] && verdict="HARD"
    wnote="wallet.dat=$wmode"
    if [ -z "$wmode" ]; then
      wnote="wallet.dat ausente"
    elif [ "$wmode" != "600" ]; then
      if [ "$LOCAL" = 1 ]; then
        wnote="wallet.dat=$wmode (AVISO: no es 600; en --local no cuenta)"
      else
        wnote="wallet.dat=$wmode (debe ser 600)"
        verdict="FAIL"
      fi
    fi
    echo "ecoin-disk check: uso $DATA_MOUNT=$p% $ROOT_MOUNT=$r% (soft $SOFT / hard $HARD) · $wnote → $verdict"
    case "$verdict" in HARD|FAIL) exit 2 ;; SOFT) exit 1 ;; *) exit 0 ;; esac
    ;;

  json)
    run_h "$(cat <<'EOF'
sp="$(pct "$DATA_MOUNT")"; rp="$(pct "$ROOT_MOUNT")"
[ -n "$sp" ] || sp=null; [ -n "$rp" ] || rp=null
ws="$(wallet_stat)"; wb="${ws##* }"; [ -n "$wb" ] || wb=0
gi="$(getinfo)"
em=""; bm=""
if running "$EC"; then em="$(mem_mib "$EC")"; fi
if running "$BOT"; then bm="$(mem_mib "$BOT")"; fi
printf '{"ts":"%s","srvOasisPct":%s,"rootPct":%s,"ecoinChainBytes":%s,"walletDatBytes":%s,"blocks":%s,"connections":%s,"balance":%s,"botFlumeBytes":%s,"ecoinMemMiB":%s,"botMemMiB":%s}\n' \
  "$(date -u +%FT%TZ)" "$sp" "$rp" "$(chain_bytes)" "$wb" \
  "$(num "$(printf '%s\n' "$gi" | jf blocks)")" "$(num "$(printf '%s\n' "$gi" | jf connections)")" "$(num "$(printf '%s\n' "$gi" | jf balance)")" \
  "$(bytes "$BOT_DATA/ssb-data/flume")" "$(num "$em")" "$(num "$bm")"
EOF
)"
    ;;

  *)
    echo "ERROR: subcomando desconocido: $CMD" >&2
    usage
    exit 2
    ;;
esac
