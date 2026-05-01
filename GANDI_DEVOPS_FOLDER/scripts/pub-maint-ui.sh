#!/usr/bin/env bash
set -euo pipefail

export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:${PATH:-}"

PROGRAM_NAME="$(basename "$0")"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEVOPS_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SSH_DIR="$DEVOPS_DIR/.ssh"
DEFAULT_KEY_PATH="$SSH_DIR/gandi_pub_ed25519"

REMOTE_USER="${REMOTE_USER:-debian}"
REMOTE_HOST="${REMOTE_HOST:-92.243.24.163}"
KEY_PATH="${KEY_PATH:-$DEFAULT_KEY_PATH}"
REMOTE_BIND_HOST="${REMOTE_BIND_HOST:-127.0.0.1}"
REMOTE_UI_PORT="${REMOTE_UI_PORT:-3000}"
LOCAL_TUNNEL_PORT="${LOCAL_TUNNEL_PORT:-3000}"
REMOTE_REPO_DIR="${REMOTE_REPO_DIR:-/opt/oasis-scriptorium/OASIS_PUB}"
REMOTE_DATA_ROOT="${REMOTE_DATA_ROOT:-/srv/oasis/oasis-pub}"
REMOTE_SSB_DIR="${REMOTE_SSB_DIR:-$REMOTE_DATA_ROOT/ssb-data}"
REMOTE_LOGS_DIR="${REMOTE_LOGS_DIR:-$REMOTE_DATA_ROOT/logs}"
REMOTE_CONFIG_FILE="${REMOTE_CONFIG_FILE:-$REMOTE_REPO_DIR/config/ssb/config}"
PUB_CONTAINER="${PUB_CONTAINER:-oasis-pub-scriptorium}"
MAINT_CONTAINER="${MAINT_CONTAINER:-oasis-pub-maint-ui}"
IMAGE="${IMAGE:-oasis-pub-scriptorium:latest}"
MODE="${MODE:-client}"
STOP_PUB="${STOP_PUB:-0}"
RESTART_PUB="${RESTART_PUB:-0}"

SSH_OPTS=()
ACTION="help"

usage() {
  cat <<EOF
Usage: $PROGRAM_NAME <up|down|status|logs|tunnel|help> [options]

Manage a temporary Oasis maintenance UI for the pub on the Gandi VPS.
The maintenance UI is loopback-only on the VPS and is intended for profile
maintenance tasks such as /profile/edit or /legacy over an SSH tunnel.

Commands:
  up          Start the temporary maintenance UI container.
  down        Stop and remove the maintenance UI container.
  status      Show status of the pub and maintenance containers.
  logs        Show recent maintenance UI logs.
  tunnel      Print the SSH tunnel command to open the UI locally.
  help        Show this help.

Options:
  --host HOST           Remote SSH host (default: $REMOTE_HOST)
  --user USER           Remote SSH user (default: $REMOTE_USER)
  --key PATH            SSH private key (default: $DEFAULT_KEY_PATH)
  --bind-host HOST      Remote bind host for UI port (default: $REMOTE_BIND_HOST)
  --remote-ui-port PORT Remote host port to publish the UI on (default: $REMOTE_UI_PORT)
  --local-port PORT     Suggested local port for SSH tunnel (default: $LOCAL_TUNNEL_PORT)
  --mode MODE           Container mode to run (default: $MODE)
  --stop-pub            When used with 'up', stop $PUB_CONTAINER first.
  --restart-pub         When used with 'down', start $PUB_CONTAINER again.
  --help                Show this help.

Examples:
  bash GANDI_DEVOPS_FOLDER/scripts/pub-maint-ui.sh up --stop-pub
  bash GANDI_DEVOPS_FOLDER/scripts/pub-maint-ui.sh tunnel
  bash GANDI_DEVOPS_FOLDER/scripts/pub-maint-ui.sh down --restart-pub
EOF
}

log() {
  printf '[%s] %s\n' "$PROGRAM_NAME" "$*"
}

warn() {
  printf '[%s] WARN: %s\n' "$PROGRAM_NAME" "$*" >&2
}

die() {
  printf '[%s] ERROR: %s\n' "$PROGRAM_NAME" "$*" >&2
  exit 1
}

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "Missing required command: $1"
}

parse_args() {
  if (($#)); then
    ACTION="$1"
    shift
  fi

  while (($#)); do
    case "$1" in
      --host)
        shift
        REMOTE_HOST="${1:-}"
        [[ -n "$REMOTE_HOST" ]] || die "--host requires a value"
        ;;
      --user)
        shift
        REMOTE_USER="${1:-}"
        [[ -n "$REMOTE_USER" ]] || die "--user requires a value"
        ;;
      --key)
        shift
        KEY_PATH="${1:-}"
        [[ -n "$KEY_PATH" ]] || die "--key requires a value"
        ;;
      --bind-host)
        shift
        REMOTE_BIND_HOST="${1:-}"
        [[ -n "$REMOTE_BIND_HOST" ]] || die "--bind-host requires a value"
        ;;
      --remote-ui-port)
        shift
        REMOTE_UI_PORT="${1:-}"
        [[ -n "$REMOTE_UI_PORT" ]] || die "--remote-ui-port requires a value"
        ;;
      --local-port)
        shift
        LOCAL_TUNNEL_PORT="${1:-}"
        [[ -n "$LOCAL_TUNNEL_PORT" ]] || die "--local-port requires a value"
        ;;
      --mode)
        shift
        MODE="${1:-}"
        [[ -n "$MODE" ]] || die "--mode requires a value"
        ;;
      --stop-pub)
        STOP_PUB="1"
        ;;
      --restart-pub)
        RESTART_PUB="1"
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

setup() {
  need_cmd ssh
  [[ -f "$KEY_PATH" ]] || die "SSH private key not found: $KEY_PATH"

  SSH_OPTS=(
    -i "$KEY_PATH"
    -o StrictHostKeyChecking=accept-new
    -o BatchMode=yes
  )
}

run_remote() {
  ssh "${SSH_OPTS[@]}" "$REMOTE_USER@$REMOTE_HOST" "$1"
}

remote_container_exists() {
  run_remote "docker ps -a --format '{{.Names}}' | grep -qx '$1'"
}

remote_container_running() {
  run_remote "docker ps --format '{{.Names}}' | grep -qx '$1'"
}

print_tunnel_info() {
  echo
  echo "SSH tunnel (run this from your machine):"
  echo "  ssh -i \"$KEY_PATH\" -L ${LOCAL_TUNNEL_PORT}:127.0.0.1:${REMOTE_UI_PORT} ${REMOTE_USER}@${REMOTE_HOST}"
  echo
  echo "Then open locally:"
  echo "  http://localhost:${LOCAL_TUNNEL_PORT}/profile/edit"
  echo "  http://localhost:${LOCAL_TUNNEL_PORT}/legacy"
  echo
}

cmd_up() {
  if remote_container_running "$MAINT_CONTAINER"; then
    log "$MAINT_CONTAINER is already running."
    print_tunnel_info
    return 0
  fi

  if remote_container_running "$PUB_CONTAINER"; then
    if [[ "$STOP_PUB" != "1" ]]; then
      die "$PUB_CONTAINER is still running. Re-run with --stop-pub or stop it manually first to avoid two processes writing the same .ssb data."
    fi
    log "Stopping $PUB_CONTAINER before starting maintenance UI."
    run_remote "docker stop '$PUB_CONTAINER' >/dev/null"
  fi

  if remote_container_exists "$MAINT_CONTAINER"; then
    log "Removing previous $MAINT_CONTAINER container."
    run_remote "docker rm -f '$MAINT_CONTAINER' >/dev/null"
  fi

  log "Starting temporary maintenance UI container on ${REMOTE_BIND_HOST}:${REMOTE_UI_PORT}."
  run_remote "docker run -d --name '$MAINT_CONTAINER' \
    -e NODE_ENV='production' \
    -e OASIS_SKIP_AI_MODEL='true' \
    -e OASIS_SERVER_CONFIG_OVERRIDE='/home/oasis/.ssb/config' \
    -e HOME='/home/oasis' \
    -e SSB_PATH='/home/oasis/.ssb' \
    -p '${REMOTE_BIND_HOST}:${REMOTE_UI_PORT}:3000' \
    -v '$REMOTE_SSB_DIR:/home/oasis/.ssb' \
    -v '$REMOTE_LOGS_DIR:/app/logs' \
    -v '$REMOTE_CONFIG_FILE:/home/oasis/.ssb/config:ro' \
    '$IMAGE' '$MODE' >/dev/null"

  print_tunnel_info
}

cmd_down() {
  if remote_container_exists "$MAINT_CONTAINER"; then
    log "Stopping and removing $MAINT_CONTAINER."
    run_remote "docker rm -f '$MAINT_CONTAINER' >/dev/null"
  else
    warn "$MAINT_CONTAINER does not exist."
  fi

  if [[ "$RESTART_PUB" == "1" ]]; then
    log "Starting $PUB_CONTAINER again."
    run_remote "docker start '$PUB_CONTAINER' >/dev/null"
  fi
}

cmd_status() {
  run_remote "docker ps -a --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}' | grep -E '^(NAMES|$PUB_CONTAINER|$MAINT_CONTAINER)' || true"
  print_tunnel_info
}

cmd_logs() {
  if ! remote_container_exists "$MAINT_CONTAINER"; then
    die "$MAINT_CONTAINER does not exist."
  fi
  run_remote "docker logs --tail 200 '$MAINT_CONTAINER'"
}

main() {
  parse_args "$@"
  setup

  case "$ACTION" in
    up)
      cmd_up
      ;;
    down)
      cmd_down
      ;;
    status)
      cmd_status
      ;;
    logs)
      cmd_logs
      ;;
    tunnel)
      print_tunnel_info
      ;;
    help|--help|-h)
      usage
      ;;
    *)
      die "Unknown action: $ACTION"
      ;;
  esac
}

main "$@"
