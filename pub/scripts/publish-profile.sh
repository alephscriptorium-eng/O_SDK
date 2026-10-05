#!/usr/bin/env bash
set -euo pipefail

# El nombre es obligatorio: un `about` no se retira, y un valor por defecto republicaría un nombre viejo.
NAME="${1:?uso: publish-profile.sh <nombre> [descripción]}"
DESCRIPTION="${2:-Nodo pub de Scriptorium para la red Oasis.}"
# shellcheck disable=SC1091
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

require_env_file
compose_pub exec -T oasis-pub sh -lc "cd /app/src/server && node /app/pub/tools/ssb-admin.js publish-about '$NAME' '$DESCRIPTION'"
