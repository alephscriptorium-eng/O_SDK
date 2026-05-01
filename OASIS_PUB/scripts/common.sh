#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PUB_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PUB_ENV_FILE="${OASIS_PUB_ENV_FILE:-.env}"
PUB_ENV_TEMPLATE="${OASIS_PUB_ENV_TEMPLATE:-.env.example}"
PUB_COMPOSE_FILE="${OASIS_PUB_COMPOSE_FILE:-docker-compose.pub.yml}"
PUB_ENV_PATH="$PUB_DIR/$PUB_ENV_FILE"
PUB_ENV_TEMPLATE_PATH="$PUB_DIR/$PUB_ENV_TEMPLATE"
PUB_COMPOSE_PATH="$PUB_DIR/$PUB_COMPOSE_FILE"

compose_pub() {
  (
    cd "$PUB_DIR"
    docker compose --env-file "$PUB_ENV_PATH" -f "$PUB_COMPOSE_PATH" "$@"
  )
}

mkdir_pub_path() {
  local raw_path="$1"
  if [[ "$raw_path" = /* ]] || [[ "$raw_path" =~ ^[A-Za-z]:[/\\] ]]; then
    mkdir -p "$raw_path"
  else
    (
      cd "$PUB_DIR"
      mkdir -p "$raw_path"
    )
  fi
}

require_env_file() {
  if [ ! -f "$PUB_ENV_PATH" ]; then
    echo "Missing env file: $PUB_ENV_PATH"
    echo "Template available: $PUB_ENV_TEMPLATE_PATH"
    exit 1
  fi
}

load_pub_env() {
  require_env_file
  set -a
  # shellcheck disable=SC1090
  . "$PUB_ENV_PATH"
  set +a
}

ensure_runtime_dirs() {
  load_pub_env
  mkdir_pub_path "${OASIS_PUB_SSB_DATA_DIR:-../volumes-dev/oasis-pub/ssb-data}"
  mkdir_pub_path "${OASIS_PUB_LOGS_DIR:-../volumes-dev/oasis-pub/logs}"
  mkdir_pub_path "${OASIS_PUB_CADDY_DATA_DIR:-../volumes-dev/oasis-pub/caddy-data}"
  mkdir_pub_path "${OASIS_PUB_CADDY_CONFIG_DIR:-../volumes-dev/oasis-pub/caddy-config}"
}

ensure_env_from_template() {
  if [ -f "$PUB_ENV_PATH" ]; then
    return 0
  fi

  if [ ! -f "$PUB_ENV_TEMPLATE_PATH" ]; then
    echo "Missing env template: $PUB_ENV_TEMPLATE_PATH"
    exit 1
  fi

  cp "$PUB_ENV_TEMPLATE_PATH" "$PUB_ENV_PATH"
  echo "Created $PUB_ENV_PATH from $PUB_ENV_TEMPLATE_PATH"
}
