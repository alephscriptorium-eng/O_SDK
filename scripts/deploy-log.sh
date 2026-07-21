#!/usr/bin/env bash
# =============================================================================
# deploy-log.sh — apenda un registro al journal de despliegue (Tarea 1 / A0b).
#
# Journal append-only en JSONL. Lo llaman los flujos de deploy (cliente y pub)
# al terminar un `up -d --build` exitoso. El timestamp lo pone el host.
# Objetivo: que una sesión futura sepa QUÉ hay desplegado sin adivinar.
#
# Uso:
#   scripts/deploy-log.sh --target pub --host pub.escrivivir.co \
#     --version 0.8.8 --caps-shs H5EC... --cycle 6 --feed @/snv...=.ed25519 --mode server
#
# Env: DEPLOY_LOG_PATH sobreescribe la ruta del journal.
# =============================================================================
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOG_PATH="${DEPLOY_LOG_PATH:-$REPO_ROOT/GANDI_DEVOPS_FOLDER/logs/deploy-history.jsonl}"

target=""; host=""; version=""; caps_shs=""; cycle=""; feed=""; mode=""
actor="${DEPLOY_ACTOR:-${USER:-${USERNAME:-unknown}}}"

while [ $# -gt 0 ]; do
  case "$1" in
    --target)   target="${2:-}"; shift 2 ;;
    --host)     host="${2:-}"; shift 2 ;;
    --version)  version="${2:-}"; shift 2 ;;
    --caps-shs) caps_shs="${2:-}"; shift 2 ;;
    --cycle)    cycle="${2:-}"; shift 2 ;;
    --feed)     feed="${2:-}"; shift 2 ;;
    --mode)     mode="${2:-}"; shift 2 ;;
    --actor)    actor="${2:-}"; shift 2 ;;
    *) echo "deploy-log: arg desconocido: $1" >&2; shift ;;
  esac
done

ts="$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo '')"
gitsha="$(git -C "$REPO_ROOT" rev-parse --short HEAD 2>/dev/null || echo '')"
mkdir -p "$(dirname "$LOG_PATH")"

# escape minimal (los campos son ids/versiones/caps: sin comillas ni saltos)
esc() { printf '%s' "${1:-}" | sed 's/\\/\\\\/g; s/"/\\"/g'; }

printf '{"ts":"%s","target":"%s","host":"%s","gitSha":"%s","oasisVersion":"%s","capsShs":"%s","cycle":"%s","feedId":"%s","mode":"%s","actor":"%s"}\n' \
  "$ts" "$(esc "$target")" "$(esc "$host")" "$gitsha" "$(esc "$version")" \
  "$(esc "$caps_shs")" "$(esc "$cycle")" "$(esc "$feed")" "$(esc "$mode")" "$(esc "$actor")" \
  >> "$LOG_PATH"

echo "deploy-log: registro añadido a $LOG_PATH"
