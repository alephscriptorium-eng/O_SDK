#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEVOPS_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO_ROOT="$(cd "$DEVOPS_DIR/.." && pwd)"

KEY_PATH="${KEY_PATH:-$DEVOPS_DIR/.ssh/gandi_pub_ed25519}"
REMOTE_USER="${REMOTE_USER:-debian}"
REMOTE_HOST="${REMOTE_HOST:-92.243.24.163}"
REMOTE_SITE_DIR="${REMOTE_SITE_DIR:-/opt/oasis-scriptorium/OASIS_PUB/site}"
LOCAL_SITE_DIR="$REPO_ROOT/OASIS_PUB/site"

SSH_OPTS="-i $KEY_PATH -o StrictHostKeyChecking=accept-new -o BatchMode=yes"

[[ -f "$KEY_PATH" ]]        || { echo "ERROR: SSH key not found: $KEY_PATH"; exit 1; }
[[ -d "$LOCAL_SITE_DIR" ]]  || { echo "ERROR: Local site dir not found: $LOCAL_SITE_DIR"; exit 1; }

echo "[deploy-site] → $REMOTE_USER@$REMOTE_HOST:$REMOTE_SITE_DIR"

if command -v rsync >/dev/null 2>&1; then
  rsync -az --checksum --delete \
    -e "ssh $SSH_OPTS" \
    "$LOCAL_SITE_DIR/" \
    "$REMOTE_USER@$REMOTE_HOST:$REMOTE_SITE_DIR/"
else
  # fallback: scp (available everywhere ssh is)
  scp $SSH_OPTS -r "$LOCAL_SITE_DIR/." "$REMOTE_USER@$REMOTE_HOST:$REMOTE_SITE_DIR/"
fi

echo "[deploy-site] Done."
