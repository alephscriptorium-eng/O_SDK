#!/usr/bin/env bash
# =============================================================================
# secretaria.sh — el mando del OPERADOR de una plantilla: una secretaría (bot retro, modo server) que se une al pub del
# colectivo, publica su `about`, siembra la plantilla y reparte los primeros códigos. Método: docs/PUB/TEMPLATE-RUNBOOK.md.
#
#   bash pub/scripts/secretaria.sh <id> prep [--template <plantilla>]   # datos en volumes-real/secretaria-<id>/ y pub/.env.secretaria-<id>
#   bash pub/scripts/secretaria.sh <id> caps <caps.shs del pub>          # pub/config/retro-bot/ssb-config.<id> con la red del pub
#   bash pub/scripts/secretaria.sh <id> config                           # compose config (sintaxis, un solo servicio, binds)
#   bash pub/scripts/secretaria.sh <id> up                               # construye la imagen si falta y levanta SOLO el bot
#   bash pub/scripts/secretaria.sh <id> status                           # contenedor, feed id del bot, pares
#   bash pub/scripts/secretaria.sh <id> join [fichero-con-el-invite]     # PERMISO · invite del pub por fichero o stdin (nunca argumento)
#   bash pub/scripts/secretaria.sh <id> about <png> <desc.txt> <nombre>  # PERMISO · un único about con imagen (descripción por stdin)
#   bash pub/scripts/secretaria.sh <id> seed [--yes <bloque>]...         # dry-run sin --yes; PERMISO por bloque
#   bash pub/scripts/secretaria.sh <id> tombstone [--yes <bloque>]...    # deshacer (TEMPLATE §9), PERMISO por bloque
#   bash pub/scripts/secretaria.sh <id> snapshot|check <tag>             # foto del bot y del sequence del pub visto desde él; Δ
#   bash pub/scripts/secretaria.sh <id> codigos list|sheet|one-use …     # códigos de tribu (pub/scripts/retro-codes.sh)
#   bash pub/scripts/secretaria.sh <id> backup <directorio>              # secret + claves de tribu + conn.json, tar 600 fuera del repo
#   bash pub/scripts/secretaria.sh <id> exec <cmd…>                      # docker exec -u oasis en el bot
#   bash pub/scripts/secretaria.sh <id> down                             # para y retira el contenedor (los datos quedan)
#
# Variante A (la secretaría junto al pub, en su mismo compose): SECRETARIA_COMPOSE=pub y el env del pub
# (p. ej. SECRETARIA_ENV=pub/.env.prod): mismas órdenes, sin override, perfil `retro`, contenedor oasis-pub-retro-bot.
# Nunca imprime invites, semillas ni `secret`. Los pasos PERMISO son irreversibles (AGENTES §3): uno a uno.
# =============================================================================
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=lib-retro.sh
. "$ROOT/pub/scripts/lib-retro.sh"
ID="${1:-}"; CMD="${2:-}"; [ -n "$ID" ] && [ -n "$CMD" ] || { sed -n '3,22p' "$0"; exit 64; }
shift 2
MODE="${SECRETARIA_COMPOSE:-solo}"
if [ "$MODE" = pub ]; then
  ENV_FILE="${SECRETARIA_ENV:-$ROOT/pub/.env.prod}"; PROJECT=""; CTR="${OASIS_RETRO_BOT_CONTAINER:-oasis-pub-retro-bot}"
  compose() { (cd "$ROOT" && docker compose --env-file "${ENV_FILE#$ROOT/}" -f pub/docker-compose.pub.yml --profile retro "$@"); }
else
  ENV_FILE="$ROOT/pub/.env.secretaria-${ID}"; PROJECT="oasis-secretaria-${ID}"; CTR="secretaria-${ID}-bot"
  compose() { (cd "$ROOT" && SECRETARIA_ID="$ID" docker compose -p "$PROJECT" --env-file "pub/.env.secretaria-${ID}" -f pub/docker-compose.pub.yml -f pub/docker-compose.secretaria.yml "$@"); }
fi
DATA="$ROOT/volumes-real/secretaria-${ID}"
CAPS_FILE="$ROOT/pub/config/retro-bot/ssb-config.${ID}"
envget() { [ -f "$ENV_FILE" ] && grep -E "^$1=" "$ENV_FILE" | tail -1 | cut -d= -f2- || true; }
envset() { # envset CLAVE valor: escribe o sustituye en el env (valores públicos: feed id del pub, dirección; nunca invites)
  if grep -qE "^$1=" "$ENV_FILE"; then sed -i -E "s#^$1=.*#$1=$2#" "$ENV_FILE"; else printf '%s=%s\n' "$1" "$2" >> "$ENV_FILE"; fi
}
need_env() { [ -f "$ENV_FILE" ] || { echo "PARADA: falta ${ENV_FILE#$ROOT/} (ejecuta: secretaria.sh $ID prep)" >&2; exit 1; }; }
template() { local t; t="$(envget OASIS_RETRO_BOT_TEMPLATE)"; echo "${t:-campamento}"; }
pub_id() { local p; p="$(envget SECRETARIA_PUB_ID)"; [ -n "$p" ] || { echo "PARADA: SECRETARIA_PUB_ID vacío en ${ENV_FILE#$ROOT/} (lo rellena join; o escríbelo: el feed id del pub, público)" >&2; exit 1; }; echo "$p"; }

prep() {
  local tpl="campamento"; while [ $# -gt 0 ]; do case "$1" in --template) tpl="$2"; shift 2 ;; *) echo "prep: argumento desconocido $1" >&2; exit 2 ;; esac; done
  [ "$MODE" = solo ] || { echo "prep solo aplica a la variante B (SECRETARIA_COMPOSE=solo); en la A el env es el del pub" >&2; exit 2; }
  [ -f "$ROOT/pub/templates/${tpl}.json" ] || { echo "PARADA: no existe pub/templates/${tpl}.json" >&2; exit 1; }
  mkdir -p "$DATA/oasis-retro-bot"/{ssb-data,logs}
  if [ ! -f "$ENV_FILE" ]; then
    sed -e "s#^OASIS_RETRO_BOT_SSB_DATA_DIR=.*#OASIS_RETRO_BOT_SSB_DATA_DIR=../volumes-real/secretaria-${ID}/oasis-retro-bot/ssb-data#" \
        -e "s#^OASIS_RETRO_BOT_LOGS_DIR=.*#OASIS_RETRO_BOT_LOGS_DIR=../volumes-real/secretaria-${ID}/oasis-retro-bot/logs#" \
        -e "s#^OASIS_RETRO_BOT_SSB_CONFIG_FILE=.*#OASIS_RETRO_BOT_SSB_CONFIG_FILE=./config/retro-bot/ssb-config.${ID}#" \
        -e "s#^OASIS_RETRO_BOT_TEMPLATE=.*#OASIS_RETRO_BOT_TEMPLATE=${tpl}#" \
        -e "s#^OASIS_RETRO_BOT_ASSETS_DIR=.*#OASIS_RETRO_BOT_ASSETS_DIR=./templates/assets/${tpl}#" \
        "$ROOT/pub/.env.local.example" > "$ENV_FILE"
    { echo; echo "# --- secretaría ${ID} (generado por pub/scripts/secretaria.sh prep; no versionado: .env.* está en .gitignore) ---"
      echo "SECRETARIA_ID=${ID}"; echo "SECRETARIA_PUB_ID="; echo "SECRETARIA_PUB_ADDR="; } >> "$ENV_FILE"
    echo "env creado: ${ENV_FILE#$ROOT/}"
  else echo "env existente: ${ENV_FILE#$ROOT/} (no se toca)"; fi
  echo "datos: ${DATA#$ROOT/}/oasis-retro-bot/{ssb-data,logs} · plantilla: $tpl · kit: pub/templates/assets/$tpl · proyecto: $PROJECT"
  [ -f "$CAPS_FILE" ] && echo "red (caps.shs): ${CAPS_FILE#$ROOT/} presente" || echo "FALTA la red del pub: secretaria.sh $ID caps <caps.shs de tu pub>"
  [ -d "$ROOT/pub/templates/assets/$tpl" ] || echo "AVISO: no existe el kit pub/templates/assets/$tpl (genera el kit: npm run pub:template:kit)"
}
caps() {
  local c="${1:-}"; [[ "$c" =~ ^[A-Za-z0-9+/]{43}=$ ]] || { echo "caps: espera el caps.shs del pub (base64 de 44 caracteres, acaba en =): se lee en el ssb-config del pub" >&2; exit 2; }
  # rutas relativas a la raíz: un python de Windows no entiende /c/… (Git Bash)
  (cd "$ROOT" && python -X utf8 - "pub/config/retro-bot/ssb-config" "pub/config/retro-bot/ssb-config.${ID}" "$c" <<'PY'
import json, sys
src, dst, c = sys.argv[1:4]
cfg = json.load(open(src, encoding='utf-8')); cfg.setdefault('caps', {})['shs'] = c
open(dst, 'w', encoding='utf-8').write(json.dumps(cfg, indent=2) + '\n')
PY
  )
  echo "escrito ${CAPS_FILE#$ROOT/} (pub:false, hops:3, red del pub). Comprueba que coincide con el del pub: si no, el bot no podrá ni saludar."
}
up() {
  need_env
  if [ "$MODE" = solo ]; then
    [ -f "$CAPS_FILE" ] || { echo "PARADA: falta ${CAPS_FILE#$ROOT/}: mide el caps.shs de tu pub y ejecuta: secretaria.sh $ID caps <valor>" >&2; exit 1; }
    if grep -qE '^OASIS_RETRO_BOT_[A-Z_]+=.*volumes-dev' "$ENV_FILE"; then echo "PARADA: ${ENV_FILE#$ROOT/} apunta el bot a volumes-dev (identidad desechable): la secretaría real va en volumes-real" >&2; exit 1; fi
  fi
  if ! docker image inspect oasis-pub-scriptorium:latest >/dev/null 2>&1; then
    echo "la imagen oasis-pub-scriptorium:latest no existe: se construye (varios minutos la primera vez)"
    (cd "$ROOT" && docker compose --env-file "${ENV_FILE#$ROOT/}" -f pub/docker-compose.pub.yml build oasis-pub)
  fi
  compose up -d --no-deps oasis-retro-bot
  for i in $(seq 1 18); do docker ps --filter "name=^${CTR}$" --format '{{.Status}}' | grep -q healthy && break; sleep 10; done
  docker ps --filter "name=^${CTR}$" --format '{{.Names}} {{.Status}}'
  echo "feed de la secretaría: $(retro_whoami "$CTR" || echo '?') (su secret ha nacido en ${DATA#$ROOT/}/oasis-retro-bot/ssb-data: cópialo, backup)"
}
status() {
  compose ps 2>/dev/null || docker ps --filter "name=^${CTR}$"
  local me; me="$(retro_whoami "$CTR" || true)"; echo "secretaría: ${me:-?}"
  local p; p="$(retro_probe "$CTR" "$(envget SECRETARIA_PUB_ID)" peers || true)"
  echo "pares: $(echo "$p" | grep -c '"state": *"connected"' || echo 0) connected · seq del pub visto desde el bot: $(echo "$p" | grep -o '"seq": *[0-9]*' | grep -o '[0-9]*$' || echo '?')"
}
join() {
  need_env
  local inv
  if [ -n "${1:-}" ]; then inv="$(tr -d '\r\n' < "$1")"; else read -r -s -p "pega el invite del pub (no se mostrará): " inv; echo; fi
  [[ "$inv" =~ ^([^:]+):([0-9]+):(@[A-Za-z0-9+/]+=\.ed25519)~ ]] || { echo "PARADA: eso no parece un invite host:puerto:@clave~semilla" >&2; exit 1; }
  local host="${BASH_REMATCH[1]}" port="${BASH_REMATCH[2]}" pk="${BASH_REMATCH[3]}"
  local k="${pk#@}"; k="${k%.ed25519}"; local addr="net:${host}:${port}~shs:${k}"
  local cur; cur="$(envget SECRETARIA_PUB_ID)"
  if [ -n "$cur" ] && [ "$cur" != "$pk" ]; then echo "PARADA: el invite es de otro pub que el SECRETARIA_PUB_ID del env" >&2; exit 1; fi
  envset SECRETARIA_PUB_ID "$pk"; envset SECRETARIA_PUB_ADDR "$addr"
  echo "pub: $(echo "$pk" | retro_mask) en $host:$port (escrito en el env; público)"
  retro_join "$CTR" "$pk" "$inv" "$addr"
}
about() { [ $# -ge 3 ] || { echo "about <png> <desc.txt> <nombre>" >&2; exit 2; }; [ -f "$1" ] && [ -f "$2" ] || { echo "about: falta el png o el txt" >&2; exit 2; }; retro_about "$CTR" "$1" "$2" "$3"; }
seed() { OASIS_RETRO_BOT_CONTAINER="$CTR" bash "$ROOT/pub/scripts/retro-seed.sh" --env "${ENV_FILE#$ROOT/}" --template "$(template)" --pub-id "$(pub_id)" "$@"; }
tombstone() { OASIS_RETRO_BOT_CONTAINER="$CTR" bash "$ROOT/pub/scripts/retro-tombstone.sh" --pub-id "$(pub_id)" "$@"; }
gates() { # foto/Δ del bot (upgrade-gates.sh --local, solo el nodo retro) + sequence del pub visto desde el bot
  local sub="$1" tag="${2:?tag}"; local pubseq; pubseq="$(retro_pub_seq "$CTR" "$(pub_id)" || echo '?')"
  local f="$ROOT/devops/logs/upgrade/${tag}.pubseq"; mkdir -p "$(dirname "$f")"
  GATE_DATA_ROOT="$DATA" OASIS_PUB_ENV_FILE="$(basename "$ENV_FILE")" GATE_NODES="retro:${CTR}:oasis-retro-bot" bash "$ROOT/devops/scripts/upgrade-gates.sh" --local "$sub" "$tag" "${@:3}"
  if [ "$sub" = snapshot ]; then echo "$pubseq" > "$f"; echo "pub seq (desde el bot) = $pubseq → ${f#$ROOT/}"
  else local prev; prev="$(cat "$f" 2>/dev/null || echo '?')"; echo "pub seq (desde el bot): antes $prev · ahora $pubseq → $([ "$prev" = "$pubseq" ] && echo 'Δ0 ok' || echo 'CAMBIÓ: parada dura (TEMPLATE §5)')"; fi
}
backup() {
  local dir="${1:?directorio fuera del repo}"; mkdir -p "$dir"
  local src="$DATA/oasis-retro-bot/ssb-data"; [ "$MODE" = pub ] && src="$(dirname "$ENV_FILE")/$(envget OASIS_RETRO_BOT_SSB_DATA_DIR)"
  [ -f "$src/secret" ] || { echo "PARADA: no hay secret en $src" >&2; exit 1; }
  local out="$dir/secretaria-${ID}-$(date -u +%Y%m%dT%H%M%SZ).tgz"
  (cd "$src" && tar czf "$out" secret conn.json oasis/keys 2>/dev/null || tar czf "$out" secret oasis/keys); chmod 600 "$out"
  echo "backup: $out ($(wc -c < "$out") B, sha256 $(sha256sum "$out" | cut -c1-16)…). Quién lo custodia: DECISIÓN del colectivo. No va a git."
}

case "$CMD" in
  prep) prep "$@" ;;
  caps) caps "$@" ;;
  config) need_env; compose config "$@" ;;
  up) up ;;
  status) status ;;
  join) join "$@" ;;
  about) about "$@" ;;
  seed) seed "$@" ;;
  tombstone) tombstone "$@" ;;
  snapshot|check) gates "$CMD" "$@" ;;
  codigos) OASIS_RETRO_BOT_CONTAINER="$CTR" OASIS_PUB_ID="$(envget SECRETARIA_PUB_ID)" bash "$ROOT/pub/scripts/retro-codes.sh" --template "$(template)" "$@" ;;
  backup) backup "$@" ;;
  exec) retro_exec "$CTR" "$*" ;;
  down) compose down ;;
  *) sed -n '3,22p' "$0"; exit 64 ;;
esac
