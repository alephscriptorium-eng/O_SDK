#!/usr/bin/env bash
# =============================================================================
# upgrade-preflight.sh — check-warning ANTES de un upgrade de Oasis.
#
# Corre en el HOST (necesita .git, el remote `oasis-upstream` y salida a internet),
# NO dentro del contenedor: el updater interno es un no-op en Docker (.dockerignore
# excluye .git y el aviso es solo console.log). Este script lo reemplaza.
#
# Detecta y AVISA de:
#   1) Drift de versión: local src/server/package.json vs oasis-upstream/master.
#   2) Drift de ciclo de red: caps.shs local vs el cap actual de la red, derivado
#      en vivo del directorio https://oasis-project.pub/api/pubs.
#   3) Presencia de nuestro pub en el directorio (cycle/shs/status) — distingue
#      "atraso de cap/deploy" de "descubribilidad" (falta follow-back).
#   4) Estado del árbol git.
#
# Salida: bloque "=== UPGRADE PREFLIGHT ===" con GO / N x WARN.
# Exit 0 si GO, 1 si hay algún WARN (para poder gatear en CI/deploy).
# =============================================================================
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT" || exit 2

UPSTREAM_REMOTE="${UPSTREAM_REMOTE:-oasis-upstream}"
UPSTREAM_BRANCH="${UPSTREAM_BRANCH:-master}"
DIRECTORY_API="${DIRECTORY_API:-https://oasis-project.pub/api/pubs}"
OUR_PUB_HOST="${OUR_PUB_HOST:-pub.escrivivir.co}"

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
if [ -n "$(git status --porcelain 2>/dev/null)" ]; then
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
  eval "$(printf '%s' "$API_JSON" | OUR_PUB_HOST="$OUR_PUB_HOST" python3 "$REPO_ROOT/scripts/directory-status.py")"
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
