#!/usr/bin/env bash
set -euo pipefail

KEY_PATH="${KEY_PATH:-GANDI_DEVOPS_FOLDER/.ssh/gandi_pub_ed25519}"
REMOTE_USER="${REMOTE_USER:-debian}"
REMOTE_HOST="${REMOTE_HOST:-92.243.24.163}"
USES="${1:-1}"

ssh -i "$KEY_PATH" -o StrictHostKeyChecking=accept-new -o BatchMode=yes \
  "$REMOTE_USER@$REMOTE_HOST" \
  "cd /opt/oasis-scriptorium/OASIS_PUB && bash scripts/env-run.sh .env.prod invite.sh '$USES'"
