#!/usr/bin/env bash
# =============================================================================
# deploy-status.sh — "¿qué hay desplegado AHORA y estamos verdes?" (A0b).
#
# Primer comando a correr al empezar una sesión de ops. Compone tres fuentes:
#   1) Journal de despliegue (último registro local).
#   2) Pub vivo por SSH (delega en GANDI_DEVOPS_FOLDER/scripts/pub-federation.sh
#      status: cap real + feed id + estado del contenedor).
#   3) Presencia en el directorio oasis-project.pub (verde/rojo + motivo).
#
# Read-only. Evita el diagnóstico a ciegas (asumir estados que no son).
# =============================================================================
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUR_PUB_HOST="${OUR_PUB_HOST:-pub.escrivivir.co}"
DIRECTORY_API="${DIRECTORY_API:-https://oasis-project.pub/api/pubs}"
JOURNAL="${DEPLOY_LOG_PATH:-$REPO_ROOT/GANDI_DEVOPS_FOLDER/logs/deploy-history.jsonl}"
FED="$REPO_ROOT/GANDI_DEVOPS_FOLDER/scripts/pub-federation.sh"

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

echo "-- Presencia en el directorio ($DIRECTORY_API) --"
api="$(curl -fsSL --max-time 15 "$DIRECTORY_API" 2>/dev/null || true)"
if [ -n "$api" ] && command -v python3 >/dev/null 2>&1; then
  eval "$(printf '%s' "$api" | OUR_PUB_HOST="$OUR_PUB_HOST" python3 "$REPO_ROOT/scripts/directory-status.py")"
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
