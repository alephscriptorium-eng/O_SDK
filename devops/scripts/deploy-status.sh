#!/usr/bin/env bash
# =============================================================================
# deploy-status.sh — "¿qué hay desplegado AHORA y estamos verdes?" (A0b).
#
# Primer comando a correr al empezar una sesión de ops. Compone cuatro fuentes:
#   1) Journal de despliegue (último registro local).
#   2) Pub vivo por SSH (delega en devops/scripts/pub-federation.sh
#      status: cap real + feed id + estado del contenedor).
#   3) Piezas vivas: versión de Oasis por contenedor y modo; deriva de los ficheros
#      que no viajan con src/ (Dockerfile, entrypoint, compose, configs) frente al
#      repo; restos de rollback.
#   4) Presencia en el directorio oasis-project.pub (verde/rojo + motivo).
#
# Read-only. Evita el diagnóstico a ciegas (asumir estados que no son).
# =============================================================================
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# Datos de instancia → devops/hosts/<DEVOPS_HOST>/host.env
# shellcheck disable=SC1091
source "$(dirname "${BASH_SOURCE[0]}")/lib-host.sh"
# shellcheck disable=SC1091
source "$(dirname "${BASH_SOURCE[0]}")/lib-node.sh"
trap node_run_cleanup EXIT
OUR_PUB_HOST="${OUR_PUB_HOST:-${PUB_HOST:-}}"
DIRECTORY_API="${DIRECTORY_API:-https://oasis-project.pub/api/pubs}"
JOURNAL="${DEPLOY_LOG_PATH:-$REPO_ROOT/devops/logs/deploy-history.jsonl}"
FED="$REPO_ROOT/devops/scripts/pub-federation.sh"

echo "=== DEPLOY STATUS ==="
echo

echo "-- Journal (último registro) --"
if [ -f "$JOURNAL" ]; then
  tail -n 1 "$JOURNAL" | sed 's/^/  /'
else
  echo "  (sin journal en $JOURNAL — aún no se registró ningún deploy)"
fi
echo

echo "-- Pub vivo (SSH, pub-federation.sh status) --"
if [ -f "$FED" ] && [ "${SKIP_LIVE:-0}" != "1" ]; then
  bash "$FED" status 2>&1 | sed 's/^/  /' || echo "  (pub-federation.sh status falló — ¿SSH/clave?)"
else
  echo "  (omitido: $FED no encontrado o SKIP_LIVE=1)"
fi
echo

echo "-- Piezas vivas y deriva host↔repo (SSH, solo lectura) --"
# Qué corre de verdad: versión de Oasis POR CONTENEDOR (la imagen es compartida, pero un retag
# no recrea a nadie) y si los ficheros que no viajan en un upgrade de src/ (Dockerfile,
# entrypoint, compose, configs) son los del repo. Nunca fatal.
if [ "${SKIP_LIVE:-0}" != "1" ] && node_run_setup 0 2>/dev/null; then
  REPO_FILES="Dockerfile docker-entrypoint.sh .dockerignore"
  PUB_FILES="docker-compose.pub.yml caddy/Caddyfile config/hub/nginx.conf.template config/hub/oasis-config.json config/hub/ssb-config config/wallet-bot/oasis-config.json.tpl config/wallet-bot/ssb-config config/wallet-bot/ssb-config.engine-on scripts/render-wallet-bot-config.sh"
  live="$({ node_remote_preamble; node_remote_lib
    printf 'ROOT=%q; PUBDIR=%q; REPO_FILES=%q; PUB_FILES=%q\n' "${REMOTE_REPO_ROOT:-}" "${REMOTE_REPO_DIR:-}" "$REPO_FILES" "$PUB_FILES"
    cat <<'EOS'
blob() { [ -f "$1" ] && (printf 'blob %s\0' "$(stat -c%s "$1")"; cat "$1") | sha1sum | cut -d' ' -f1 || echo -; }
docker ps --format '{{.Names}}' | sort | while read -r c; do
  v="$(node_version "$c")"; [ -n "$v" ] || continue
  cur="$(docker inspect -f '{{.Image}}' "$c" 2>/dev/null)"
  name="$(docker inspect -f '{{.Config.Image}}' "$c" 2>/dev/null)"
  latest="$(docker image inspect -f '{{.Id}}' "$name" 2>/dev/null)"
  [ "$cur" = "$latest" ] && fresh="imagen al día" || fresh="IMAGEN VIEJA (el tag apunta a otra: falta recrear)"
  echo "NODE|$c|$v|$(docker inspect -f '{{join .Config.Cmd " "}}' "$c" 2>/dev/null)|$(node_state "$c")|$fresh"
done
docker ps --format '{{.Names}}|{{.Image}}|{{.Status}}' | sort | sed 's/^/CTR|/'
echo "SRC|$(grep -m1 '"version"' "$ROOT/src/server/package.json" 2>/dev/null | sed 's/.*: *"\([^"]*\)".*/\1/')"
for f in $REPO_FILES; do echo "FILE|$f|$(blob "$ROOT/$f")"; done
for f in $PUB_FILES;  do echo "FILE|pub/$f|$(blob "$PUBDIR/$f")"; done
for d in "$ROOT"/src.old* "$ROOT"/src.new*; do [ -e "$d" ] && echo "REST|$d"; done
ls "$NODE_DATA"/src-*.tgz 2>/dev/null | sed 's/^/REST|/'
docker images --format '{{.Repository}}:{{.Tag}}' 2>/dev/null | grep -v ':latest$\|<none>' | grep -i 'oasis-pub-scriptorium' | sed 's/^/REST|imagen /'
EOS
  } | run 2>/dev/null)"
  if [ -z "$live" ]; then
    echo "  (sin respuesta del host — ¿SSH/clave?)"
  else
    echo "  Nodos de Oasis (versión dentro del contenedor · modo · estado):"
    printf '%s\n' "$live" | awk -F'|' '$1=="NODE"{printf "    %-26s %-8s %-10s %-18s %s\n",$2,$3,$4,$5,$6}'
    echo "  Resto de contenedores:"
    printf '%s\n' "$live" | awk -F'|' '$1=="CTR"{printf "    %-30s %-34s %s\n",$2,$3,$4}' | grep -v -F "$(printf '%s\n' "$live" | awk -F'|' '$1=="NODE"{print "    "$2" "}')" || true
    echo "  src/ en disco del host: $(printf '%s\n' "$live" | awk -F'|' '$1=="SRC"{print $2}')  (lo que entrará en el próximo build)"
    echo "  Deriva (fichero del host frente al repo):"
    printf '%s\n' "$live" | awk -F'|' '$1=="FILE"{print $2" "$3}' | while read -r f h; do
      if [ "$h" = "-" ]; then verdict="no existe en el host"
      elif [ "$h" = "$(git -C "$REPO_ROOT" rev-parse "HEAD:$f" 2>/dev/null)" ]; then verdict="igual que HEAD"
      elif git -C "$REPO_ROOT" cat-file -e "$h" 2>/dev/null; then
        verdict="DISTINTO de HEAD; es una versión que el repo tuvo (último commit que la toca: $(git -C "$REPO_ROOT" log --all --format=%h -1 --find-object="$h" 2>/dev/null || echo '?'))"
      else verdict="DISTINTO de HEAD y no está en la historia del repo (editado en el host o pre-refactor)"; fi
      printf '    %-38s %s\n' "$f" "$verdict"
    done
    rest="$(printf '%s\n' "$live" | awk -F'|' '$1=="REST"{print "    "$2}')"
    if [ -n "$rest" ]; then echo "  Restos de rollback (ocupan disco; src.old* rompe el 'mv' del deploy si ya existe):"; echo "$rest"
    else echo "  Restos de rollback: ninguno"; fi
  fi
else
  echo "  (omitido: SKIP_LIVE=1 o sin acceso SSH)"
fi
echo

echo "-- Presencia en el directorio ($DIRECTORY_API) --"
api="$(curl -fsSL --max-time 15 "$DIRECTORY_API" 2>/dev/null || true)"
if [ -n "$api" ] && command -v python3 >/dev/null 2>&1; then
  eval "$(printf '%s' "$api" | OUR_PUB_HOST="$OUR_PUB_HOST" python3 "$REPO_ROOT/devops/scripts/directory-status.py")"
  if [ "${PARSE_ERR:-0}" = "1" ]; then
    echo "  (el directorio no devolvió JSON parseable)"
  else
    echo "  Ciclo actual de red: ${CUR_CYCLE:-?}  (cap ${CUR_SHS:-?})"
    if [ "${SELF_PRESENT:-0}" = "1" ]; then
      verdict="ROJO"
      if [ -n "${SELF_SHS:-}" ] && [ "${SELF_CYCLE:-}" = "${CUR_CYCLE:-}" ]; then verdict="VERDE"; fi
      echo "  $OUR_PUB_HOST → cycle=${SELF_CYCLE:-?} shs=${SELF_SHS:-null} status=${SELF_STATUS:-?}  [$verdict]"
      if [ "$verdict" = "ROJO" ]; then
        echo "  motivo probable: DESCUBRIBILIDAD (falta follow-back/invite de la red), no re-deploy — protocolo A5.1"
      fi
    else
      echo "  $OUR_PUB_HOST NO aparece en el directorio"
    fi
  fi
else
  echo "  (no se pudo leer el directorio; fallback: scraping / pedir aviso al admin)"
fi
echo

echo "-- Disco del HUB (hub-disk.sh check; best-effort) --"
# Nunca fatal: si el HUB no está desplegado o falla el SSH, deploy-status sigue.
hub_line="$(bash "$REPO_ROOT/devops/scripts/hub-disk.sh" check 2>/dev/null || true)"
echo "  ${hub_line:-(hub-disk.sh check no disponible — ¿HUB aún no desplegado / SSH?)}"
echo

echo "-- hub-wallet (ecoin) (ecoin-disk.sh check; best-effort) --"
# Nunca fatal: si el hub-wallet no está desplegado o falla el SSH, deploy-status sigue.
ecoin_line="$(bash "$REPO_ROOT/devops/scripts/ecoin-disk.sh" check 2>/dev/null || true)"
echo "  ${ecoin_line:-(hub-wallet no desplegado)}"
