#!/usr/bin/env bash
set -euo pipefail

ENV_FILE="${1:?Provide env file name, e.g. .env.local}"
SCRIPT_NAME="${2:?Provide target script name}"
shift 2

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export OASIS_PUB_ENV_FILE="$ENV_FILE"

if [ -z "${OASIS_PUB_ENV_TEMPLATE:-}" ] && [ "$ENV_FILE" = ".env.local" ]; then
  export OASIS_PUB_ENV_TEMPLATE=".env.local.example"
fi

exec bash "$SCRIPT_DIR/$SCRIPT_NAME" "$@"
