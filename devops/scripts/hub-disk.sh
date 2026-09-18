#!/usr/bin/env bash
# =============================================================================
# hub-disk.sh — control del volumen de datos del HUB clearnet (nodo de soporte).
#
# El HUB (`oasis-pub-hub` + `oasis-pub-hub-cache`) guarda TODO su estado bajo
# /srv/oasis/oasis-hub/{ssb-data,logs,http-cache} (volumen de datos, 40 GB).
# Este script mide y acota ese estado. Read-only salvo los subcomandos prune-*.
# Doc viva: docs/PUB/HUB-PROTOCOL.md §6 (tabla de rutas, árbol de decisión).
#
# Uso:
#   bash devops/scripts/hub-disk.sh [--local] <subcomando> [opciones]
#
# Subcomandos:
#   status        df -h de / y /srv/oasis · opciones del mount (¿noatime?) ·
#                 du de ssb-data/{flume,blobs}, http-cache, logs y del pub
#                 (comparativa) · nº de blobs · docker stats de pub, hub,
#                 hub-cache y web · docker system df.   [read-only]
#   check         umbrales HUB_DISK_SOFT_PCT (75) / HUB_DISK_HARD_PCT (90)
#                 sobre /srv/oasis Y / → exit 0 ok · 1 soft · 2 hard
#                 (3 = no se pudo medir).   [read-only; deploy-status.sh y cron]
#   prune-blobs [--older-than N] [--dry-run]
#                 borra blobs de ssb-data/blobs/sha256 no accedidos en N días
#                 (default 30). Criterio -atime; si el mount es noatime cae a
#                 -mtime (fecha de descarga). Seguro: content-addressed, `want`
#                 repone al siguiente GET y nginx conserva la copia HTTP 7 días.
#                 NUNCA toca flume/, secret, conn.json, gossip*.json.
#   prune-cache   vacía http-cache/ y hace `nginx -s reload` en
#                 oasis-pub-hub-cache (útil tras un rebuild de índices para no
#                 servir 60 s de indexingView; casi nunca por espacio).
#   --json        una línea JSON para el journal (devops/logs/hub-disk.jsonl):
#                 {ts, srvOasisPct, rootPct, hubFlumeBytes, hubBlobsBytes,
#                  hubCacheBytes, hubMemMiB}. También `status --json`.
#
# Flag global:
#   --local       en vez de SSH al VPS ejecuta los mismos comandos en local
#                 contra HUB_DATA=${OASIS_HUB_LOCAL_DIR:-<repo>/volumes-dev/oasis-hub}
#                 y df del repo (gate G7 y pruebas sin VPS). Si el directorio
#                 aún no existe avisa, no falla. Nota: en Windows/NTFS (Git
#                 Bash) el propio stat() de find actualiza el atime, así que
#                 un --dry-run "refresca" los blobs y la poda real posterior
#                 no los ve; es un artefacto de la plataforma, no ocurre en ext4.
#
# Cadencia (HUB-PROTOCOL §6): `status --json` en el cierre del deploy (línea
# base), a las 24 h, a los 7 días y después SEMANAL; `check` en cada
# deploy-status. Con 30 días de --json se decide el tope duro (WP-O47).
#
# Instancia: lib-host.sh (DEVOPS_HOST → devops/hosts/<nombre>/host.env:
# REMOTE_USER, REMOTE_HOST, KEY_FILE/KEY_PATH). Variables opcionales:
#   HUB_DATA            ruta del estado del HUB (default /srv/oasis/oasis-hub)
#   HUB_DATA_MOUNT      punto de montaje del volumen de datos (default /srv/oasis)
#   HUB_PUB_DATA        ssb-data del pub para la comparativa
#   HUB_DISK_SOFT_PCT / HUB_DISK_HARD_PCT   umbrales de check (75 / 90)
# =============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Datos de instancia → devops/hosts/<DEVOPS_HOST>/host.env
# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib-host.sh"
REPO_ROOT="$(cd "$DEVOPS_DIR/.." && pwd)"

SOFT="${HUB_DISK_SOFT_PCT:-75}"
HARD="${HUB_DISK_HARD_PCT:-90}"

usage() {
  cat <<EOF
uso: hub-disk.sh [--local] status [--json] | check | prune-blobs [--older-than N] [--dry-run] | prune-cache | --json
  --local   ejecuta en local contra \${OASIS_HUB_LOCAL_DIR:-<repo>/volumes-dev/oasis-hub} (sin SSH)
  check     exit 0 ok · 1 ≥ HUB_DISK_SOFT_PCT ($SOFT) · 2 ≥ HUB_DISK_HARD_PCT ($HARD) · 3 sin medida
EOF
}

# ---------------------------------------------------------------------------
# Flags globales y subcomando
# ---------------------------------------------------------------------------
LOCAL=0
JSON=0
CMD=""
ARGS=()
while [ $# -gt 0 ]; do
  case "$1" in
    --local) LOCAL=1 ;;
    --json)  JSON=1 ;;
    -h|--help) usage; exit 0 ;;
    *) if [ -z "$CMD" ]; then CMD="$1"; else ARGS+=("$1"); fi ;;
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
  HUB_DATA="${OASIS_HUB_LOCAL_DIR:-$REPO_ROOT/volumes-dev/oasis-hub}"
  DATA_MOUNT="${HUB_DATA_MOUNT:-$REPO_ROOT}"
  ROOT_MOUNT="$REPO_ROOT"
  PUB_DATA="${HUB_PUB_DATA:-$REPO_ROOT/volumes-dev/oasis-pub/ssb-data}"
  SUDO=""
  WHERE="local"
  if [ ! -d "$HUB_DATA" ]; then
    echo "AVISO: $HUB_DATA no existe todavía (el HUB local aún no ha arrancado); los du saldrán a 0." >&2
  fi
else
  HUB_DATA="${HUB_DATA:-/srv/oasis/oasis-hub}"
  DATA_MOUNT="${HUB_DATA_MOUNT:-/srv/oasis}"
  ROOT_MOUNT="/"
  PUB_DATA="${HUB_PUB_DATA:-${REMOTE_DATA_ROOT:-/srv/oasis/oasis-pub}/ssb-data}"
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

# Guardas: prune-* solo bajo un HUB_DATA con nombre; nunca sobre / ni vacío.
case "$HUB_DATA" in
  ""|"/"|"/srv"|"/srv/oasis") echo "ERROR: HUB_DATA inválido: '$HUB_DATA'" >&2; exit 3 ;;
esac

# run_h <cuerpo>: ejecuta el cuerpo con `bash -s` en local o en el VPS. El
# cuerpo se escribe con comillas simples ('EOF') y recibe las variables por el
# preludio: idéntico en ambos modos → lo que se prueba en local es lo que corre.
run_h() {
  local prelude body
  prelude="$(printf 'set -uo pipefail\nHUB_DATA=%q; DATA_MOUNT=%q; ROOT_MOUNT=%q; PUB_DATA=%q; SUDO=%q\n' \
    "$HUB_DATA" "$DATA_MOUNT" "$ROOT_MOUNT" "$PUB_DATA" "$SUDO")"
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
pct(){ df -P "$1" 2>/dev/null | awk '"'"'NR==2{gsub("%","",$5); print $5}'"'"'; }
bytes(){ if [ -d "$1" ]; then $SUDO du -sb "$1" 2>/dev/null | cut -f1; else echo 0; fi; }
mount_opts(){ if command -v findmnt >/dev/null 2>&1; then findmnt -no OPTIONS "$1" 2>/dev/null; else echo "(findmnt no disponible)"; fi; }
hub_containers(){ docker ps --format "{{.Names}}" 2>/dev/null | grep -E "^(oasis-pub-hub|oasis-pub-hub-cache|oasis-pub-scriptorium|oasis-pub-web)$" || true; }
mem_mib(){ docker stats --no-stream --format "{{.MemUsage}}" oasis-pub-hub 2>/dev/null | awk '"'"'{v=$1; u=v; gsub(/[0-9.]/,"",u); sub(/[A-Za-z]+$/,"",v); m=v; if(u=="GiB")m=v*1024; else if(u=="KiB")m=v/1024; else if(u=="B")m=v/1048576; else if(u=="GB")m=v*953.674; else if(u=="kB")m=v/1048.576; else if(u=="MB")m=v/1.048576; printf "%d\n", m}'"'"'; }
'

# ---------------------------------------------------------------------------
# Subcomandos
# ---------------------------------------------------------------------------
case "$CMD" in
  status)
    echo "=== HUB DISK · $WHERE · HUB_DATA=$HUB_DATA ==="
    run_h "$(cat <<'EOF'
echo "-- df --"
df -h "$ROOT_MOUNT" "$DATA_MOUNT" 2>/dev/null | awk 'NR==1 || !seen[$0]++'
echo
echo "-- mount $DATA_MOUNT (noatime ⇒ prune-blobs usa -mtime) --"
mount_opts "$DATA_MOUNT"
echo
echo "-- tamaño (du) --"
for d in "$HUB_DATA/ssb-data/flume" "$HUB_DATA/ssb-data/blobs" "$HUB_DATA/http-cache" "$HUB_DATA/logs" "$PUB_DATA" "$(dirname "$PUB_DATA")/teatro"; do
  if [ -d "$d" ]; then $SUDO du -sh "$d" 2>/dev/null || echo "?	$d"; else echo "0	$d (no existe)"; fi
done
echo
if [ -d "$HUB_DATA/ssb-data/blobs" ]; then
  echo "blobs=$($SUDO find "$HUB_DATA/ssb-data/blobs" -type f 2>/dev/null | wc -l | tr -d ' ')"
else
  echo "blobs=0 (sin directorio)"
fi
echo
echo "-- docker stats --"
cs="$(hub_containers)"
if [ -n "$cs" ]; then
  # shellcheck disable=SC2086
  docker stats --no-stream --format 'table {{.Name}}\t{{.MemUsage}}\t{{.CPUPerc}}' $cs 2>/dev/null || echo "(docker stats falló)"
else
  echo "(ninguno de oasis-pub-hub / oasis-pub-hub-cache / oasis-pub-scriptorium / oasis-pub-web está en marcha)"
fi
echo
echo "-- docker system df --"
docker system df 2>/dev/null || echo "(docker no disponible)"
EOF
)"
    ;;

  check)
    out="$(run_h "$(cat <<'EOF'
echo "$(pct "$DATA_MOUNT") $(pct "$ROOT_MOUNT")"
EOF
)")"
    p="${out%% *}"; r="${out##* }"
    if [ -z "$p" ] || [ -z "$r" ] || ! [ "$p" -ge 0 ] 2>/dev/null || ! [ "$r" -ge 0 ] 2>/dev/null; then
      echo "hub-disk check: no se pudo medir ($WHERE)"
      exit 3
    fi
    m=$(( p > r ? p : r ))
    verdict="OK"
    [ "$m" -ge "$SOFT" ] && verdict="SOFT"
    [ "$m" -ge "$HARD" ] && verdict="HARD"
    echo "hub-disk check: uso $DATA_MOUNT=$p% $ROOT_MOUNT=$r% (soft $SOFT / hard $HARD) → $verdict"
    case "$verdict" in HARD) exit 2 ;; SOFT) exit 1 ;; *) exit 0 ;; esac
    ;;

  prune-blobs)
    N=30; DRY=0
    set -- "${ARGS[@]+"${ARGS[@]}"}"
    while [ $# -gt 0 ]; do
      case "$1" in
        --older-than) N="${2:-}"; shift ;;
        --older-than=*) N="${1#*=}" ;;
        --dry-run) DRY=1 ;;
        *) echo "ERROR: opción desconocida para prune-blobs: $1" >&2; usage; exit 2 ;;
      esac
      shift
    done
    [ "$N" -ge 0 ] 2>/dev/null || { echo "ERROR: --older-than espera un entero de días" >&2; exit 2; }
    run_h "N=$N; DRY=$DRY
$(cat <<'EOF'
B="$HUB_DATA/ssb-data/blobs/sha256"
if [ ! -d "$B" ]; then echo "prune-blobs: $B no existe; nada que podar"; exit 0; fi
# -atime solo es fiable si el mount NO es noatime; con noatime se cae a -mtime (fecha de descarga)
case "$(mount_opts "$DATA_MOUNT")" in *noatime*) F=-mtime ;; *) F=-atime ;; esac
if [ "$DRY" = 1 ]; then echo "criterio=$F +$N (dry-run, no se borra nada)"; else echo "criterio=$F +$N"; fi
if [ "$DRY" = 1 ]; then
  n="$($SUDO find "$B" -type f "$F" "+$N" -print 2>/dev/null | wc -l | tr -d ' ')"
else
  n="$($SUDO find "$B" -type f "$F" "+$N" -print -delete 2>/dev/null | wc -l | tr -d ' ')"
fi
echo "afectados=$n"
EOF
)"
    ;;

  prune-cache)
    run_h "$(cat <<'EOF'
C="$HUB_DATA/http-cache"
if [ ! -d "$C" ]; then echo "prune-cache: $C no existe; nada que vaciar"; exit 0; fi
before="$(bytes "$C")"
$SUDO find "$C" -mindepth 1 -delete 2>/dev/null || echo "AVISO: find -delete devolvió error (¿permisos?)" >&2
echo "http-cache: $before → $(bytes "$C") bytes"
if docker ps --format '{{.Names}}' 2>/dev/null | grep -qx oasis-pub-hub-cache; then
  docker exec oasis-pub-hub-cache nginx -s reload && echo "nginx -s reload: ok"
else
  echo "AVISO: oasis-pub-hub-cache no está en marcha; sin reload (la caché se rehace al arrancar)"
fi
EOF
)"
    ;;

  json)
    run_h "$(cat <<'EOF'
mem="$(mem_mib)"; [ -n "$mem" ] || mem=null
sp="$(pct "$DATA_MOUNT")"; rp="$(pct "$ROOT_MOUNT")"
[ -n "$sp" ] || sp=null; [ -n "$rp" ] || rp=null
printf '{"ts":"%s","srvOasisPct":%s,"rootPct":%s,"hubFlumeBytes":%s,"hubBlobsBytes":%s,"hubCacheBytes":%s,"hubMemMiB":%s}\n' \
  "$(date -u +%FT%TZ)" "$sp" "$rp" \
  "$(bytes "$HUB_DATA/ssb-data/flume")" "$(bytes "$HUB_DATA/ssb-data/blobs")" "$(bytes "$HUB_DATA/http-cache")" "$mem"
EOF
)"
    ;;

  *)
    echo "ERROR: subcomando desconocido: $CMD" >&2
    usage
    exit 2
    ;;
esac
