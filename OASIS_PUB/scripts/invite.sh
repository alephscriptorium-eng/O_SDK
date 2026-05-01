#!/usr/bin/env bash
set -euo pipefail

USES="${1:-1}"
# shellcheck disable=SC1091
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

require_env_file
compose_pub exec -T oasis-pub sh -lc "cd /app/src/server && node /app/OASIS_PUB/tools/ssb-admin.js invite.create '$USES'"
