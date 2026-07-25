#!/usr/bin/env bash
set -euo pipefail

# Genera un invite en el pub remoto de la instancia activa (DEVOPS_HOST).
# Uso: bash devops/scripts/generate-invite.sh [usos]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Datos de instancia → devops/hosts/<DEVOPS_HOST>/host.env
# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib-host.sh"

KEY_PATH="${KEY_PATH:-}"
REMOTE_USER="${REMOTE_USER:-}"
REMOTE_HOST="${REMOTE_HOST:-}"
REMOTE_REPO_DIR="${REMOTE_REPO_DIR:-}"
REMOTE_ENV_FILE="${REMOTE_ENV_FILE:-.env.prod}"
USES="${1:-1}"

[[ -f "$KEY_PATH" ]] || { echo "ERROR: clave SSH no encontrada: '$KEY_PATH' (¿DEVOPS_HOST/host.env?)"; exit 1; }
[[ -n "$REMOTE_HOST" && -n "$REMOTE_REPO_DIR" ]] || { echo "ERROR: faltan REMOTE_HOST/REMOTE_REPO_DIR (¿DEVOPS_HOST/host.env?)"; exit 1; }

ssh -i "$KEY_PATH" -o StrictHostKeyChecking=accept-new -o BatchMode=yes \
  "$REMOTE_USER@$REMOTE_HOST" \
  "cd $REMOTE_REPO_DIR && bash scripts/env-run.sh $REMOTE_ENV_FILE invite.sh '$USES'"
