#!/usr/bin/env bash
# =============================================================================
# drill-26s.sh — entorno de drill SEPARADO del pub (proyecto oasis-drill-26s) con identidades desechables.
# Envuelve `docker compose` con el override pub/docker-compose.drill.yml y el env pub/.env.drill-26s.
# Nunca toca el stack real (oasis-pub-scriptorium) ni el bot nº 3 real (oasis-pub-retro-bot, volumes-real/).
#
#   bash pub/scripts/drill-26s.sh prep      # crea volumes-dev/drill-26s/… y pub/.env.drill-26s (si no existen)
#   bash pub/scripts/drill-26s.sh config    # compose config (sintaxis, nombres, binds)
#   bash pub/scripts/drill-26s.sh up        # levanta pub, web, hub, hub-cache y retro-bot del drill
#   bash pub/scripts/drill-26s.sh guard     # ningún contenedor drill26s-* monta volumes-real/ (exit 1 si lo hace)
#   bash pub/scripts/drill-26s.sh status    # ps del proyecto + whoami del pub y del bot
#   bash pub/scripts/drill-26s.sh exec <svc> <cmd…>   # docker exec -u oasis en un servicio del drill
#   bash pub/scripts/drill-26s.sh down      # para y retira los contenedores del drill (los datos quedan)
#   bash pub/scripts/drill-26s.sh wipe      # borra volumes-dev/drill-26s (pide escribir BORRAR)
#
# Variables: DRILL_ID (default 26s), DRILL_TEMPLATE (default acampada26s). Todo lo demás sale del env del drill.
# =============================================================================
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DRILL_ID="${DRILL_ID:-26s}"
DRILL_TEMPLATE="${DRILL_TEMPLATE:-acampada26s}"
PROJECT="oasis-drill-${DRILL_ID}"
PREFIX="drill${DRILL_ID}"
ENV_FILE="$ROOT/pub/.env.drill-${DRILL_ID}"
DATA="$ROOT/volumes-dev/drill-${DRILL_ID}"
export MSYS_NO_PATHCONV=1

# Rutas relativas para docker (binario de Windows + MSYS_NO_PATHCONV: una ruta /c/… no se traduce).
compose() { (cd "$ROOT" && docker compose -p "$PROJECT" --env-file "pub/.env.drill-${DRILL_ID}" -f pub/docker-compose.pub.yml -f pub/docker-compose.drill.yml "$@"); }

prep() {
  mkdir -p "$DATA"/oasis-pub/{ssb-data,logs,caddy-data,caddy-config} "$DATA"/oasis-hub/{ssb-data,logs} \
           "$DATA"/oasis-retro-bot/{ssb-data,logs} "$DATA"/teatro
  # Oasis no envía el PM de bienvenida si el flag existe (HUB §3): se pre-crea en el HUB y en el pub del drill.
  for n in oasis-pub oasis-hub oasis-retro-bot; do mkdir -p "$DATA/$n/ssb-data/oasis/flags"; : > "$DATA/$n/ssb-data/oasis/flags/oasis-first-contact"; done
  if [ ! -f "$ENV_FILE" ]; then
    sed -e "s#^OASIS_PUB_SSB_PORT=.*#OASIS_PUB_SSB_PORT=8109#" \
        -e "s#^OASIS_PUB_HTTP_PORT=.*#OASIS_PUB_HTTP_PORT=8188#" \
        -e "s#^OASIS_PUB_HTTPS_PORT=.*#OASIS_PUB_HTTPS_PORT=8543#" \
        -e "s#^PUB_PANEL_PORT=.*#PUB_PANEL_PORT=8788#" \
        -e "s#^OASIS_CLIENT_URL=.*#OASIS_CLIENT_URL=http://localhost:3100#" \
        -e "s#\.\./volumes-dev/oasis-pub/#../volumes-dev/drill-${DRILL_ID}/oasis-pub/#g" \
        -e "s#\.\./volumes-dev/oasis-hub/#../volumes-dev/drill-${DRILL_ID}/oasis-hub/#g" \
        -e "s#\.\./volumes-dev/oasis-retro-bot/#../volumes-dev/drill-${DRILL_ID}/oasis-retro-bot/#g" \
        -e "s#\.\./volumes-dev/teatro#../volumes-dev/drill-${DRILL_ID}/teatro#" \
        -e "s#^OASIS_RETRO_BOT_TEMPLATE=.*#OASIS_RETRO_BOT_TEMPLATE=${DRILL_TEMPLATE}#" \
        -e "s#^OASIS_RETRO_BOT_ASSETS_DIR=.*#OASIS_RETRO_BOT_ASSETS_DIR=./templates/assets/${DRILL_TEMPLATE}#" \
        "$ROOT/pub/.env.local.example" > "$ENV_FILE"
    { echo; echo "# --- drill ${DRILL_ID} (generado por pub/scripts/drill-26s.sh prep; no versionado) ---"; echo "OASIS_HUB_MEM_LIMIT=1024m"; } >> "$ENV_FILE"
    echo "env creado: ${ENV_FILE#$ROOT/}"
  fi
  if grep -qE '^[A-Z_]+=.*volumes-real' "$ENV_FILE"; then echo "PARADA: ${ENV_FILE#$ROOT/} apunta a volumes-real" >&2; exit 1; fi
  echo "datos: ${DATA#$ROOT/}  plantilla: $DRILL_TEMPLATE  proyecto: $PROJECT"
}

guard() {
  local bad=0 ctrs; ctrs="$(docker ps -a --filter "name=^${PREFIX}-" --format '{{.Names}}')"
  [ -n "$ctrs" ] || { echo "guard: sin contenedores ${PREFIX}-*"; return 0; }
  for c in $ctrs; do
    if docker inspect "$c" --format '{{range .Mounts}}{{.Source}}{{"\n"}}{{end}}' | grep -qi "volumes-real"; then echo "GUARD FALLA: $c monta volumes-real" >&2; bad=1; fi
  done
  [ "$bad" = 0 ] && echo "guard ok: $(echo "$ctrs" | wc -l | tr -d ' ') contenedores ${PREFIX}-*, ninguno monta volumes-real"
  return $bad
}

# Ayudantes compartidos con secretaria.sh (probe, conn-fix, join, about): pub/scripts/lib-retro.sh.
. "$ROOT/pub/scripts/lib-retro.sh"
pub_key()  { compose exec -T -u oasis -e HOME=/home/oasis oasis-pub sh -lc 'cd /app/src/server && node /app/pub/tools/ssb-admin.js whoami' 2>/dev/null | grep -oE '@[A-Za-z0-9+/]+=\.ed25519' | head -1; }
ctr_of()   { echo "${PREFIX}-$(echo "$1" | sed 's/^oasis-//;s/^pub-//')"; }   # oasis-pub → drill26s-pub, oasis-retro-bot → drill26s-retro-bot, oasis-hub → drill26s-hub
probe()    { retro_probe "$@"; }
invite_ip() { # invite del pub del drill con el host reescrito a la IP del bridge (ssb-ref exige dominio con punto al crear)
  local ip; ip="$(docker inspect "$(ctr_of oasis-pub)" --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}')"
  local inv; inv="$(compose exec -T -u oasis -e HOME=/home/oasis oasis-pub sh -lc "cd /app/src/server && node -e \"const c=require('ssb-client');const cfg=require('./ssb_config');c(cfg.keys,cfg,(e,s)=>{if(e){console.error(e.message);process.exit(1)}s.invite.create({uses:1,external:'pub.local.test'},(e2,inv)=>{if(e2){console.error(e2.message);process.exit(1)}console.log(inv);s.close()})})\"" | tail -1)"
  [ -n "$inv" ] || { echo "sin invite" >&2; return 1; }
  echo "${inv/pub.local.test/$ip}"
}
pub_addr() { local k; k="$(pub_key)"; k="${k#@}"; k="${k%.ed25519}"; echo "net:oasis-pub:8009~shs:$k"; }   # el pub del drill dentro de su red (HUB §3)
conn_fix() { retro_conn_fix "$1" "$(pub_addr)"; }
join() { # join <oasis-retro-bot|oasis-hub>: invite → accept por socket → restart → conn-fix → restart → sonda connected. Nunca imprime el invite.
  local svc="$1" ctr; ctr="$(ctr_of "$svc")"; local inv; inv="$(invite_ip)" || exit 1
  printf '%s ' "$svc"; retro_join "$ctr" "$(pub_key)" "$inv" "$(pub_addr)"
}
about() { retro_about "$(ctr_of oasis-retro-bot)" "$2" "$3" "${4:-Secretaría (drill)}"; }   # about <png> <desc.txt> [nombre]
seed() { OASIS_RETRO_BOT_CONTAINER="$(ctr_of oasis-retro-bot)" bash "$ROOT/pub/scripts/retro-seed.sh" --env "pub/.env.drill-${DRILL_ID}" --template "$DRILL_TEMPLATE" --pub-id "$(pub_key)" "$@"; }
gates() { GATE_DATA_ROOT="$DATA" OASIS_PUB_ENV_FILE=".env.drill-${DRILL_ID}" GATE_NODES="pub:$(ctr_of oasis-pub):oasis-pub hub:$(ctr_of oasis-hub):oasis-hub retro:$(ctr_of oasis-retro-bot):oasis-retro-bot" bash "$ROOT/devops/scripts/upgrade-gates.sh" --local "$@"; }
client_join() { # cliente desechable (client/docker-compose.drill.yml): mismo caps.shs que el pub, red del drill, invite por socket, conn-fix
  local D2="docker compose -p o-sdk-drill -f docker-compose.yml -f client/docker-compose.drill.yml --env-file client/.env.drill"
  local caps; caps="$(grep -o '"shs": *"[^"]*"' "$ROOT/pub/config/ssb/config.local" | sed -E 's/.*"shs": *"([^"]*)"/\1/')"
  python -X utf8 - "$ROOT/volumes-dev/drill/ssb-data/config" "$caps" <<'PY'
import json,sys,pathlib
p=pathlib.Path(sys.argv[1]); c=json.loads(p.read_text(encoding='utf-8')) if p.exists() else {}
c.setdefault('caps',{})['shs']=sys.argv[2]; p.parent.mkdir(parents=True,exist_ok=True); p.write_text(json.dumps(c,indent=2)+'\n',encoding='utf-8'); print('caps del cliente drill alineado con el pub del drill')
PY
  (cd "$ROOT" && $D2 up -d --no-deps oasis-client >/dev/null 2>&1)
  for i in $(seq 1 18); do docker ps --filter name=^oasis-client-drill --format '{{.Status}}' | grep -q healthy && break; sleep 10; done
  docker network connect "${PROJECT}_oasis_pub_net" oasis-client-drill 2>/dev/null || true
  local pk; pk="$(pub_key)"; local inv; inv="$(invite_ip)" || exit 1
  probe oasis-client-drill "$pk" invite-accept "$inv" | grep -o '"accept": *[a-z]*' | head -1 || true
  conn_fix oasis-client-drill; docker restart oasis-client-drill >/dev/null; sleep 12
  local bot; bot="$(docker exec -u oasis -e HOME=/home/oasis "$(ctr_of oasis-retro-bot)" sh -lc 'cd /app/src/server && node /app/pub/tools/ssb-admin.js whoami' | grep -oE '@[A-Za-z0-9+/]+=\.ed25519' | head -1)"
  for i in $(seq 1 18); do local s; s="$(probe oasis-client-drill "$bot" seq | grep -o '"seq": *[0-9]*' | grep -o '[0-9]*$')"; echo "t=$((i*10))s cliente drill: seq ${s:-?} del bot"; [ "${s:-0}" -ge "${CLIENT_MIN_SEQ:-100}" ] && return 0; sleep 10; done; return 1
}

case "${1:-}" in
  prep) prep ;;
  join) join "${2:?oasis-retro-bot|oasis-hub}" ;;
  about) about "$@" ;;
  seed) seed "${@:2}" ;;
  snapshot|check|hub) gates "$@" ;;
  client-join) client_join ;;
  config) compose config "${@:2}" ;;
  up) prep >/dev/null; compose up -d "${@:2}"; guard ;;
  guard) guard ;;
  status) compose ps; for s in oasis-pub oasis-retro-bot; do printf '%s whoami: ' "$s"; compose exec -T -u oasis -e HOME=/home/oasis "$s" sh -lc 'cd /app/src/server && node /app/pub/tools/ssb-admin.js whoami' 2>/dev/null | grep -oE '@[A-Za-z0-9+/]+=\.ed25519' || echo '?'; done ;;
  exec) compose exec -T -u oasis -e HOME=/home/oasis "${2:?svc}" sh -lc "${*:3}" ;;
  down) compose down "${@:2}" ;;
  wipe) read -r -p "Borrar ${DATA#$ROOT/} (solo el drill). Escribe BORRAR: " ok; [ "$ok" = BORRAR ] || exit 1; compose down -v 2>/dev/null || true; rm -rf "$DATA"; echo "borrado ${DATA#$ROOT/}" ;;
  *) sed -n '2,18p' "$0"; exit 64 ;;
esac
