#!/usr/bin/env bash
# =============================================================================
# upgrade-preflight.sh — check-warning ANTES de un upgrade de Oasis.
#
# Corre en el HOST (necesita .git, el remote `oasis-upstream` y salida a internet),
# NO dentro del contenedor: el updater interno es un no-op en Docker (.dockerignore
# excluye .git y el aviso es solo console.log). Este script lo reemplaza.
#
# Detecta y AVISA de:
#   1) Drift de versión: local src/server/package.json vs oasis-upstream/main, y
#      de qué commit de upstream se parte (OLD_REF) para el diff de comportamiento
#      (devops/scripts/upgrade-behaviour-diff.sh). La versión de partida es la
#      DESPLEGADA (último registro del journal), no la de HEAD: en la rama de
#      upgrade HEAD ya es la versión nueva. Se puede forzar con --from X.Y.Z.
#   2) Drift de ciclo de red: caps.shs local vs el cap actual de la red, derivado
#      en vivo del directorio https://oasis-project.pub/api/pubs.
#   3) Presencia de nuestro pub en el directorio (cycle/shs/status) — distingue
#      "atraso de cap/deploy" de "descubribilidad" (falta follow-back).
#   4) Estado del árbol git.
#
# Uso: bash devops/scripts/upgrade-preflight.sh [--from X.Y.Z]
#      (UPSTREAM_REMOTE / UPSTREAM_BRANCH por entorno; por defecto oasis-upstream/main)
#
# Salida: bloque "=== UPGRADE PREFLIGHT ===" con GO / N x WARN, y las líneas
# `OLD_REF=<commit>` y `NEW_REF=<commit>` listas para copiar.
# Exit 0 si GO, 1 si hay algún WARN (para poder gatear en CI/deploy).
# =============================================================================
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT" || exit 2

# Datos de instancia → devops/hosts/<DEVOPS_HOST>/host.env
# shellcheck disable=SC1091
source "$REPO_ROOT/devops/scripts/lib-host.sh"
UPSTREAM_REMOTE="${UPSTREAM_REMOTE:-oasis-upstream}"
UPSTREAM_BRANCH="${UPSTREAM_BRANCH:-main}"
JOURNAL="${DEPLOY_LOG_PATH:-$REPO_ROOT/devops/logs/deploy-history.jsonl}"

FROM_VER=""
while [ $# -gt 0 ]; do
  case "$1" in
    --from) FROM_VER="${2:-}"; shift ;;
    --from=*) FROM_VER="${1#--from=}" ;;
    -h|--help) sed -n '2,24p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
  esac
  shift
done
DIRECTORY_API="${DIRECTORY_API:-https://oasis-project.pub/api/pubs}"
OUR_PUB_HOST="${OUR_PUB_HOST:-${PUB_HOST:-}}"

warns=0
note() { printf '  %s\n' "$*"; }
warn() { printf '  [WARN] %s\n' "$*"; warns=$((warns + 1)); }

pkg_version() { grep -m1 '"version"' | sed -E 's/.*"version"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/'; }
local_shs()   { grep -m1 '"shs"' src/configs/server-config.json 2>/dev/null | sed -E 's/.*"shs"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/'; }

fetch() { # $1 url -> stdout ; return !=0 on failure
  if   command -v curl >/dev/null 2>&1; then curl -fsSL --max-time 15 "$1"
  elif command -v wget >/dev/null 2>&1; then wget -qO- --timeout=15 "$1"
  else return 127; fi
}

echo "=== UPGRADE PREFLIGHT ==="
echo

# --- 1) árbol + remote -------------------------------------------------------
echo "-- Árbol --"
note "Branch: $(git branch --show-current 2>/dev/null || echo '?')"
# Solo ficheros con seguimiento: uno sin seguimiento (ajustes locales del editor) no viaja a ninguna parte.
if [ -n "$(git status --porcelain --untracked-files=no 2>/dev/null)" ]; then
  warn "working tree NO limpio — commitea/stashea antes del upgrade"
else
  note "Working tree limpio"
fi
git remote | grep -qx "$UPSTREAM_REMOTE" || warn "remote '$UPSTREAM_REMOTE' no configurado"

# --- 2) drift de versión -----------------------------------------------------
echo
echo "-- Versión --"
git fetch "$UPSTREAM_REMOTE" "$UPSTREAM_BRANCH" >/dev/null 2>&1 || warn "git fetch $UPSTREAM_REMOTE falló (offline?)"
LOCAL_VER="$(git show "HEAD:src/server/package.json" 2>/dev/null | pkg_version)"
UP_VER="$(git show "$UPSTREAM_REMOTE/$UPSTREAM_BRANCH:src/server/package.json" 2>/dev/null | pkg_version)"
note "LOCAL=${LOCAL_VER:-?}  UPSTREAM=${UP_VER:-?}"
if [ -n "$LOCAL_VER" ] && [ -n "$UP_VER" ] && [ "$LOCAL_VER" != "$UP_VER" ]; then
  warn "upstream por delante: $LOCAL_VER -> $UP_VER (rebuild desde el host; auto-update in-app deshabilitado)"
fi

# De qué commit de upstream se parte. Upstream no etiqueta las versiones de Oasis (solo las de
# Android): el commit de una versión es el que se titula "Oasis release X.Y.Z".
DEPLOYED_VER="$FROM_VER"
if [ -z "$DEPLOYED_VER" ] && [ -f "$JOURNAL" ]; then
  DEPLOYED_VER="$(tail -n 1 "$JOURNAL" | grep -o '"oasisVersion":"[^"]*"' | cut -d'"' -f4)"
fi
DEPLOYED_VER="${DEPLOYED_VER:-$LOCAL_VER}"
note "DESPLEGADA=${DEPLOYED_VER:-?}  (journal o --from; mídela con deploy-status.sh, bloque «Piezas vivas»)"
NEW_REF="$(git rev-parse --short "$UPSTREAM_REMOTE/$UPSTREAM_BRANCH" 2>/dev/null)"
OLD_REF=""
if [ -n "$DEPLOYED_VER" ]; then
  esc="$(printf '%s' "$DEPLOYED_VER" | sed 's/\./\\./g')"
  OLD_REF="$(git log --format=%h -1 --grep="release $esc\$" "$UPSTREAM_REMOTE/$UPSTREAM_BRANCH" 2>/dev/null)"
fi
if [ -n "$OLD_REF" ] && [ "$(git show "$OLD_REF:src/server/package.json" 2>/dev/null | pkg_version)" = "$DEPLOYED_VER" ]; then
  echo "OLD_REF=$OLD_REF"
  echo "NEW_REF=$NEW_REF"
  # Riesgo por rol. El pub (modo server) no ejecuta «src/server»: ejecuta el CIERRE de requires de
  # SSB_server.js, que sale de esa carpeta (banking_model.js, state-manager…). Los backends (HUB,
  # bots) y el cliente pueden cargar todo src/.
  # src/base (desde 1.2) son dependencias vendorizadas: se cuentan aparte, no como código de Oasis.
  n_all="$(git diff --name-only "$OLD_REF" "$NEW_REF" -- src ':!src/client/assets' ':!src/base' | wc -l | tr -d ' ')"
  n_vendor="$(git diff --name-only "$OLD_REF" "$NEW_REF" -- src/base | wc -l | tr -d ' ')"
  closure="$(node "$REPO_ROOT/devops/scripts/upgrade-closure.js" "$NEW_REF" src/server/SSB_server.js 2>/dev/null)"
  if [ -n "$closure" ]; then
    changed="$(git diff --name-only "$OLD_REF" "$NEW_REF" -- src | grep -Fx -f <(printf '%s\n' "$closure") | grep -v 'package-lock.json')"
    note "Código que cambia por rol: pub en modo server = $(printf '%s' "$changed" | grep -c .) de los $(printf '%s\n' "$closure" | grep -c .) ficheros que carga · backends y cliente = $n_all · dependencias vendorizadas (src/base) = $n_vendor"
    printf '%s\n' "$changed" | grep . | sed 's/^/      pub: /'
  else
    warn "no pude calcular el cierre de requires del modo server (¿node?): cuenta solo src/server = $(git diff --name-only "$OLD_REF" "$NEW_REF" -- src/server | wc -l | tr -d ' ')"
  fi
  note "Siguiente: bash devops/scripts/upgrade-behaviour-diff.sh $OLD_REF $NEW_REF"
else
  warn "no encuentro en $UPSTREAM_REMOTE/$UPSTREAM_BRANCH el commit de la versión ${DEPLOYED_VER:-?} (prueba --from X.Y.Z)"
fi

# --- 3) drift de ciclo + presencia en el directorio --------------------------
echo
echo "-- Ciclo de red (directorio: $DIRECTORY_API) --"
LSHS="$(local_shs)"
note "caps.shs local: ${LSHS:-?}"
API_JSON="$(fetch "$DIRECTORY_API" 2>/dev/null || true)"
if [ -z "$API_JSON" ]; then
  warn "no se pudo leer el directorio (fallback: scraping / pedir al admin aviso de cambios de esquema)"
elif command -v python3 >/dev/null 2>&1; then
  # Parseo robusto vía helper: ciclo actual = max(cycle) entre online; cap actual
  # = shs mayoritario en ese ciclo; self = fila de nuestro host.
  eval "$(printf '%s' "$API_JSON" | OUR_PUB_HOST="$OUR_PUB_HOST" python3 "$REPO_ROOT/devops/scripts/directory-status.py")"
  if [ "${PARSE_ERR:-0}" = "1" ]; then
    warn "el directorio no devolvió JSON parseable (¿cambió el esquema? avisar al admin)"
  else
    note "Ciclo actual de red: ${CUR_CYCLE:-?}  (cap ${CUR_SHS:-?})"
    if [ -n "$LSHS" ] && [ -n "${CUR_SHS:-}" ] && [ "$LSHS" != "$CUR_SHS" ]; then
      warn "tu caps.shs local != cap actual de la red → la red cambió de ciclo; hay que rotar (A5.2)"
    else
      note "caps.shs local coincide con el cap actual de la red (mismo ciclo)"
    fi
    if [ "${SELF_PRESENT:-0}" = "1" ]; then
      note "Nuestro pub en el directorio: cycle=${SELF_CYCLE:-?} shs=${SELF_SHS:-null} status=${SELF_STATUS:-?}"
      if [ -z "${SELF_SHS:-}" ] || { [ -n "${CUR_CYCLE:-}" ] && [ -n "${SELF_CYCLE:-}" ] && [ "${SELF_CYCLE}" -lt "${CUR_CYCLE}" ] 2>/dev/null; }; then
        warn "pub en ROJO en el directorio (shs null / ciclo<actual). Si el pub vivo está sano en el cap actual → es DESCUBRIBILIDAD (falta follow-back / invite de la red), NO re-deploy."
      fi
    else
      warn "nuestro pub ($OUR_PUB_HOST) no aparece en el directorio"
    fi
  fi
else
  warn "python3 no disponible — chequeo de ciclo omitido; fila cruda:"
  printf '%s' "$API_JSON" | grep -o "{[^{}]*$OUR_PUB_HOST[^{}]*}" || true
fi

# --- resumen -----------------------------------------------------------------
echo
if [ "$warns" -eq 0 ]; then
  echo "=== GO — sin avisos ==="
  exit 0
else
  echo "=== WARN x$warns — revisa arriba antes de continuar ==="
  exit 1
fi
