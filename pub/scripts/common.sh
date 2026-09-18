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

is_absolute_pub_path() {
  local raw_path="$1"
  [[ "$raw_path" = /* ]] || [[ "$raw_path" =~ ^[A-Za-z]:[/\\] ]]
}

is_canonical_vps_layout() {
  [[ "$PUB_DIR" = "/opt/oasis-scriptorium/pub" ]]
}

require_vps_persistent_path() {
  local var_name="$1"
  local raw_path="$2"

  if ! is_absolute_pub_path "$raw_path"; then
    echo "Invalid $var_name for canonical VPS deploy: '$raw_path'"
    echo "Expected an absolute path under /srv/oasis/."
    echo "Create $PUB_ENV_PATH from $PUB_DIR/.env.vps.example before running deploy."
    exit 1
  fi

  if [[ "$raw_path" != /srv/oasis/* ]]; then
    echo "Invalid $var_name for canonical VPS deploy: '$raw_path'"
    echo "Expected a path rooted under /srv/oasis/."
    echo "Create $PUB_ENV_PATH from $PUB_DIR/.env.vps.example before running deploy."
    exit 1
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

# hub-wallet (WP-O102): rutas opcionales. Solo cuentan si la variable está definida y no vacía
# (un host sin wallet no debe fallar ni ver directorios creados de más).
PUB_WALLET_DIR_VARS=(
  OASIS_ECOIN_DATA_DIR
  OASIS_WALLET_BOT_SSB_DATA_DIR
  OASIS_WALLET_BOT_LOGS_DIR
  OASIS_WALLET_BOT_BANKING_DIR
)

validate_vps_persistent_paths() {
  if ! is_canonical_vps_layout; then
    return 0
  fi

  load_pub_env
  require_vps_persistent_path "OASIS_PUB_SSB_DATA_DIR" "${OASIS_PUB_SSB_DATA_DIR:-../volumes-dev/oasis-pub/ssb-data}"
  require_vps_persistent_path "OASIS_PUB_LOGS_DIR" "${OASIS_PUB_LOGS_DIR:-../volumes-dev/oasis-pub/logs}"
  require_vps_persistent_path "OASIS_PUB_CADDY_DATA_DIR" "${OASIS_PUB_CADDY_DATA_DIR:-../volumes-dev/oasis-pub/caddy-data}"
  require_vps_persistent_path "OASIS_PUB_CADDY_CONFIG_DIR" "${OASIS_PUB_CADDY_CONFIG_DIR:-../volumes-dev/oasis-pub/caddy-config}"
  require_vps_persistent_path "OASIS_PUB_TEATRO_DIR" "${OASIS_PUB_TEATRO_DIR:-../volumes-dev/teatro}"
  require_vps_persistent_path "OASIS_HUB_SSB_DATA_DIR" "${OASIS_HUB_SSB_DATA_DIR:-../volumes-dev/oasis-hub/ssb-data}"
  require_vps_persistent_path "OASIS_HUB_LOGS_DIR" "${OASIS_HUB_LOGS_DIR:-../volumes-dev/oasis-hub/logs}"
  require_vps_persistent_path "OASIS_HUB_HTTP_CACHE_DIR" "${OASIS_HUB_HTTP_CACHE_DIR:-../volumes-dev/oasis-hub/http-cache}"

  local wallet_var
  for wallet_var in "${PUB_WALLET_DIR_VARS[@]}" OASIS_WALLET_BOT_OASIS_CONFIG_FILE; do
    if [ -n "${!wallet_var:-}" ]; then
      require_vps_persistent_path "$wallet_var" "${!wallet_var}"
    fi
  done
}

ensure_runtime_dirs() {
  load_pub_env
  mkdir_pub_path "${OASIS_PUB_SSB_DATA_DIR:-../volumes-dev/oasis-pub/ssb-data}"
  mkdir_pub_path "${OASIS_PUB_LOGS_DIR:-../volumes-dev/oasis-pub/logs}"
  mkdir_pub_path "${OASIS_PUB_CADDY_DATA_DIR:-../volumes-dev/oasis-pub/caddy-data}"
  mkdir_pub_path "${OASIS_PUB_CADDY_CONFIG_DIR:-../volumes-dev/oasis-pub/caddy-config}"
  mkdir_pub_path "${OASIS_PUB_TEATRO_DIR:-../volumes-dev/teatro}"
  mkdir_pub_path "${OASIS_HUB_SSB_DATA_DIR:-../volumes-dev/oasis-hub/ssb-data}"
  mkdir_pub_path "${OASIS_HUB_LOGS_DIR:-../volumes-dev/oasis-hub/logs}"
  mkdir_pub_path "${OASIS_HUB_HTTP_CACHE_DIR:-../volumes-dev/oasis-hub/http-cache}"

  local wallet_var
  for wallet_var in "${PUB_WALLET_DIR_VARS[@]}"; do
    if [ -n "${!wallet_var:-}" ]; then
      mkdir_pub_path "${!wallet_var}"
    fi
  done
  # El oasis-config.json del bot lo escribe render-wallet-bot-config.sh: aquí solo su directorio padre.
  if [ -n "${OASIS_WALLET_BOT_OASIS_CONFIG_FILE:-}" ]; then
    mkdir_pub_path "$(dirname "$OASIS_WALLET_BOT_OASIS_CONFIG_FILE")"
  fi
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
