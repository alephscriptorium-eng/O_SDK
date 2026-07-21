#!/usr/bin/env bash
set -euo pipefail

export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:${PATH:-}"

PROGRAM_NAME="$(basename "$0")"
EXPECTED_DEBIAN_MAJOR="${EXPECTED_DEBIAN_MAJOR:-13}"
MOUNT_POINT="${MOUNT_POINT:-/srv/oasis}"
REPO_DIR="${REPO_DIR:-/opt/oasis-scriptorium}"
DATA_ROOT="${DATA_ROOT:-}"
VOLUME_DEVICE="${VOLUME_DEVICE:-}"
FS_LABEL="${FS_LABEL:-scriptorium-oasis-pub}"
FS_TYPE="${FS_TYPE:-ext4}"
OWNER_USER="${OWNER_USER:-}"
APPLY_SSH_HARDENING="${APPLY_SSH_HARDENING:-0}"
ASSUME_YES="${ASSUME_YES:-0}"
SSH_HARDENING_FILE="/etc/ssh/sshd_config.d/60-oasis-pub-hardening.conf"
SUDO=()

usage() {
  cat <<EOF
Usage: $PROGRAM_NAME [options]

Prepare the canonical Debian 13 base for PUB OASIS SCRIPTORIUM:
  - code in /opt/oasis-scriptorium
  - persistent state in /srv/oasis

Options:
  --device PATH               Block device for the data volume (for example /dev/vdb).
                              If omitted, the script will try to auto-detect the extra disk.
  --mount-point PATH          Mount point for the persistent volume (default: $MOUNT_POINT).
  --repo-dir PATH             Repo directory to create (default: $REPO_DIR).
  --data-root PATH            Root directory for persistent pub data
                              (default: <mount-point>/oasis-pub).
  --owner USER                Owner of repo/data directories (default: sudo user or debian).
  --apply-ssh-hardening       Write SSH hardening config and reload sshd.
  --assume-yes                Skip interactive confirmation before formatting.
  --help                      Show this help.

Environment overrides:
  EXPECTED_DEBIAN_MAJOR, MOUNT_POINT, REPO_DIR, DATA_ROOT, VOLUME_DEVICE,
  FS_LABEL, FS_TYPE, OWNER_USER, APPLY_SSH_HARDENING, ASSUME_YES.
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

run_root() {
  if ((${#SUDO[@]})); then
    "${SUDO[@]}" "$@"
  else
    "$@"
  fi
}

confirm() {
  local prompt="$1"
  local reply

  if [[ "$ASSUME_YES" == "1" ]]; then
    return 0
  fi

  read -r -p "$prompt [y/N] " reply
  [[ "$reply" =~ ^([yY]|[yY][eE][sS])$ ]]
}

parse_args() {
  while (($#)); do
    case "$1" in
      --device)
        shift
        VOLUME_DEVICE="${1:-}"
        [[ -n "$VOLUME_DEVICE" ]] || die "--device requires a value"
        ;;
      --mount-point)
        shift
        MOUNT_POINT="${1:-}"
        [[ -n "$MOUNT_POINT" ]] || die "--mount-point requires a value"
        ;;
      --repo-dir)
        shift
        REPO_DIR="${1:-}"
        [[ -n "$REPO_DIR" ]] || die "--repo-dir requires a value"
        ;;
      --data-root)
        shift
        DATA_ROOT="${1:-}"
        [[ -n "$DATA_ROOT" ]] || die "--data-root requires a value"
        ;;
      --owner)
        shift
        OWNER_USER="${1:-}"
        [[ -n "$OWNER_USER" ]] || die "--owner requires a value"
        ;;
      --apply-ssh-hardening)
        APPLY_SSH_HARDENING="1"
        ;;
      --assume-yes)
        ASSUME_YES="1"
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

  if [[ -z "$DATA_ROOT" ]]; then
    DATA_ROOT="$MOUNT_POINT/oasis-pub"
  fi
}

setup_sudo() {
  if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
    SUDO=()
  else
    need_cmd sudo
    SUDO=(sudo)
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

ensure_bootstrap_prereqs() {
  local missing_cmds=()
  local cmd

  for cmd in blkid findmnt lsblk wipefs; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      missing_cmds+=("$cmd")
    fi
  done

  if ((${#missing_cmds[@]} == 0)); then
    return 0
  fi

  warn "Missing bootstrap prerequisites: ${missing_cmds[*]}"
  log "Installing util-linux so the bootstrap can inspect and format block devices."
  run_root apt-get update
  run_root apt-get install -y util-linux

  for cmd in blkid findmnt lsblk wipefs; do
    need_cmd "$cmd"
  done
}

ensure_supported_os() {
  # shellcheck disable=SC1091
  . /etc/os-release

  [[ "${ID:-}" == "debian" ]] || die "This script targets Debian; detected ${ID:-unknown}."
  [[ "${VERSION_ID%%.*}" == "$EXPECTED_DEBIAN_MAJOR" ]] || die "Expected Debian $EXPECTED_DEBIAN_MAJOR, detected ${VERSION_ID:-unknown}."
  [[ "$FS_TYPE" == "ext4" ]] || die "Only ext4 is supported by this script right now."

  log "Detected Debian ${VERSION_ID:-unknown} (${VERSION_CODENAME:-unknown})."
}

root_disk() {
  local root_source parent

  root_source="$(findmnt -no SOURCE /)"
  if [[ -b "$root_source" ]]; then
    parent="$(lsblk -no PKNAME "$root_source" 2>/dev/null || true)"
    if [[ -n "$parent" ]]; then
      printf '/dev/%s\n' "$parent"
      return 0
    fi
    printf '%s\n' "$root_source"
    return 0
  fi

  return 1
}

detect_volume_device() {
  local system_disk
  local candidates=()

  if [[ -n "$VOLUME_DEVICE" ]]; then
    [[ -b "$VOLUME_DEVICE" ]] || die "Device does not exist or is not a block device: $VOLUME_DEVICE"
    log "Using explicit device: $VOLUME_DEVICE"
    return 0
  fi

  system_disk="$(root_disk || true)"
  if [[ -n "$system_disk" ]]; then
    mapfile -t candidates < <(lsblk -dnpo NAME,TYPE | awk '$2 == "disk" { print $1 }' | grep -vx "$system_disk" || true)
  else
    mapfile -t candidates < <(lsblk -dnpo NAME,TYPE | awk '$2 == "disk" { print $1 }')
  fi

  if ((${#candidates[@]} == 1)); then
    VOLUME_DEVICE="${candidates[0]}"
    log "Auto-detected data volume device: $VOLUME_DEVICE"
    return 0
  fi

  warn "Could not safely auto-detect the attached data volume."
  lsblk -o NAME,SIZE,FSTYPE,TYPE,MOUNTPOINT
  die "Pass --device /dev/... explicitly."
}

existing_fs_type() {
  blkid -o value -s TYPE "$VOLUME_DEVICE" 2>/dev/null || true
}

existing_uuid() {
  local uuid

  uuid="$(blkid -o value -s UUID "$VOLUME_DEVICE" 2>/dev/null || true)"
  if [[ -n "$uuid" ]]; then
    printf '%s\n' "$uuid"
    return 0
  fi

  if command -v udevadm >/dev/null 2>&1; then
    run_root udevadm settle || true
  fi

  blkid -p -o value -s UUID "$VOLUME_DEVICE" 2>/dev/null || true
}

has_child_block_devices() {
  local child_count
  child_count="$(lsblk -lnpo NAME "$VOLUME_DEVICE" 2>/dev/null | awk 'NR > 1 { count += 1 } END { print count + 0 }')"
  [[ "$child_count" -gt 0 ]]
}

clear_stale_signatures() {
  local wipe_preview

  wipe_preview="$(wipefs --noheadings "$VOLUME_DEVICE" 2>/dev/null || true)"
  if [[ -n "$wipe_preview" ]] || has_child_block_devices; then
    warn "Clearing stale signatures/partition metadata from $VOLUME_DEVICE before formatting."
    run_root wipefs -a "$VOLUME_DEVICE"
  fi
}

ensure_filesystem() {
  local current_fs
  local mkfs_cmd

  current_fs="$(existing_fs_type)"
  if [[ -n "$current_fs" ]]; then
    if [[ "$current_fs" != "$FS_TYPE" ]]; then
      warn "Device already contains filesystem $current_fs; using that instead of requested $FS_TYPE."
      FS_TYPE="$current_fs"
    fi
    log "Device $VOLUME_DEVICE already has filesystem $FS_TYPE."
    return 0
  fi

  warn "About to create $FS_TYPE on $VOLUME_DEVICE. This will erase data on that device."
  confirm "Format $VOLUME_DEVICE?" || die "Aborted before formatting $VOLUME_DEVICE."

  mkfs_cmd="mkfs.$FS_TYPE"
  need_cmd "$mkfs_cmd"
  clear_stale_signatures
  run_root "$mkfs_cmd" -F -L "$FS_LABEL" "$VOLUME_DEVICE"
  log "Created $FS_TYPE filesystem on $VOLUME_DEVICE with label $FS_LABEL."
}

ensure_mount_point() {
  run_root install -d -m 0755 "$MOUNT_POINT"
}

ensure_fstab_entry() {
  local uuid timestamp mount_line

  uuid="$(existing_uuid)"
  [[ -n "$uuid" ]] || die "Could not determine UUID for $VOLUME_DEVICE after filesystem setup."
  mount_line="$(run_root awk -v mount_point="$MOUNT_POINT" '$2 == mount_point { print $0 }' /etc/fstab || true)"

  if [[ -n "$mount_line" ]]; then
    if grep -Eq "^[[:space:]]*UUID=$uuid[[:space:]]+$MOUNT_POINT[[:space:]]+$FS_TYPE([[:space:]]|$)" <<<"$mount_line"; then
      log "/etc/fstab already contains the expected entry for $MOUNT_POINT."
      return 0
    fi
    die "/etc/fstab already contains a different entry for $MOUNT_POINT: $mount_line"
  fi

  timestamp="$(date +%Y%m%d%H%M%S)"
  run_root cp /etc/fstab "/etc/fstab.bak.$timestamp"
  printf 'UUID=%s %s %s defaults,nofail 0 2\n' "$uuid" "$MOUNT_POINT" "$FS_TYPE" | run_root tee -a /etc/fstab >/dev/null
  log "Appended persistent mount for $MOUNT_POINT to /etc/fstab."
}

ensure_mounted() {
  local mounted_source expected_source

  mounted_source="$(findmnt -no SOURCE "$MOUNT_POINT" 2>/dev/null || true)"
  expected_source="$(readlink -f "$VOLUME_DEVICE" 2>/dev/null || printf '%s' "$VOLUME_DEVICE")"

  if [[ -n "$mounted_source" ]]; then
    mounted_source="$(readlink -f "$mounted_source" 2>/dev/null || printf '%s' "$mounted_source")"
    [[ "$mounted_source" == "$expected_source" ]] || die "$MOUNT_POINT is already mounted from $mounted_source instead of $expected_source."
    log "$MOUNT_POINT is already mounted from $mounted_source."
  else
    run_root mount "$MOUNT_POINT"
    log "Mounted $VOLUME_DEVICE on $MOUNT_POINT."
  fi

  run_root mount -a
}

ensure_host_layout() {
  local owner_group

  id "$OWNER_USER" >/dev/null 2>&1 || die "Owner user does not exist: $OWNER_USER"
  owner_group="$(id -gn "$OWNER_USER")"

  run_root install -d -o "$OWNER_USER" -g "$owner_group" -m 0755 "$REPO_DIR"
  run_root install -d -o "$OWNER_USER" -g "$owner_group" -m 0755 "$DATA_ROOT"
  run_root install -d -o "$OWNER_USER" -g "$owner_group" -m 0755 \
    "$DATA_ROOT/ssb-data" \
    "$DATA_ROOT/logs" \
    "$DATA_ROOT/caddy-data" \
    "$DATA_ROOT/caddy-config" \
    "$DATA_ROOT/backups"

  log "Ensured host layout under $REPO_DIR and $DATA_ROOT for user $OWNER_USER."
}

package_available() {
  apt-cache show "$1" >/dev/null 2>&1
}

compose_package() {
  local candidate
  for candidate in docker-compose docker-compose-v2 docker-compose-plugin; do
    if package_available "$candidate"; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done
  return 1
}

optional_buildx_package() {
  local candidate
  for candidate in docker-buildx docker-buildx-plugin; do
    if package_available "$candidate"; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done
  return 1
}

install_packages() {
  local compose_pkg buildx_pkg
  local packages=(ca-certificates curl git openssh-server rsync ufw docker.io docker-cli)

  log "Refreshing apt metadata."
  run_root apt-get update

  compose_pkg="$(compose_package)" || die "Could not find a Compose v2 package in the Debian repositories."
  packages+=("$compose_pkg")

  buildx_pkg="$(optional_buildx_package || true)"
  if [[ -n "$buildx_pkg" ]]; then
    packages+=("$buildx_pkg")
  fi

  log "Installing packages: ${packages[*]}"
  run_root apt-get install -y "${packages[@]}"
  run_root systemctl enable --now docker
  run_root usermod -aG docker "$OWNER_USER"

  run_root docker --version >/dev/null
  run_root docker compose version >/dev/null
  log "Docker Engine and Compose v2 are installed and docker.service is enabled."
}

configure_ufw() {
  log "Configuring UFW for 22, 80, 443 and 8008/tcp."
  run_root ufw default deny incoming
  run_root ufw default allow outgoing
  run_root ufw allow 22/tcp
  run_root ufw allow 80/tcp
  run_root ufw allow 443/tcp
  run_root ufw allow 8008/tcp
  run_root ufw --force enable
}

audit_ssh() {
  local sshd_config

  sshd_config="$(run_root sshd -T 2>/dev/null || true)"
  if [[ -z "$sshd_config" ]]; then
    warn "Could not read the effective sshd configuration with 'sshd -T'."
    return 0
  fi

  log "Effective SSH settings:"
  printf '%s\n' "$sshd_config" | awk '/^(passwordauthentication|kbdinteractiveauthentication|pubkeyauthentication|permitrootlogin) / { printf "  - %s\n", $0 }'
}

reload_ssh() {
  if run_root systemctl reload ssh; then
    return 0
  fi
  run_root systemctl reload sshd
}

maybe_harden_ssh() {
  if [[ "$APPLY_SSH_HARDENING" != "1" ]]; then
    warn "SSH hardening not applied automatically. Re-run with --apply-ssh-hardening after confirming key-based login in a second SSH session."
    audit_ssh
    return 0
  fi

  run_root install -d -m 0755 /etc/ssh/sshd_config.d
  cat <<'EOF' | run_root tee "$SSH_HARDENING_FILE" >/dev/null
PermitRootLogin no
PasswordAuthentication no
KbdInteractiveAuthentication no
ChallengeResponseAuthentication no
PubkeyAuthentication yes
EOF

  run_root sshd -t
  reload_ssh
  log "Applied SSH hardening in $SSH_HARDENING_FILE and reloaded sshd."
  audit_ssh
}

print_summary() {
  cat <<EOF

Base Debian 13 host setup complete.

Layout:
  repo dir:    $REPO_DIR
  mount point: $MOUNT_POINT
  data root:   $DATA_ROOT
  owner user:  $OWNER_USER
  data device: $VOLUME_DEVICE

Next steps:
  1. Clone the repository into $REPO_DIR if it is not there yet.
  2. Copy OASIS_PUB/.env.vps.example to OASIS_PUB/.env.
  3. Reboot the VPS once.
  4. Re-run GANDI_DEVOPS_FOLDER/scripts/verify-debian13-base.sh after reboot.

Remember: the docker group change applies fully after a new login for $OWNER_USER.
EOF
}

main() {
  parse_args "$@"
  setup_sudo
  default_owner_user

  need_cmd apt-get
  need_cmd awk
  need_cmd install
  need_cmd systemctl
  ensure_bootstrap_prereqs

  ensure_supported_os
  detect_volume_device
  ensure_filesystem
  ensure_mount_point
  ensure_fstab_entry
  ensure_mounted
  ensure_host_layout
  install_packages
  maybe_harden_ssh
  configure_ufw
  audit_ssh
  print_summary
}

main "$@"
