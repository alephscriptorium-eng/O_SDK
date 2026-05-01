#!/usr/bin/env bash
set -euo pipefail

# shellcheck disable=SC1091
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

ensure_env_from_template
ensure_runtime_dirs

if grep -q 'change-me-before-deploy' "$PUB_ENV_PATH"; then
  echo "Refusing deploy: replace the placeholder token in $PUB_ENV_PATH first."
  exit 1
fi

compose_pub up -d --build
