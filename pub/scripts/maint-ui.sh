#!/usr/bin/env bash
set -euo pipefail

PROGRAM_NAME="$(basename "$0")"
# shellcheck disable=SC1091
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

PUB_CONTAINER="${PUB_CONTAINER:-oasis-pub-scriptorium}"
MAINT_CONTAINER="${MAINT_CONTAINER:-oasis-pub-maint-ui-local}"
IMAGE="${IMAGE:-oasis-pub-scriptorium:latest}"
MODE="${MODE:-client}"
STOP_PUB="${STOP_PUB:-0}"
RESTART_PUB="${RESTART_PUB:-0}"
BIND_HOST="${OASIS_PUB_MAINT_UI_BIND:-127.0.0.1}"
UI_PORT="${OASIS_PUB_MAINT_UI_PORT:-3001}"

ACTION="help"

usage() {
  cat <<EOF
Usage: $PROGRAM_NAME <up|down|status|logs|urls|help> [options]

Temporary Oasis GUI for the local pub identity (avatar, /profile/edit, /legacy).
Uses the same ssb-data as the pub stack; do not run both writers at once.

Commands:
  up       Start maintenance UI (requires --stop-pub if pub container is running).
  down     Stop and remove the maintenance UI container.
  status   Show pub + maintenance container status.
  logs     Tail maintenance UI logs.
  urls     Print local URLs for profile edit.
  help     Show this help.

Options:
  --stop-pub      Stop $PUB_CONTAINER before starting maintenance UI.
  --restart-pub   Start $PUB_CONTAINER again after 'down'.
  --ui-port PORT  Host port for the UI (default: $UI_PORT).
  --mode MODE     Entrypoint mode (default: $MODE).
  --help          Show this help.

Examples (from BlockchainComPort/):
  npm run pub:local:maint-ui:up
  npm run pub:local:maint-ui:urls
  npm run pub:local:maint-ui:down

Notes:
  - Default UI port is 3001 so oasis-client on :3000 can stay running.
  - You must stop the pub SSB container (--stop-pub) before 'up'; the Oasis
    client (oasis-client) does NOT need to stop unless you want port 3000.
EOF
}

log() { printf '[%s] %s\n' "$PROGRAM_NAME" "$*"; }
warn() { printf '[%s] WARN: %s\n' "$PROGRAM_NAME" "$*" >&2; }
die() { printf '[%s] ERROR: %s\n' "$PROGRAM_NAME" "$*" >&2; exit 1; }

# Git Bash on Windows rewrites /home/oasis/.ssb unless disabled — breaks volume mounts.
docker_env() {
  if [[ "$(uname -s 2>/dev/null)" == MINGW* ]] || [[ "$(uname -s 2>/dev/null)" == MSYS* ]]; then
    MSYS_NO_PATHCONV=1
    MSYS2_ARG_CONV_EXCL='*'
    export MSYS_NO_PATHCONV MSYS2_ARG_CONV_EXCL
  fi
}

abs_pub_path() {
  local raw="$1"
  if [[ "$raw" = /* ]] || [[ "$raw" =~ ^[A-Za-z]:[/\\] ]]; then
    printf '%s' "$raw"
    return 0
  fi
  (
    cd "$PUB_DIR"
    if [[ -e "$raw" && ! -d "$raw" ]]; then
      dirname "$(cd "$(dirname "$raw")" && pwd)/$(basename "$raw")"
    else
      mkdir -p "$raw"
      cd "$raw"
      pwd
    fi
  )
}

container_running() {
  docker ps --format '{{.Names}}' | grep -qx "$1"
}

container_exists() {
  docker ps -a --format '{{.Names}}' | grep -qx "$1"
}

port_busy() {
  local port="$1"
  if command -v ss >/dev/null 2>&1; then
    ss -ltn 2>/dev/null | grep -q ":${port} "
    return $?
  fi
  if command -v netstat >/dev/null 2>&1; then
    netstat -ltn 2>/dev/null | grep -q ":${port} "
    return $?
  fi
  return 1
}

print_urls() {
  echo
  echo "Open in your browser:"
  echo "  http://${BIND_HOST}:${UI_PORT}/profile/edit"
  echo "  http://${BIND_HOST}:${UI_PORT}/legacy"
  echo
  if [ "$UI_PORT" = "3000" ] && container_running "oasis-client"; then
    warn "Port 3000 is also used by oasis-client. Stop the client or use --ui-port 3001."
  fi
}

parse_args() {
  if (($#)); then
    ACTION="$1"
    shift
  fi
  while (($#)); do
    case "$1" in
      --stop-pub) STOP_PUB="1" ;;
      --restart-pub) RESTART_PUB="1" ;;
      --ui-port)
        shift
        UI_PORT="${1:-}"
        [[ -n "$UI_PORT" ]] || die "--ui-port requires a value"
        ;;
      --mode)
        shift
        MODE="${1:-}"
        [[ -n "$MODE" ]] || die "--mode requires a value"
        ;;
      --help|-h)
        usage
        exit 0
        ;;
      *)
        die "Unknown option: $1"
        ;;
    esac
    shift
  done
}

cmd_up() {
  load_pub_env
  ensure_runtime_dirs

  if container_running "$MAINT_CONTAINER"; then
    log "$MAINT_CONTAINER is already running."
    print_urls
    return 0
  fi

  if container_running "$PUB_CONTAINER"; then
    if [[ "$STOP_PUB" != "1" ]]; then
      die "$PUB_CONTAINER is still running. Re-run with --stop-pub (or npm run pub:local:maint-ui:up)."
    fi
    log "Stopping $PUB_CONTAINER before starting maintenance UI."
    compose_pub stop oasis-pub >/dev/null
  fi

  if container_exists "$MAINT_CONTAINER"; then
    log "Removing previous $MAINT_CONTAINER container."
    docker rm -f "$MAINT_CONTAINER" >/dev/null
  fi

  if port_busy "$UI_PORT"; then
    die "Port ${UI_PORT} is already in use. Stop oasis-client or use --ui-port 3001."
  fi

  local ssb_dir logs_dir config_file
  ssb_dir="$(abs_pub_path "${OASIS_PUB_SSB_DATA_DIR:-../volumes-dev/oasis-pub/ssb-data}")"
  logs_dir="$(abs_pub_path "${OASIS_PUB_LOGS_DIR:-../volumes-dev/oasis-pub/logs}")"
  config_file="${OASIS_PUB_SSB_CONFIG_FILE:-./config/ssb/config.local}"
  if [[ "$config_file" = /* ]] || [[ "$config_file" =~ ^[A-Za-z]:[/\\] ]]; then
    :
  else
    config_file="$(cd "$PUB_DIR" && pwd)/${config_file#./}"
  fi

  [[ -f "$ssb_dir/secret" ]] || die "Pub identity not found in $ssb_dir — run npm run pub:local:up first."

  if [[ ! -s "$ssb_dir/config" ]] && [[ -f "$config_file" ]]; then
    log "Seeding empty $ssb_dir/config from $(basename "$config_file")."
    cp "$config_file" "$ssb_dir/config"
  fi

  docker_env
  log "Starting maintenance UI on ${BIND_HOST}:${UI_PORT} (mode=$MODE)."
  log "Mount ssb-data: $ssb_dir"
  log "Mount config:   $config_file"
  docker run -d --name "$MAINT_CONTAINER" \
    -e NODE_ENV=production \
    -e OASIS_SKIP_AI_MODEL=true \
    -e OASIS_SERVER_CONFIG_OVERRIDE=/home/oasis/.ssb/config \
    -e HOME=/home/oasis \
    -e SSB_PATH=/home/oasis/.ssb \
    -p "${BIND_HOST}:${UI_PORT}:3000" \
    -v "${ssb_dir}:/home/oasis/.ssb" \
    -v "${logs_dir}:/app/logs" \
    -v "${config_file}:/home/oasis/.ssb/config:ro" \
    "$IMAGE" "$MODE" >/dev/null

  log "Waiting for UI to become reachable..."
  local i code
  for i in $(seq 1 30); do
    code="$(curl -sS -o /dev/null -w '%{http_code}' "http://${BIND_HOST}:${UI_PORT}/" 2>/dev/null || true)"
    case "$code" in
      200|301|302|401|403) break ;;
    esac
    sleep 2
  done

  if docker logs "$MAINT_CONTAINER" 2>&1 | grep -q 'Creando configuración SSB inicial'; then
    warn "El entrypoint generó config nueva — revisa mounts (¿Git Bash / Windows?)."
  fi
  local pub_id
  pub_id="$(docker logs "$MAINT_CONTAINER" 2>&1 | sed -n 's/.*Oasis ID:.*\(\@[^[]*\).*/\1/p' | tail -1 | tr -d '[:space:]' | sed 's/\x1b\[[0-9;]*m//g')"
  if [[ -n "$pub_id" ]]; then
    log "Oasis ID en UI: $pub_id"
  fi

  print_urls
}

cmd_down() {
  if container_exists "$MAINT_CONTAINER"; then
    log "Stopping and removing $MAINT_CONTAINER."
    docker rm -f "$MAINT_CONTAINER" >/dev/null
  else
    warn "$MAINT_CONTAINER does not exist."
  fi

  if [[ "$RESTART_PUB" == "1" ]]; then
    log "Starting pub stack service oasis-pub again."
    compose_pub start oasis-pub >/dev/null
  fi
}

cmd_status() {
  docker ps -a --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}' \
    | grep -E "^(NAMES|${PUB_CONTAINER}|${MAINT_CONTAINER}|oasis-pub-)" || true
  print_urls
}

cmd_logs() {
  container_exists "$MAINT_CONTAINER" || die "$MAINT_CONTAINER does not exist."
  docker logs --tail 200 -f "$MAINT_CONTAINER"
}

main() {
  parse_args "$@"
  case "$ACTION" in
    up) cmd_up ;;
    down) cmd_down ;;
    status) cmd_status ;;
    logs) cmd_logs ;;
    urls) print_urls ;;
    help|--help|-h) usage ;;
    *) die "Unknown action: $ACTION (try: up|down|status|logs|urls)" ;;
  esac
}

main "$@"
