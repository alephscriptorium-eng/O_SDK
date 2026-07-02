#!/usr/bin/env bash
set -euo pipefail

# shellcheck disable=SC1091
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

load_pub_env

FEED_ID="${1:?Provide feed ID to follow, e.g. @0qSCyK3xyL71X4qKkmf84Cb2riP6OeUqxCvbP2Z6HWs=.ed25519}"

compose_pub exec -T oasis-pub sh -lc "cd /app/src/server && node /app/OASIS_PUB/tools/ssb-admin.js follow '$FEED_ID'"
