#!/usr/bin/env bash
set -euo pipefail

export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:${PATH:-}"

PROGRAM_NAME="$(basename "$0")"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEVOPS_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SSH_DIR="$DEVOPS_DIR/.ssh"
DEFAULT_KEY_PATH="$SSH_DIR/gandi_pub_ed25519"
LOG_DIR="$DEVOPS_DIR/logs"

REMOTE_USER="${REMOTE_USER:-debian}"
REMOTE_HOST="${REMOTE_HOST:-92.243.24.163}"
KEY_PATH="${KEY_PATH:-$DEFAULT_KEY_PATH}"
REMOTE_REPO_DIR="${REMOTE_REPO_DIR:-/opt/oasis-scriptorium/OASIS_PUB}"
REMOTE_ENV_FILE="${REMOTE_ENV_FILE:-.env.prod}"
PUB_CONTAINER="${PUB_CONTAINER:-oasis-pub-scriptorium}"

# Oasis network SHS cap — must match remote config before any SSB publish.
# Verified in: OASIS_PUB/config/ssb/config, src/configs/server-config.json,
# and GANDI_DEVOPS_FOLDER/backups/oasis-pub/20260501T185202Z/identity/config
EXPECTED_SHS="zTmidAb7t+tKi7W93FIHbOvlbd936x6G/vm8e8Td//A="

# solarnethub.com "La Plaza" — validated in docs/PUB/deploy.md and
# src/configs/snh-invite-code.json
SNH_FEED="@mGrevRCSX4E5dLgmflWBc50Qkn/1RXUAtDaGHOJ8xB4=.ed25519"

PUB_HOST_OVERRIDE=""
PUB_PORT_OVERRIDE=""
FOLLOW_FEED=""
DRY_RUN=0
SKIP_CONFIRM=0
ACTION="help"
SSH_OPTS=()

# ---------------------------------------------------------------------------
# Usage
# ---------------------------------------------------------------------------

usage() {
  cat <<EOF
Usage: $PROGRAM_NAME <status|announce|follow|follow-solarnethub|help> [options]

Manage federation of the Oasis PUB on the Gandi VPS.
All publish commands write IMMUTABLE SSB messages — review carefully before confirming.

Commands:
  status               Show pub identity, caps.shs, and container status (no publish).
  announce             Publish the pub's own address to the SSB network.
  follow <feedId>      Follow another pub's feed (publish a contact message).
  follow-solarnethub   Follow solarnethub.com "La Plaza" ($SNH_FEED).
  help                 Show this help.

Options:
  --host HOST           Remote SSH host (default: $REMOTE_HOST)
  --user USER           Remote SSH user (default: $REMOTE_USER)
  --key PATH            SSH private key (default: $DEFAULT_KEY_PATH)
  --pub-host HOST       Override pub SSB hostname for announce.
  --pub-port PORT       Override pub SSB port for announce.
  --remote-env FILE     Remote env filename in REMOTE_REPO_DIR (default: .env.prod).
  --dry-run             Preview what would be published without writing to SSB.
  --yes                 Skip interactive confirmation prompt.
  --help                Show this help.

Recommended order:
  1. status               -- verify identity, caps.shs, and container
  2. announce             -- publish pub address
  3. follow-solarnethub   -- start replication with the Oasis seed pub

Examples:
  bash GANDI_DEVOPS_FOLDER/scripts/pub-federation.sh status
  bash GANDI_DEVOPS_FOLDER/scripts/pub-federation.sh announce --dry-run
  bash GANDI_DEVOPS_FOLDER/scripts/pub-federation.sh announce --yes
  bash GANDI_DEVOPS_FOLDER/scripts/pub-federation.sh follow-solarnethub --dry-run
  bash GANDI_DEVOPS_FOLDER/scripts/pub-federation.sh follow-solarnethub --yes
  bash GANDI_DEVOPS_FOLDER/scripts/pub-federation.sh follow @feedId=.ed25519
EOF
}

# ---------------------------------------------------------------------------
# Logging helpers
# ---------------------------------------------------------------------------

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

log_op() {
  local ts="$1" action="$2" detail="$3" result="$4"
  printf '%s  action=%-22s  detail=%s  result=%s\n' \
    "$ts" "$action" "$detail" "$result" >> "$LOG_DIR/federation.log"
}

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------

parse_args() {
  if (($#)); then ACTION="$1"; shift; fi

  # 'follow' accepts a positional feed ID before any flags
  if [[ "$ACTION" == "follow" ]] && (($#)) && [[ "${1:-}" != --* ]]; then
    FOLLOW_FEED="$1"
    shift
  fi

  while (($#)); do
    case "$1" in
      --host)      shift; REMOTE_HOST="${1:?--host requires a value}" ;;
      --user)      shift; REMOTE_USER="${1:?--user requires a value}" ;;
      --key)       shift; KEY_PATH="${1:?--key requires a value}" ;;
      --pub-host)  shift; PUB_HOST_OVERRIDE="${1:?--pub-host requires a value}" ;;
      --pub-port)    shift; PUB_PORT_OVERRIDE="${1:?--pub-port requires a value}" ;;
      --remote-env) shift; REMOTE_ENV_FILE="${1:?--remote-env requires a value}" ;;
      --dry-run)    DRY_RUN=1 ;;
      --yes)       SKIP_CONFIRM=1 ;;
      --help|-h)   usage; exit 0 ;;
      *)           die "Unknown option: $1" ;;
    esac
    shift
  done
}

# ---------------------------------------------------------------------------
# Setup
# ---------------------------------------------------------------------------

setup() {
  need_cmd ssh
  [[ -f "$KEY_PATH" ]] || die "SSH private key not found: $KEY_PATH"
  SSH_OPTS=(
    -i "$KEY_PATH"
    -o StrictHostKeyChecking=accept-new
    -o BatchMode=yes
  )
  mkdir -p "$LOG_DIR"
}

# ---------------------------------------------------------------------------
# Remote execution
# ---------------------------------------------------------------------------

run_remote() {
  ssh "${SSH_OPTS[@]}" "$REMOTE_USER@$REMOTE_HOST" "$1"
}

# ---------------------------------------------------------------------------
# Preflight: non-mutating checks — must pass before any SSB publish
# ---------------------------------------------------------------------------

preflight() {
  log "[preflight] SSH: $REMOTE_USER@$REMOTE_HOST ..."
  run_remote "true" 2>/dev/null \
    || die "SSH connection failed to $REMOTE_USER@$REMOTE_HOST"

  log "[preflight] Remote repo: $REMOTE_REPO_DIR ..."
  run_remote "test -d '$REMOTE_REPO_DIR'" \
    || die "Remote repo not found: $REMOTE_REPO_DIR"

  log "[preflight] Remote env file: $REMOTE_REPO_DIR/$REMOTE_ENV_FILE ..."
  run_remote "test -f '$REMOTE_REPO_DIR/$REMOTE_ENV_FILE'" \
    || die "Remote env not found: $REMOTE_REPO_DIR/$REMOTE_ENV_FILE — try --remote-env .env or run deploy first"

  log "[preflight] Container $PUB_CONTAINER ..."
  run_remote "docker ps --format '{{.Names}}' | grep -qx '$PUB_CONTAINER'" \
    || die "Container $PUB_CONTAINER is not running — start the pub before federating"

  log "[preflight] Verifying caps.shs ..."
  local remote_shs
  remote_shs="$(run_remote "awk -F'\"' '/\"shs\"/{print \$4;exit}' '$REMOTE_REPO_DIR/config/ssb/config'")"
  if [[ "$remote_shs" != "$EXPECTED_SHS" ]]; then
    die "caps.shs MISMATCH — aborting to avoid publishing on the wrong network.
  Expected : $EXPECTED_SHS
  Got      : ${remote_shs:-EMPTY}
  Fix      : ensure $REMOTE_REPO_DIR/config/ssb/config has the correct Oasis SHS."
  fi
  log "[preflight] caps.shs OK ($remote_shs)"
}

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

get_whoami() {
  run_remote "cd '$REMOTE_REPO_DIR' && bash scripts/env-run.sh '$REMOTE_ENV_FILE' whoami.sh 2>/dev/null" \
    | grep '"id"' | head -1 \
    | sed 's/.*"id"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/'
}

confirm_or_abort() {
  local prompt="$1"
  if [[ "$SKIP_CONFIRM" == "1" ]]; then return 0; fi
  printf '\n%s\nConfirm? [y/N] ' "$prompt"
  local answer
  read -r answer
  [[ "$answer" == [yY] ]] || { log "Aborted by user."; exit 0; }
}

# ---------------------------------------------------------------------------
# Commands
# ---------------------------------------------------------------------------

cmd_status() {
  preflight

  local feed_id container_info
  feed_id="$(get_whoami 2>/dev/null || echo '(unable to reach SSB)')"
  container_info="$(run_remote "docker ps --format '{{.Names}} | {{.Status}}' | grep '$PUB_CONTAINER'" 2>/dev/null \
    || echo 'not found')"

  echo
  echo "=== PUB Federation Status ==="
  printf '  %-14s %s\n'  "SSH host:"   "$REMOTE_USER@$REMOTE_HOST"
  printf '  %-14s %s\n'  "Repo dir:"   "$REMOTE_REPO_DIR"
  printf '  %-14s %s\n'  "Container:"  "$container_info"
  printf '  %-14s %s  [OK — Oasis network]\n' "caps.shs:"  "$EXPECTED_SHS"
  printf '  %-14s %s\n'  "Feed ID:"    "$feed_id"
  echo
}

cmd_announce() {
  preflight

  local feed_id host port
  feed_id="$(get_whoami)"
  [[ -n "$feed_id" ]] \
    || die "Could not read pub identity via whoami — is SSB running inside the container?"

  # Resolve host/port for preview; announce-pub.sh will re-read from .env if not overridden.
  host="${PUB_HOST_OVERRIDE:-}"
  if [[ -z "$host" ]]; then
    host="$(run_remote "grep -m1 '^OASIS_PUB_HOST=' '$REMOTE_REPO_DIR/$REMOTE_ENV_FILE' 2>/dev/null" \
      | cut -d= -f2- | tr -d '"' | tr -d "'")"
    [[ -n "$host" ]] || host="pub.escrivivir.co"
  fi

  port="${PUB_PORT_OVERRIDE:-}"
  if [[ -z "$port" ]]; then
    port="$(run_remote "grep -m1 '^OASIS_PUB_SSB_PORT=' '$REMOTE_REPO_DIR/$REMOTE_ENV_FILE' 2>/dev/null" \
      | cut -d= -f2- | tr -d '"' | tr -d "'")"
    [[ -n "$port" ]] || port="8008"
  fi

  echo
  echo "=== Announce PUB ==="
  echo "  This will publish the following IMMUTABLE SSB message:"
  echo "  {"
  echo "    \"type\": \"pub\","
  echo "    \"address\": {"
  echo "      \"key\":  \"$feed_id\","
  echo "      \"host\": \"$host\","
  echo "      \"port\": $port"
  echo "    }"
  echo "  }"
  echo
  warn "SSB messages are immutable — once published they cannot be deleted."
  echo

  if [[ "$DRY_RUN" == "1" ]]; then
    log "[dry-run] announce | host=$host port=$port feed=$feed_id"
    log "Dry run complete — nothing published."
    return 0
  fi

  confirm_or_abort "Publish announce message for $host:$port ?"

  local ts output
  ts="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
  output="$(run_remote \
    "cd '$REMOTE_REPO_DIR' && bash scripts/env-run.sh '$REMOTE_ENV_FILE' announce-pub.sh '$PUB_HOST_OVERRIDE' '$PUB_PORT_OVERRIDE' 2>&1")"
  echo "$output"
  log_op "$ts" "announce" "host=$host port=$port feed=$feed_id" \
    "$(printf '%s' "$output" | tr '\n' '|')"
  log "Done. Result logged to $LOG_DIR/federation.log"
}

cmd_follow() {
  local feed_id="$1"
  [[ "$feed_id" =~ ^@.+=\.ed25519$ ]] \
    || die "Invalid feed ID: '$feed_id'  (expected format: @...=.ed25519)"

  preflight

  echo
  echo "=== Follow PUB ==="
  echo "  This will publish the following IMMUTABLE SSB message:"
  echo "  {"
  echo "    \"type\":      \"contact\","
  echo "    \"contact\":   \"$feed_id\","
  echo "    \"following\": true"
  echo "  }"
  echo
  warn "SSB messages are immutable — once published they cannot be deleted."
  echo

  if [[ "$DRY_RUN" == "1" ]]; then
    log "[dry-run] follow | feed=$feed_id"
    log "Dry run complete — nothing published."
    return 0
  fi

  confirm_or_abort "Publish follow message for $feed_id ?"

  local ts output
  ts="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
  output="$(run_remote \
    "cd '$REMOTE_REPO_DIR' && bash scripts/env-run.sh '$REMOTE_ENV_FILE' follow-pub.sh '$feed_id' 2>&1")"
  echo "$output"
  log_op "$ts" "follow" "feed=$feed_id" \
    "$(printf '%s' "$output" | tr '\n' '|')"
  log "Done. Result logged to $LOG_DIR/federation.log"
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

main() {
  parse_args "$@"
  setup

  case "$ACTION" in
    status)
      cmd_status
      ;;
    announce)
      cmd_announce
      ;;
    follow)
      [[ -n "$FOLLOW_FEED" ]] \
        || die "'follow' requires a feed ID: $PROGRAM_NAME follow <@feedId=.ed25519>"
      cmd_follow "$FOLLOW_FEED"
      ;;
    follow-solarnethub)
      cmd_follow "$SNH_FEED"
      ;;
    help|--help|-h)
      usage
      ;;
    *)
      die "Unknown action: '$ACTION'. Run '$PROGRAM_NAME help' for usage."
      ;;
  esac
}

main "$@"
