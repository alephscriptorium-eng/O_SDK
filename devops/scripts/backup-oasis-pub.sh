#!/usr/bin/env bash
set -euo pipefail
umask 077

export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:${PATH:-}"

PROGRAM_NAME="$(basename "$0")"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Datos de instancia → devops/hosts/<DEVOPS_HOST>/host.env
# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib-host.sh"
DEFAULT_KEY_PATH="${KEY_PATH:-$SSH_DIR/${KEY_FILE:-}}"

REMOTE_USER="${REMOTE_USER:-}"
REMOTE_HOST="${REMOTE_HOST:-}"
REMOTE_DATA_ROOT="${REMOTE_DATA_ROOT:-/srv/oasis/oasis-pub}"
REMOTE_SSB_DIR="${REMOTE_SSB_DIR:-$REMOTE_DATA_ROOT/ssb-data}"
REMOTE_CONFIG_FILE="${REMOTE_CONFIG_FILE:-${REMOTE_REPO_DIR:-}/config/ssb/config}"
LOCAL_BACKUP_ROOT="${LOCAL_BACKUP_ROOT:-$DEVOPS_DIR/backups/oasis-pub}"
KEY_PATH="${KEY_PATH:-$DEFAULT_KEY_PATH}"
REMOTE_SUDO="${REMOTE_SUDO:-sudo}"
IDENTITY_ONLY="${IDENTITY_ONLY:-0}"

IDENTITY_FILES=(
  secret
  config
  gossip.json
  gossip_unfollowed.json
  manifest.json
)

SSH_OPTS=()
TARGET_DIR=""
ARCHIVE_PATH=""
TIMESTAMP=""
FEED_ID="unknown"

usage() {
  cat <<EOF
Usage: $PROGRAM_NAME [options]

Create a local backup of the Oasis PUB running on the Gandi VPS.
The backup is stored under devops/backups/ by default, which is
ignored by git thanks to the deny-by-default .gitignore in that folder.

Options:
  --host HOST              Remote SSH host (default: $REMOTE_HOST)
  --user USER              Remote SSH user (default: $REMOTE_USER)
  --key PATH               SSH private key (default: $DEFAULT_KEY_PATH)
  --backup-root PATH       Local backup root (default: $LOCAL_BACKUP_ROOT)
  --remote-data-root PATH  Remote pub data root (default: $REMOTE_DATA_ROOT)
  --remote-ssb-dir PATH    Remote SSB directory (default: <data-root>/ssb-data)
  --remote-config-file PATH Effective pub config file on the VPS (default: $REMOTE_CONFIG_FILE)
  --identity-only          Copy only the identity/config files, skip full tarball
  --help                   Show this help

Environment overrides:
  REMOTE_HOST, REMOTE_USER, KEY_PATH, LOCAL_BACKUP_ROOT,
  REMOTE_DATA_ROOT, REMOTE_SSB_DIR, REMOTE_CONFIG_FILE, REMOTE_SUDO, IDENTITY_ONLY.
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
      --backup-root)
        shift
        LOCAL_BACKUP_ROOT="${1:-}"
        [[ -n "$LOCAL_BACKUP_ROOT" ]] || die "--backup-root requires a value"
        ;;
      --remote-data-root)
        shift
        REMOTE_DATA_ROOT="${1:-}"
        [[ -n "$REMOTE_DATA_ROOT" ]] || die "--remote-data-root requires a value"
        ;;
      --remote-ssb-dir)
        shift
        REMOTE_SSB_DIR="${1:-}"
        [[ -n "$REMOTE_SSB_DIR" ]] || die "--remote-ssb-dir requires a value"
        ;;
      --remote-config-file)
        shift
        REMOTE_CONFIG_FILE="${1:-}"
        [[ -n "$REMOTE_CONFIG_FILE" ]] || die "--remote-config-file requires a value"
        ;;
      --identity-only)
        IDENTITY_ONLY="1"
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
  need_cmd tar
  need_cmd sha256sum

  [[ -f "$KEY_PATH" ]] || die "SSH private key not found: $KEY_PATH"

  SSH_OPTS=(
    -i "$KEY_PATH"
    -o StrictHostKeyChecking=accept-new
    -o BatchMode=yes
  )

  TIMESTAMP="$(date -u +%Y%m%dT%H%M%SZ)"
  TARGET_DIR="$LOCAL_BACKUP_ROOT/$TIMESTAMP"
  mkdir -p "$TARGET_DIR/identity"
  chmod 700 "$TARGET_DIR" "$TARGET_DIR/identity" 2>/dev/null || true
}

run_remote() {
  ssh "${SSH_OPTS[@]}" "$REMOTE_USER@$REMOTE_HOST" "$1"
}

run_remote_sudo() {
  local command="$1"
  if [[ -n "$REMOTE_SUDO" ]]; then
    run_remote "${REMOTE_SUDO} $command"
  else
    run_remote "$command"
  fi
}

copy_remote_file() {
  local remote_path="$1"
  local local_path="$2"
  run_remote_sudo "cat '$remote_path'" > "$local_path"
}

remote_path_for_file() {
  local name="$1"
  case "$name" in
    config)
      printf '%s\n' "$REMOTE_CONFIG_FILE"
      ;;
    *)
      printf '%s/%s\n' "$REMOTE_SSB_DIR" "$name"
      ;;
  esac
}

fetch_identity_files() {
  local name remote_path local_path remote_hash local_hash
  local fetched_any=0

  : > "$TARGET_DIR/SHA256SUMS.txt"

  for name in "${IDENTITY_FILES[@]}"; do
    remote_path="$(remote_path_for_file "$name")"
    local_path="$TARGET_DIR/identity/$name"

    if ! run_remote_sudo "test -f '$remote_path'"; then
      warn "Remote file not found, skipping: $remote_path"
      continue
    fi

    log "Copying $remote_path"
    copy_remote_file "$remote_path" "$local_path"

    remote_hash="$(run_remote_sudo "sha256sum '$remote_path' | cut -d' ' -f1")"
    local_hash="$(sha256sum "$local_path" | awk '{print $1}')"

    [[ "$remote_hash" == "$local_hash" ]] || die "Hash mismatch after copying $name"
    printf '%s  identity/%s\n' "$local_hash" "$name" >> "$TARGET_DIR/SHA256SUMS.txt"
    fetched_any=1
  done

  [[ "$fetched_any" == "1" ]] || die "No identity files were copied from $REMOTE_SSB_DIR"
}

extract_feed_id() {
  local secret_path="$TARGET_DIR/identity/secret"

  if [[ ! -f "$secret_path" ]]; then
    FEED_ID="unknown"
    return 0
  fi

  if command -v node >/dev/null 2>&1; then
    FEED_ID="$(node -e "const fs=require('fs'); const raw=fs.readFileSync(process.argv[1],'utf8'); const json=raw.split(/\r?\n/).filter(line => !line.trim().startsWith('#') && line.trim() !== '').join('\n'); const secret=JSON.parse(json); let pub=String(secret.id || secret.public || '').trim(); if (pub && !pub.startsWith('@')) pub='@'+pub; if (pub && !pub.endsWith('.ed25519') && secret.public) pub += '.ed25519'; console.log(pub || 'unknown');" "$secret_path" 2>/dev/null || printf 'unknown')"
  else
    FEED_ID="$(grep -o '"id"[[:space:]]*:[[:space:]]*"[^"]*"' "$secret_path" | head -1 | cut -d '"' -f4 2>/dev/null || true)"
    if [[ -z "$FEED_ID" ]]; then
      FEED_ID="@$(grep -o '"public"[[:space:]]*:[[:space:]]*"[^"]*"' "$secret_path" | head -1 | cut -d '"' -f4 2>/dev/null || printf 'unknown')"
      [[ "$FEED_ID" == "@unknown" ]] || FEED_ID="$FEED_ID.ed25519"
    fi
  fi
}

create_archive() {
  local archive_name

  [[ "$IDENTITY_ONLY" == "1" ]] && return 0

  archive_name="ssb-data-$TIMESTAMP.tar.gz"
  ARCHIVE_PATH="$TARGET_DIR/$archive_name"

  log "Streaming full archive from $REMOTE_DATA_ROOT/ssb-data"
  run_remote_sudo "tar -C '$REMOTE_DATA_ROOT' -czf - 'ssb-data'" > "$ARCHIVE_PATH"
  [[ -s "$ARCHIVE_PATH" ]] || die "Archive was created empty: $ARCHIVE_PATH"

  sha256sum "$ARCHIVE_PATH" | sed "s|$TARGET_DIR/||" >> "$TARGET_DIR/SHA256SUMS.txt"
  tar -tzf "$ARCHIVE_PATH" > "$TARGET_DIR/ssb-data.contents.txt"
}

write_metadata() {
  local remote_hostname archive_json operator_name

  remote_hostname="$(run_remote 'hostname' 2>/dev/null || printf 'unknown')"
  operator_name="${USER:-${USERNAME:-$(id -un 2>/dev/null || printf 'unknown')}}"
  archive_json='null'
  if [[ -n "$ARCHIVE_PATH" ]]; then
    archive_json="\"$(basename "$ARCHIVE_PATH")\""
  fi

  cat > "$TARGET_DIR/BACKUP_METADATA.json" <<EOF
{
  "createdAtUtc": "$TIMESTAMP",
  "operator": "$operator_name",
  "remoteUser": "$REMOTE_USER",
  "remoteHost": "$REMOTE_HOST",
  "remoteHostname": "$remote_hostname",
  "remoteDataRoot": "$REMOTE_DATA_ROOT",
  "remoteSsbDir": "$REMOTE_SSB_DIR",
  "remoteConfigFile": "$REMOTE_CONFIG_FILE",
  "feedId": "$FEED_ID",
  "identityFiles": [
    "secret",
    "config",
    "gossip.json",
    "gossip_unfollowed.json",
    "manifest.json"
  ],
  "archive": $archive_json,
  "identityOnly": $IDENTITY_ONLY
}
EOF

  cat > "$TARGET_DIR/RESTORE.txt" <<EOF
PUB OASIS SCRIPTORIUM backup
============================

Created (UTC): $TIMESTAMP
Feed ID:       $FEED_ID
Remote host:   $REMOTE_USER@$REMOTE_HOST
Remote SSB:    $REMOTE_SSB_DIR

Restore identity only:
  1. Stop the pub container on the VPS.
  2. Copy files from identity/ back into the remote SSB directory.
  3. Start the pub container again.

Restore full state:
  1. Stop the pub container on the VPS.
  2. Upload $(basename "${ARCHIVE_PATH:-ssb-data-<timestamp>.tar.gz}") to the VPS.
  3. Extract it so that the remote path becomes $REMOTE_DATA_ROOT/ssb-data.
  4. Start the pub container again.

Security note:
  This backup contains the SSB private key in plain form.
  Move it to encrypted external storage as soon as possible.
EOF
}

print_summary() {
  echo
  log "Backup complete"
  printf '  Local folder: %s\n' "$TARGET_DIR"
  printf '  Feed ID:      %s\n' "$FEED_ID"
  if [[ -n "$ARCHIVE_PATH" ]]; then
    printf '  Archive:      %s\n' "$ARCHIVE_PATH"
  else
    printf '  Archive:      skipped (--identity-only)\n'
  fi
  echo
  warn "This backup is intentionally ignored by git, but it still contains secrets."
  warn "Move it to encrypted external storage as soon as possible."
}

main() {
  parse_args "$@"
  setup
  fetch_identity_files
  extract_feed_id
  create_archive
  write_metadata
  print_summary
}

main "$@"
