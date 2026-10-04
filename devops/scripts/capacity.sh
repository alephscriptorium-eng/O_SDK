#!/usr/bin/env bash
# =============================================================================
# capacity.sh — inventario único de lo que CRECE en una instancia y de sus límites
# (docs/PUB/CAPACIDAD.md, D-O27). Solo lectura.
#
# Uso:
#   bash devops/scripts/capacity.sh [--local] [--json]
#
#   --local   stack local (volumes-dev/); sin él, el host de la instancia por SSH
#   --json    una línea JSON para un journal (devops/logs/capacity.jsonl)
#
# Qué mide, por nodo de Oasis (pub, HUB, bots): log (db2/log.bipf o flume/log.offset), índices
# (db2/indexes, db2/jit), blobs, snapshots (oasis/content), /app/logs, log de Docker, capa del
# contenedor (lo que se escribe fuera de los volúmenes: /tmp, src/maps/cache), memoria y su límite.
# Del host: discos, imágenes y caché de build, restos de rollback, cadena de ecoind, caché HTTP.
#
# Cada fila lleva un estado: ok · AVISO (pasa su presupuesto, o no tiene límite donde debería
# tenerlo) · ? (no se pudo medir). Los presupuestos son umbrales de aviso, no límites: el límite,
# cuando existe, lo pone la pieza (compose, config del nodo, nginx). Se ajustan por entorno:
#   CAP_LOG_MB=1024  CAP_INDEX_MB=1024  CAP_BLOBS_PUB_MB=4096  CAP_BLOBS_HUB_MB=2048  CAP_BLOBS_BOT_MB=256
#   CAP_SNAPSHOT_MB=512  CAP_APPLOGS_MB=200  CAP_LAYER_MB=300  CAP_MEM_PCT=80
#   CAP_DISK_SOFT=75  CAP_DISK_HARD=90  CAP_IMAGES_GB=12  CAP_CHAIN_MB=2048  CAP_HTTPCACHE_MB=2048
#
# Códigos: 0 todo ok · 1 hay avisos · 2 disco por encima del umbral duro · 3 no se pudo medir
# Nodos: GATE_NODES="alias:contenedor:servicio …" (los mismos que upgrade-gates.sh)
# =============================================================================
set -uo pipefail
export MSYS_NO_PATHCONV=1

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib-host.sh"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib-node.sh"

LOCAL=0; JSON=0
while [ $# -gt 0 ]; do
  case "$1" in
    --local) LOCAL=1 ;;
    --json) JSON=1 ;;
    -h|--help) sed -n '2,27p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "argumento desconocido: $1" >&2; exit 64 ;;
  esac
  shift
done

GATE_NODES="${GATE_NODES:-pub:${PUB_CONTAINER:-oasis-pub-scriptorium}:oasis-pub hub:oasis-pub-hub:oasis-hub bot:oasis-pub-wallet-bot:oasis-wallet-bot}"
trap node_run_cleanup EXIT
node_run_setup "$LOCAL" || exit 3
if [ "$LOCAL" = 1 ]; then ROOT_MOUNT="$(cd "$DEVOPS_DIR/.." && pwd)"; DATA_MOUNT="$ROOT_MOUNT"; REPO_HOST="$ROOT_MOUNT"
else ROOT_MOUNT="/"; DATA_MOUNT="${HUB_DATA_MOUNT:-/srv/oasis}"; REPO_HOST="$(dirname "${REMOTE_REPO_DIR:-/opt/oasis}")"; fi

raw="$({ node_remote_preamble; node_remote_lib
  printf 'GATE_NODES=%q; ROOT_MOUNT=%q; DATA_MOUNT=%q; REPO_HOST=%q\n' "$GATE_NODES" "$ROOT_MOUNT" "$DATA_MOUNT" "$REPO_HOST"
  for v in CAP_LOG_MB:1024 CAP_INDEX_MB:1024 CAP_BLOBS_PUB_MB:4096 CAP_BLOBS_HUB_MB:2048 CAP_BLOBS_BOT_MB:256 CAP_SNAPSHOT_MB:512 \
           CAP_APPLOGS_MB:200 CAP_LAYER_MB:300 CAP_MEM_PCT:80 CAP_DISK_SOFT:75 CAP_DISK_HARD:90 CAP_IMAGES_GB:12 CAP_CHAIN_MB:2048 CAP_HTTPCACHE_MB:2048; do
    n="${v%%:*}"; printf '%s=%q\n' "$n" "${!n:-${v##*:}}"
  done
  cat <<'EOS'
# Sin argumentos devuelve 0: un `du` sin rutas mediría el directorio actual entero.
mb()    { [ $# -gt 0 ] || { echo 0; return; }; local b; b="$($SUDO du -sb "$@" 2>/dev/null | awk '{s+=$1} END{print s+0}')"; echo $(( ${b:-0} / 1048576 )); }
have()  { $SUDO test -e "$1" 2>/dev/null; }
# row <ámbito> <qué> <valor> <unidad> <presupuesto|-> <límite real|-> [estado forzado]
row()   { local st="${7:-}"; if [ -z "$st" ]; then st=ok; if [ "$3" = "?" ]; then st="?"; elif [ "$5" != "-" ] && [ "$3" -gt "$5" ] 2>/dev/null; then st=AVISO; fi; fi
          printf '%s|%s|%s|%s|%s|%s|%s\n' "$1" "$2" "$3" "$4" "$5" "$6" "$st"; }
# Docker tarda en calcular tamaños y consumo: una sola llamada de cada para todos los contenedores.
SIZES="$(docker ps -s --format '{{.Names}}|{{.Size}}' 2>/dev/null)"
STATS="$(docker stats --no-stream --format '{{.Name}}|{{.MemPerc}}|{{.MemUsage}}' 2>/dev/null)"
for n in $GATE_NODES; do
  a="${n%%:*}"; c="${n#*:}"; c="${c%%:*}"
  d="$(node_ssb_dir "$c")"
  [ -n "$d" ] && have "$d" || { row "$a" "datos" "?" "" - - ; continue; }
  fmt="$(node_log_format "$d")"
  case "$fmt" in db2) lg="$d/db2/log.bipf" ;; *) lg="$d/flume/log.offset" ;; esac
  row "$a" "log ($fmt)" "$(mb "$lg")" MB "$CAP_LOG_MB" "hops/dunbar del ssb-config"
  if [ "$fmt" = db2 ]; then row "$a" "índices (db2/indexes, db2/jit)" "$(mb "$d/db2/indexes" "$d/db2/jit")" MB "$CAP_INDEX_MB" "derivables"
  else row "$a" "índices (flume/*)" "$(( $(mb "$d/flume") - $(mb "$lg") ))" MB "$CAP_INDEX_MB" "derivables"; fi
  case "$a" in pub) cap="$CAP_BLOBS_PUB_MB" ;; hub) cap="$CAP_BLOBS_HUB_MB" ;; *) cap="$CAP_BLOBS_BOT_MB" ;; esac
  lim="$(docker exec "$c" sh -c 'grep -A3 "\"blobCache\"" /app/src/configs/oasis-config.json 2>/dev/null | grep -o "\"pubMaxMB\": *[0-9]*" | grep -o "[0-9]*$"' 2>/dev/null)"
  mode="$(docker inspect -f '{{join .Config.Cmd " "}}' "$c" 2>/dev/null)"
  case "$mode" in server) blim="sin recolector (solo sbot): hub-disk.sh prune-blobs --node pub" ;; *) if [ "${lim:-0}" -gt 0 ] 2>/dev/null; then blim="blobCache.pubMaxMB=${lim} MB"; else blim="SIN LÍMITE (pubMaxMB=0)"; fi ;; esac
  st=""; case "$blim" in SIN*) st=AVISO ;; esac
  row "$a" "blobs" "$(mb "$d/blobs")" MB "$cap" "$blim" $st
  row "$a" "snapshots (oasis/content)" "$(mb $($SUDO sh -c "ls $d/oasis/content/snapshot* 2>/dev/null"))" MB "$CAP_SNAPSHOT_MB" "$(docker inspect -f '{{range .Config.Env}}{{println .}}{{end}}' "$c" 2>/dev/null | grep -q '^OASIS_SNAPSHOT=off' && echo 'apagados (OASIS_SNAPSHOT=off)' || echo 'pub-snapshot.sh, techo SNAPSHOT_MAX_MB')"
  ld="$(docker inspect -f '{{range .Mounts}}{{if eq .Destination "/app/logs"}}{{.Source}}{{end}}{{end}}' "$c" 2>/dev/null)"
  if [ "${NODE_LOCAL:-0}" = 1 ]; then ld="$(dirname "$d")/logs"; fi
  row "$a" "/app/logs" "$(mb "$ld")" MB "$CAP_APPLOGS_MB" "sin rotación"
  ms="$(docker inspect -f '{{index .HostConfig.LogConfig.Config "max-size"}}×{{index .HostConfig.LogConfig.Config "max-file"}}' "$c" 2>/dev/null)"
  lp="$(docker inspect -f '{{.LogPath}}' "$c" 2>/dev/null)"
  lmb=0; if [ -n "$lp" ] && have "$lp"; then lmb="$($SUDO sh -c "du -cb ${lp}* 2>/dev/null | tail -1 | cut -f1" 2>/dev/null)"; lmb="${lmb:-0}"; fi
  case "$ms" in ×|"<no value>×<no value>"|"") row "$a" "log de Docker" "$(( lmb / 1048576 ))" MB - "SIN ROTACIÓN" AVISO ;; *) row "$a" "log de Docker" "$(( lmb / 1048576 ))" MB - "$ms" ;; esac
  layer="$(printf '%s
' "$SIZES" | awk -F'|' -v c="$c" '$1==c{print $2}' | awk '{v=$1; u=v; gsub(/[0-9.]/,"",u); gsub(/[A-Za-z]/,"",v); if(u=="GB")v*=1024; else if(u=="kB")v/=1024; else if(u=="B")v/=1048576; printf "%d", v}')"
  row "$a" "capa del contenedor (/tmp, maps/cache…)" "${layer:-?}" MB "$CAP_LAYER_MB" "se vacía al recrear"
  mem="$(printf '%s
' "$STATS" | awk -F'|' -v c="$c" '$1==c{print $2}' | tr -d '%' | cut -d. -f1)"
  ml="$(docker inspect -f '{{.HostConfig.Memory}}' "$c" 2>/dev/null)"
  if [ "${ml:-0}" = 0 ]; then row "$a" "memoria" "$(printf '%s
' "$STATS" | awk -F'|' -v c="$c" '$1==c{print $3}' | awk '{print $1}')" "" - "SIN LÍMITE" AVISO
  else row "$a" "memoria" "${mem:-?}" "% del límite" "$CAP_MEM_PCT" "mem_limit=$(( ml / 1048576 )) MB"; fi
done
# --- host
for m in "$ROOT_MOUNT" "$DATA_MOUNT"; do
  p="$(df -P "$m" 2>/dev/null | awk 'NR==2{gsub("%","",$5); print $5}')"
  st=""; if [ -n "$p" ] && [ "$p" -ge "$CAP_DISK_HARD" ]; then st=DURO; fi
  row host "disco $m" "${p:-?}" "%" "$CAP_DISK_SOFT" "umbral duro $CAP_DISK_HARD %" $st
done
# Suma de las imágenes por ID (no por etiqueta). No descuenta capas compartidas: es una cota superior.
# `docker system df` daría la cifra exacta y la caché de build, pero puede tardar minutos: no se usa aquí.
img="$(docker images --format '{{.ID}}|{{.Size}}' 2>/dev/null | sort -u | awk -F'|' '{v=$2; u=v; gsub(/[0-9.]/,"",u); gsub(/[A-Za-z]/,"",v); if(u=="MB")v/=1024; else if(u=="kB")v/=1048576; s+=v} END{printf "%d", s}')"
row host "imágenes de Docker (cota superior)" "${img:-?}" GB "$CAP_IMAGES_GB" "poda en cada deploy (UPGRADE §4 paso 2); la caché de build no se mide aquí"
rb="$( { $SUDO sh -c "ls -d $REPO_HOST/src.old* $REPO_HOST/*/src.old* $DATA_MOUNT/src-*.tgz 2>/dev/null"; docker images --format '{{.Repository}}:{{.Tag}}' 2>/dev/null | grep -E ':[0-9]+\.[0-9]+\.[0-9]+(-[a-z]+)?$' | grep -v ecoin; } | wc -l | tr -d ' ')"
row host "restos de rollback (src.old*, tgz, tags)" "$rb" "" 3 "se retiran al sustituirlos el ciclo siguiente"
if [ "${NODE_LOCAL:-0}" = 1 ]; then ch="$NODE_DATA/ecoin"; hc="$NODE_DATA/oasis-hub/http-cache"; else ch="$NODE_DATA/ecoin"; hc="$NODE_DATA/oasis-hub/http-cache"; fi
have "$ch" && row host "cadena de ecoind" "$(mb "$ch")" MB "$CAP_CHAIN_MB" "no se puede podar"
have "$hc" && row host "caché HTTP del visor" "$(mb "$hc")" MB "$CAP_HTTPCACHE_MB" "nginx max_size + inactive 7d"
EOS
} | run 2>/dev/null)"

[ -n "$raw" ] || { echo "capacity: no se pudo medir (¿Docker/SSH?)" >&2; exit 3; }

if [ "$JSON" = 1 ]; then
  printf '{"ts":"%s"' "$(date -u +%FT%TZ)"
  printf '%s\n' "$raw" | awk -F'|' '{k=$1 "." $2; gsub(/[^A-Za-z0-9.]+/, "_", k); v=$3; if (v !~ /^[0-9]+$/) v="\"" v "\""; printf ",\"%s\":%s", k, v}'
  printf '}\n'
else
  echo "== capacidad · $([ "$LOCAL" = 1 ] && echo local || echo "${PUB_HOST:-host}") · $(date -u +%FT%TZ)"
  printf '%s\n' "$raw" | awk -F'|' '
    $1 != last { printf "\n  %s\n", $1; last = $1 }
    { bud = ($5 == "-") ? "" : sprintf(" (aviso > %s)", $5)
      printf "    %-7s %-42s %8s %-13s%s · %s\n", ($7 == "ok" ? "ok" : $7), $2, $3, $4, bud, $6 }'
  echo
fi
warn="$(printf '%s\n' "$raw" | awk -F'|' '$7=="AVISO"' | wc -l | tr -d ' ')"
unk="$(printf '%s\n' "$raw" | awk -F'|' '$7=="?"' | wc -l | tr -d ' ')"
hard="$(printf '%s\n' "$raw" | awk -F'|' '$7=="DURO"' | wc -l | tr -d ' ')"
[ "$JSON" = 1 ] || echo "capacity: $warn avisos · $unk sin medir · $hard por encima del umbral duro"
if [ "$hard" -gt 0 ]; then exit 2; fi
if [ "$unk" -gt 0 ]; then exit 3; fi
[ "$warn" = 0 ] || exit 1
