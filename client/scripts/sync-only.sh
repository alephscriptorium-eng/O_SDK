#!/usr/bin/env bash
# =============================================================================
# sync-only.sh — arranca el cliente como sbot PURO (modo `server` del entrypoint: sin GUI, nada
# puede publicar) para que una identidad recién importada recupere/empuje su feed con el pub ANTES
# de arrancar la GUI (docs/CLIENT-PROTOCOL.md §3; regla de oro de RECOVERY-PROTOCOL.md §4).
#
# Uso (desde la raíz del repo):
#   bash client/scripts/sync-only.sh start [--no-ports]
#   bash client/scripts/sync-only.sh status [--pub] [--watch] [--stable-min N]
#   bash client/scripts/sync-only.sh invite            # SSB_INVITE='host:port:@key~seed' (caso PUB-UNKNOWN)
#   bash client/scripts/sync-only.sh stop [--now]
#
# Veredictos de `status`:
#   SYNC-OK      seq local == seq pub, log estable ≥ N min, pub visto conectado → parar y arrancar la GUI
#   AHEAD        seq local >  seq pub → normal (publicaste offline); el sbot empuja al pub; repetir
#   BEHIND       seq local <  seq pub → NO arrancar la GUI; esperar / reiniciar el contenedor
#   PUB-UNKNOWN  el pub no tiene el feed ni lo sigue → `invite`
#   ID-MISMATCH  el sbot no es el feed del secret → parar YA y revisar el montaje
# =============================================================================
set -euo pipefail
export MSYS_NO_PATHCONV=1

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$REPO_ROOT"

SSB="$REPO_ROOT/volumes-dev/ssb-data"
CTR="oasis-sync-only"
IMAGE="o-sdk-oasis-client"
INSPECT="$SCRIPT_DIR/lib/inspect-log-offset.js"
PROBE="$REPO_ROOT/pub/tools/ssb-probe.js"
STATE="$REPO_ROOT/volumes-dev/logs/sync-only.samples"
PUB_FEED_SEQ="$REPO_ROOT/devops/scripts/pub-feed-seq.sh"

die()  { echo "❌ $2" >&2; exit "$1"; }
warn() { echo "⚠️  $*" >&2; }
info() { echo "→ $*"; }
wpath() { cygpath -m "$1" 2>/dev/null || echo "$1"; }   # rutas para binarios Windows (node) bajo MSYS_NO_PATHCONV
json_get() { node -pe 'const o=JSON.parse(process.argv[1]||"{}"); const v=process.argv[2].split(".").reduce((a,k)=>a&&a[k],o); v===undefined||v===null?"":(typeof v==="object"?JSON.stringify(v):String(v))' "$1" "$2"; }

feed_from_secret() {
  [ -f "$SSB/secret" ] || die 3 "no hay identidad en volumes-dev/ssb-data (import-identity.sh, o alta fresca con docker compose up)"
  grep -o '"id": *"[^"]*"' "$SSB/secret" | head -1 | cut -d'"' -f4
}
ctr_running() { [ "$(docker inspect -f '{{.State.Running}}' "$CTR" 2>/dev/null || echo false)" = "true" ]; }
probe_local() {  # $1 action, $2 invite
  docker exec -i -u oasis -e HOME=/home/oasis -e SSB_FEED="$FEED" -e SSB_ACTION="${1:-seq}" -e SSB_INVITE="${2:-}" "$CTR" \
    sh -lc 'cd /app/src/server && node -' < "$PROBE"
}
log_size() { stat -c%s "$SSB/flume/log.offset" 2>/dev/null || echo 0; }

cmd="${1:-}"; shift || true
case "$cmd" in
# ---------------------------------------------------------------------------------------------- start
start)
  NO_PORTS=0; for a in "$@"; do [ "$a" = "--no-ports" ] && NO_PORTS=1; done
  FEED="$(feed_from_secret)"
  if [ "$(docker inspect -f '{{.State.Running}}' oasis-client 2>/dev/null || echo false)" = "true" ]; then
    die 3 "oasis-client (GUI) está corriendo: docker compose stop oasis-client"
  fi
  [ -z "$(docker ps -aq -f name="^$CTR$")" ] || die 3 "$CTR ya existe: sync-only.sh stop"
  docker image inspect "$IMAGE" >/dev/null 2>&1 || die 3 "imagen $IMAGE no construida: npm run build"
  mkdir -p volumes-dev/logs volumes-dev/ai-models volumes-dev/ecoin-data
  rm -f "$SSB/socket" "$STATE"
  ports=(-p 8008:8008); [ $NO_PORTS = 1 ] && ports=()
  info "arrancando sbot puro como $FEED (modo server, sin GUI)…"
  docker compose run -d --rm --no-deps --name "$CTR" "${ports[@]}" -e OASIS_SKIP_AI_MODEL=true oasis-client server >/dev/null
  for _ in $(seq 60); do [ -f "$SSB/manifest.json" ] && break; sleep 2; done
  if [ ! -f "$SSB/manifest.json" ]; then
    docker logs --tail 40 "$CTR" 2>&1 || true
    die 5 "el sbot no escribió manifest.json en 120 s (¿montaje? ¿log corrupto? mira los logs)"
  fi
  sleep 3
  ME="$(probe_local seq 2>/dev/null | node -pe 'JSON.parse(require("fs").readFileSync(0,"utf8")).me' 2>/dev/null || echo '?')"
  if [ "$ME" != "$FEED" ]; then
    docker stop -t 5 "$CTR" >/dev/null 2>&1 || true
    die 5 "GATE ID-MISMATCH: el sbot dice ser '$ME' y el secret es '$FEED'. Parado. Revisa el volumen/montaje."
  fi
  echo "$(date +%s) $(log_size)" >> "$STATE"
  docker logs --tail 15 "$CTR" 2>&1 | sed 's/^/  │ /' || true
  echo "✅ sbot puro arriba como $FEED · seq local $(node "$(wpath "$INSPECT")" "$(wpath "$SSB/flume/log.offset")" "$FEED" | node -pe 'JSON.parse(require("fs").readFileSync(0,"utf8")).mySeq')"
  echo "   sigue con: bash client/scripts/sync-only.sh status --pub --watch"
  ;;
# ---------------------------------------------------------------------------------------------- status
status)
  PUB=0; WATCH=0; STABLE_MIN=5
  while [ $# -gt 0 ]; do case "$1" in --pub) PUB=1;; --watch) WATCH=1;; --stable-min) shift; STABLE_MIN="$1";; esac; shift; done
  FEED="$(feed_from_secret)"
  ctr_running || die 3 "$CTR no está corriendo (sync-only.sh start)"
  mkdir -p "$(dirname "$STATE")"
  while :; do
    now="$(date +%s)"; size="$(log_size)"; echo "$now $size" >> "$STATE"
    # estabilidad: primera muestra con el tamaño actual
    since="$(awk -v s="$size" '$2==s {print $1; exit}' "$STATE")"; [ -n "$since" ] || since="$now"
    stable_s=$(( now - since ))
    file_json="$(node "$(wpath "$INSPECT")" "$(wpath "$SSB/flume/log.offset")" "$FEED" 2>/dev/null || echo '{}')"
    tail_ok="$(json_get "$file_json" tailOk)"
    seq_file="$(json_get "$file_json" mySeq)"
    sbot_json="$(probe_local seq 2>/dev/null || echo '{}')"
    me="$(json_get "$sbot_json" me)"; seq_sbot="$(json_get "$sbot_json" seq)"
    peers="$(node -pe 'const o=JSON.parse(process.argv[1]||"{}");(o.peers||[]).map(p=>`${p.addr}[${p.state||"?"}]`).join(" ")||"-"' "$sbot_json")"
    pub_conn="$(node -pe 'const o=JSON.parse(process.argv[1]||"{}");String((o.peers||[]).some(p=>/pub\.escrivivir\.co|:8008/.test(p.addr)&&p.state==="connected"))' "$sbot_json")"
    seq_pub=""; follows=""
    if [ $PUB = 1 ]; then
      pub_json="$(bash "$PUB_FEED_SEQ" "$FEED" --raw 2>/dev/null || echo '{}')"
      seq_pub="$(json_get "$pub_json" seq)"; follows="$(json_get "$pub_json" iFollow)"
    fi
    seqL="${seq_sbot:-$seq_file}"; [ -n "$seqL" ] || seqL="$seq_file"
    verdict="SYNCING"
    if [ -n "$me" ] && [ "$me" != "$FEED" ]; then verdict="ID-MISMATCH"
    elif [ $PUB = 1 ] && [ -n "$seq_pub" ]; then
      if   [ "${seq_pub:-0}" = "0" ] && [ "$follows" != "true" ]; then verdict="PUB-UNKNOWN"
      elif [ "$seqL" -lt "$seq_pub" ]; then verdict="BEHIND"
      elif [ "$seqL" -gt "$seq_pub" ]; then verdict="AHEAD"
      elif [ $stable_s -ge $(( STABLE_MIN * 60 )) ] && [ "$pub_conn" = "true" -o "$stable_s" -ge $(( STABLE_MIN * 120 )) ]; then verdict="SYNC-OK"
      else verdict="SYNCING (igual al pub; estable ${stable_s}s/$(( STABLE_MIN*60 ))s, pub conectado=$pub_conn)"; fi
    fi
    printf '%s · log.offset=%s B (estable %ss, tail=%s) · seq local=%s/fichero %s/sbot · seq pub=%s · pub_sigue=%s · peers: %s\n  ⇒ %s\n' \
      "$(date +%H:%M:%S)" "$size" "$stable_s" "${tail_ok:-?}" "${seq_file:-?}" "${seq_sbot:-?}" "${seq_pub:--}" "${follows:--}" "$peers" "$verdict"
    case "$verdict" in
      SYNC-OK) echo "   → bash client/scripts/sync-only.sh stop  &&  docker compose up -d oasis-client"; exit 0 ;;
      ID-MISMATCH) exit 5 ;;
      PUB-UNKNOWN) echo "   → npm run devops:invite -- 1  y luego  SSB_INVITE='…' bash client/scripts/sync-only.sh invite" ;;
      BEHIND) echo "   → NO arrancar la GUI. Si no avanza en 10 min: docker restart $CTR" ;;
    esac
    [ $WATCH = 1 ] || exit 0
    sleep 30
  done
  ;;
# ---------------------------------------------------------------------------------------------- invite
invite)
  FEED="$(feed_from_secret)"; ctr_running || die 3 "$CTR no está corriendo"
  [ -n "${SSB_INVITE:-}" ] || die 2 "define SSB_INVITE='host:port:@key~seed' (npm run devops:invite -- 1)"
  info "redimiendo invite desde el sbot puro (publica un 'contact' hacia el pub: legítimo, seq local ≥ pub)…"
  probe_local invite-accept "$SSB_INVITE"
  echo "   comprueba: bash client/scripts/sync-only.sh status --pub"
  ;;
# ---------------------------------------------------------------------------------------------- stop
stop)
  NOW=0; for a in "$@"; do [ "$a" = "--now" ] && NOW=1; done
  FEED="$(feed_from_secret)"
  if ctr_running && [ $NOW = 0 ]; then
    s1="$(log_size)"; info "comprobando que log.offset está estable (60 s)…"; sleep 60; s2="$(log_size)"
    [ "$s1" = "$s2" ] || die 3 "log.offset sigue creciendo ($s1 → $s2). Espera, o --now"
  fi
  # la parada acaba en SIGKILL (PID 1 es `su`): por eso exigimos estabilidad antes
  docker stop -t 30 "$CTR" >/dev/null 2>&1 || true
  docker rm -f "$CTR" >/dev/null 2>&1 || true
  rm -f "$SSB/socket"
  final="$(node "$(wpath "$INSPECT")" "$(wpath "$SSB/flume/log.offset")" "$FEED")" || die 5 "frame final roto tras la parada: $final"
  echo "✅ parado · seq local final $(json_get "$final" mySeq) · log $(json_get "$final" fileSize) B íntegro"
  echo "   si el último status fue SYNC-OK: docker compose up -d oasis-client"
  ;;
*)
  sed -n '2,20p' "$0"; exit 2 ;;
esac
