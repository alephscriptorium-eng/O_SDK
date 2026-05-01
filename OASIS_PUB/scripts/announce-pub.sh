#!/usr/bin/env bash
set -euo pipefail

# shellcheck disable=SC1091
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

load_pub_env

HOST="${1:-${OASIS_PUB_HOST:-pub.escrivivir.co}}"
PORT="${2:-${OASIS_PUB_SSB_PORT:-8008}}"

compose_pub exec -T oasis-pub sh -lc "cd /app/src/server && OASIS_PUB_HOST='$HOST' OASIS_PUB_PORT='$PORT' node /app/OASIS_PUB/tools/ssb-admin.js announce-pub '$HOST' '$PORT'"
