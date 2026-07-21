#!/usr/bin/env bash
set -euo pipefail

# shellcheck disable=SC1091
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

ensure_env_from_template
validate_vps_persistent_paths
ensure_runtime_dirs

if grep -q 'change-me-before-deploy' "$PUB_ENV_PATH"; then
  echo "Refusing deploy: replace the placeholder token in $PUB_ENV_PATH first."
  exit 1
fi

compose_pub up -d --build

# --- Journal de despliegue (A0b, best-effort, no-fatal) ----------------------
DEPLOY_LOG="$PUB_DIR/../scripts/deploy-log.sh"
if [ -f "$DEPLOY_LOG" ]; then
  load_pub_env || true
  _ver="$(grep -m1 '"version"' "$PUB_DIR/../src/server/package.json" 2>/dev/null | sed -E 's/.*"version"[^"]*"([^"]+)".*/\1/')"
  _shs="$(grep -m1 '"shs"' "$PUB_DIR/config/ssb/config" 2>/dev/null | sed -E 's/.*"shs"[^"]*"([^"]+)".*/\1/')"
  _cyc="$(grep -m1 '"cycle"' "$PUB_DIR/../src/configs/blockchain-cycle.json" 2>/dev/null | sed -E 's/.*"cycle"[^0-9]*([0-9]+).*/\1/')"
  _feed="$(compose_pub exec -T oasis-pub sh -lc 'node /app/OASIS_PUB/tools/ssb-admin.js whoami 2>/dev/null' 2>/dev/null | grep -oE '@[A-Za-z0-9+/]+=\.ed25519' | head -1 || true)"
  bash "$DEPLOY_LOG" --target pub --host "${OASIS_PUB_HOST:-}" --version "$_ver" \
    --caps-shs "$_shs" --cycle "$_cyc" --feed "$_feed" --mode server || true
fi
