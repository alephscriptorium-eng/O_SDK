#!/usr/bin/env bash
set -euo pipefail

export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:${PATH:-}"

PROGRAM_NAME="$(basename "$0")"
EXPECTED_DEBIAN_MAJOR="${EXPECTED_DEBIAN_MAJOR:-13}"
MOUNT_POINT="${MOUNT_POINT:-/srv/oasis}"
REPO_DIR="${REPO_DIR:-/opt/oasis-scriptorium}"
DATA_ROOT="${DATA_ROOT:-}"
OWNER_USER="${OWNER_USER:-}"
STRICT_SSH="${STRICT_SSH:-0}"
SUDO=()
PASS_COUNT=0
WARN_COUNT=0
FAIL_COUNT=0

usage() {
  cat <<EOF
Usage: $PROGRAM_NAME [options]

Verify the Debian 13 base expected for PUB OASIS SCRIPTORIUM.

Options:
  --mount-point PATH          Mount point to validate (default: $MOUNT_POINT).
  --repo-dir PATH             Repo directory to validate (default: $REPO_DIR).
  --data-root PATH            Persistent data root (default: <mount-point>/oasis-pub).
  --owner USER                Expected owner of repo/data directories.
  --strict-ssh                Fail if SSH password auth or root login are still enabled.
  --help                      Show this help.
EOF
}

pass() {
  PASS_COUNT=$((PASS_COUNT + 1))
  printf '[%s] PASS: %s\n' "$PROGRAM_NAME" "$*"
}

warn() {
  WARN_COUNT=$((WARN_COUNT + 1))
  printf '[%s] WARN: %s\n' "$PROGRAM_NAME" "$*" >&2
}

fail() {
  FAIL_COUNT=$((FAIL_COUNT + 1))
  printf '[%s] FAIL: %s\n' "$PROGRAM_NAME" "$*" >&2
}

run_root() {
  if ((${#SUDO[@]})); then
    "${SUDO[@]}" "$@"
  else
    "$@"
  fi
}

parse_args() {
  while (($#)); do
    case "$1" in
      --mount-point)
        shift
        MOUNT_POINT="${1:-}"
        [[ -n "$MOUNT_POINT" ]] || {
          printf '[%s] ERROR: --mount-point requires a value\n' "$PROGRAM_NAME" >&2
          exit 1
        }
        ;;
      --repo-dir)
        shift
        REPO_DIR="${1:-}"
        [[ -n "$REPO_DIR" ]] || {
          printf '[%s] ERROR: --repo-dir requires a value\n' "$PROGRAM_NAME" >&2
          exit 1
        }
        ;;
      --data-root)
        shift
        DATA_ROOT="${1:-}"
        [[ -n "$DATA_ROOT" ]] || {
          printf '[%s] ERROR: --data-root requires a value\n' "$PROGRAM_NAME" >&2
          exit 1
        }
        ;;
      --owner)
        shift
        OWNER_USER="${1:-}"
        [[ -n "$OWNER_USER" ]] || {
          printf '[%s] ERROR: --owner requires a value\n' "$PROGRAM_NAME" >&2
          exit 1
        }
        ;;
      --strict-ssh)
        STRICT_SSH="1"
        ;;
      --help|-h)
        usage
        exit 0
        ;;
      *)
        printf '[%s] ERROR: Unknown option: %s\n' "$PROGRAM_NAME" "$1" >&2
        exit 1
        ;;
    esac
    shift
  done

  if [[ -z "$DATA_ROOT" ]]; then
    DATA_ROOT="$MOUNT_POINT/oasis-pub"
  fi
}

setup_sudo() {
  if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
    SUDO=()
  else
    if command -v sudo >/dev/null 2>&1; then
      SUDO=(sudo)
    else
      printf '[%s] ERROR: sudo is required when not running as root\n' "$PROGRAM_NAME" >&2
      exit 1
    fi
  fi
}

default_owner_user() {
  if [[ -n "$OWNER_USER" ]]; then
    return 0
  fi

  if [[ -n "${SUDO_USER:-}" && "${SUDO_USER:-}" != "root" ]]; then
    OWNER_USER="$SUDO_USER"
  elif id debian >/dev/null 2>&1; then
    OWNER_USER="debian"
  else
    OWNER_USER="$(id -un)"
  fi
}

check_os() {
  # shellcheck disable=SC1091
  . /etc/os-release
  if [[ "${ID:-}" == "debian" && "${VERSION_ID%%.*}" == "$EXPECTED_DEBIAN_MAJOR" ]]; then
    pass "Detected Debian ${VERSION_ID:-unknown}."
  else
    fail "Expected Debian $EXPECTED_DEBIAN_MAJOR but detected ${ID:-unknown} ${VERSION_ID:-unknown}."
  fi
}

check_mount() {
  local source uuid

  source="$(findmnt -no SOURCE "$MOUNT_POINT" 2>/dev/null || true)"
  if [[ -z "$source" ]]; then
    fail "$MOUNT_POINT is not mounted."
    return 0
  fi
  pass "$MOUNT_POINT is mounted from $source."

  uuid="$(blkid -o value -s UUID "$source" 2>/dev/null || true)"
  if [[ -z "$uuid" ]]; then
    fail "Could not determine UUID for the device mounted on $MOUNT_POINT."
    return 0
  fi

  if run_root grep -Eq "^[[:space:]]*UUID=$uuid[[:space:]]+$MOUNT_POINT[[:space:]]" /etc/fstab; then
    pass "/etc/fstab persists $MOUNT_POINT by UUID ($uuid)."
  else
    fail "/etc/fstab does not contain a UUID entry for $MOUNT_POINT ($uuid)."
  fi
}

check_layout() {
  local dir
  local dirs=(
    "$REPO_DIR"
    "$DATA_ROOT"
    "$DATA_ROOT/ssb-data"
    "$DATA_ROOT/logs"
    "$DATA_ROOT/caddy-data"
    "$DATA_ROOT/caddy-config"
    "$DATA_ROOT/backups"
  )

  for dir in "${dirs[@]}"; do
    if [[ -d "$dir" ]]; then
      pass "Directory exists: $dir"
    else
      fail "Missing directory: $dir"
    fi
  done
}

check_ownership() {
  local actual_owner actual_group expected_group

  if ! id "$OWNER_USER" >/dev/null 2>&1; then
    fail "Expected owner user does not exist: $OWNER_USER"
    return 0
  fi

  expected_group="$(id -gn "$OWNER_USER")"
  actual_owner="$(stat -c %U "$DATA_ROOT" 2>/dev/null || true)"
  actual_group="$(stat -c %G "$DATA_ROOT" 2>/dev/null || true)"

  if [[ "$actual_owner" == "$OWNER_USER" && "$actual_group" == "$expected_group" ]]; then
    pass "$DATA_ROOT is owned by $OWNER_USER:$expected_group."
  else
    fail "$DATA_ROOT ownership is ${actual_owner:-unknown}:${actual_group:-unknown}, expected $OWNER_USER:$expected_group."
  fi
}

check_docker() {
  if command -v docker >/dev/null 2>&1; then
    pass "docker CLI is installed."
  else
    fail "docker CLI is missing."
    return 0
  fi

  if run_root docker compose version >/dev/null 2>&1; then
    pass "docker compose is available."
  else
    fail "docker compose is not available."
  fi

  if run_root systemctl is-enabled docker >/dev/null 2>&1; then
    pass "docker.service is enabled."
  else
    fail "docker.service is not enabled."
  fi

  if run_root systemctl is-active docker >/dev/null 2>&1; then
    pass "docker.service is active."
  else
    fail "docker.service is not active."
  fi

  if id -nG "$OWNER_USER" 2>/dev/null | tr ' ' '\n' | grep -qx docker; then
    pass "$OWNER_USER belongs to the docker group."
  else
    warn "$OWNER_USER is not in the docker group yet (or needs a new login session)."
  fi
}

check_ufw() {
  local status_output verbose_output port

  status_output="$(run_root ufw status 2>/dev/null || true)"
  verbose_output="$(run_root ufw status verbose 2>/dev/null || true)"

  if grep -q '^Status: active' <<<"$status_output"; then
    pass "UFW is active."
  else
    fail "UFW is not active."
  fi

  for port in 22/tcp 80/tcp 443/tcp 8008/tcp; do
    if grep -Eq "(^|[[:space:]])$port([[:space:]]|$)" <<<"$status_output"; then
      pass "UFW allows $port."
    else
      fail "UFW rule missing for $port."
    fi
  done

  if grep -q 'Default: deny (incoming)' <<<"$verbose_output"; then
    pass "UFW default incoming policy is deny."
  else
    warn "UFW default incoming policy is not reported as deny."
  fi
}

check_panel_exposure() {
  local listeners bad_listener=0

  listeners="$(ss -ltn 2>/dev/null | awk '$4 ~ /:8787$/ { print $4 }')"
  if [[ -z "$listeners" ]]; then
    pass "Port 8787 is not listening publicly."
    return 0
  fi

  while IFS= read -r listener; do
    [[ -z "$listener" ]] && continue
    case "$listener" in
      127.0.0.1:8787|[::1]:8787)
        ;;
      *)
        bad_listener=1
        ;;
    esac
  done <<<"$listeners"

  if [[ "$bad_listener" == "0" ]]; then
    pass "Port 8787 is loopback-only (${listeners//$'\n'/, })."
  else
    fail "Port 8787 is exposed on a non-loopback interface: ${listeners//$'\n'/, }"
  fi
}

check_ssh() {
  local sshd_config pubkey_setting password_setting keyboard_setting root_setting

  sshd_config="$(run_root sshd -T 2>/dev/null || true)"
  if [[ -z "$sshd_config" ]]; then
    fail "Could not read effective sshd configuration with 'sshd -T'."
    return 0
  fi

  pubkey_setting="$(awk '/^pubkeyauthentication / { print $2 }' <<<"$sshd_config")"
  password_setting="$(awk '/^passwordauthentication / { print $2 }' <<<"$sshd_config")"
  keyboard_setting="$(awk '/^kbdinteractiveauthentication / { print $2 }' <<<"$sshd_config")"
  root_setting="$(awk '/^permitrootlogin / { print $2 }' <<<"$sshd_config")"

  if [[ "$pubkey_setting" == "yes" ]]; then
    pass "SSH pubkey authentication is enabled."
  else
    fail "SSH pubkey authentication is not enabled."
  fi

  if [[ "$password_setting" == "no" ]]; then
    pass "SSH password authentication is disabled."
  elif [[ "$STRICT_SSH" == "1" ]]; then
    fail "SSH password authentication is still $password_setting."
  else
    warn "SSH password authentication is still $password_setting."
  fi

  if [[ "$keyboard_setting" == "no" ]]; then
    pass "SSH keyboard-interactive authentication is disabled."
  elif [[ "$STRICT_SSH" == "1" ]]; then
    fail "SSH keyboard-interactive authentication is still $keyboard_setting."
  else
    warn "SSH keyboard-interactive authentication is still $keyboard_setting."
  fi

  if [[ "$root_setting" == "no" ]]; then
    pass "SSH root login is disabled."
  elif [[ "$STRICT_SSH" == "1" ]]; then
    fail "SSH PermitRootLogin is $root_setting instead of no."
  else
    warn "SSH PermitRootLogin is $root_setting instead of no."
  fi
}

summary() {
  printf '\n[%s] Summary: %s pass, %s warning, %s fail\n' "$PROGRAM_NAME" "$PASS_COUNT" "$WARN_COUNT" "$FAIL_COUNT"
  if [[ "$FAIL_COUNT" -gt 0 ]]; then
    exit 1
  fi
}

main() {
  parse_args "$@"
  setup_sudo
  default_owner_user

  check_os
  check_mount
  check_layout
  check_ownership
  check_docker
  check_ufw
  check_panel_exposure
  check_ssh
  summary
}

main "$@"
