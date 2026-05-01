#!/usr/bin/env bash
set -euo pipefail

NAME="${1:-PUB OASIS SCRIPTORIUM}"
DESCRIPTION="${2:-Nodo pub de Scriptorium para la red Oasis.}"
# shellcheck disable=SC1091
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

require_env_file
compose_pub exec -T oasis-pub sh -lc "cd /app/src/server && node /app/OASIS_PUB/tools/ssb-admin.js publish-about '$NAME' '$DESCRIPTION'"
