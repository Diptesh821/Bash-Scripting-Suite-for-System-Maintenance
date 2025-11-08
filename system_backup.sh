#!/usr/bin/env bash
# system_backup.sh - simple timestamped tar backup with retention
# Usage: ./system_backup.sh -s /path -s /another -d /dest -r 14 -n
set -o errexit
set -o nounset
set -o pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/utils.sh" || true

SRC=()
DEST="${DEST:-./backups}"
RETENTION_DAYS=${RETENTION_DAYS:-14}
DRY_RUN=0

usage() {
  echo "Usage: $0 -s /src -s /src2 -d /dest -r retention_days [-n dry-run]"
  exit 1
}

while getopts ":s:d:r:n" opt; do
  case $opt in
    s) SRC+=("$OPTARG") ;;
    d) DEST="$OPTARG" ;;
    r) RETENTION_DAYS="$OPTARG" ;;
    n) DRY_RUN=1 ;;
    *) usage ;;
  esac
done

if [ ${#SRC[@]} -eq 0 ]; then
  echo "No source directories provided. Use -s /path"
  usage
fi


TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
ARCHIVE_NAME="${TIMESTAMP}_backup.tar.gz"
ARCHIVE_PATH="$DEST/$ARCHIVE_NAME"

log "Starting backup for: ${SRC[*]} -> $ARCHIVE_PATH (dry-run=$DRY_RUN)"

if [ "$DRY_RUN" -eq 1 ]; then
  echo "DRY RUN: tar -czf $ARCHIVE_PATH ${SRC[*]}"
  exit 0
fi

# Decide if tar needs sudo:
# - any source unreadable by current user
# - OR destination directory not writable by current user (so tar can't create the archive)
NEED_SUDO_TAR=0
DEST_SUDO=0
for s in "${SRC[@]}"; do
  # If top-level source is not readable → sudo needed
  if [ ! -r "$s" ]; then
    NEED_SUDO_TAR=1
    break
  fi

  # Conservative rule: if path is a system directory, force sudo
  case "$s" in
    /etc*|/var/log*|/root*|/usr/local*|/var/backups*)
      NEED_SUDO_TAR=1
      break
      ;;
  esac
done

# Destination writability check
if [ -e "$DEST" ]; then
  if [ ! -w "$DEST" ]; then
    NEED_SUDO_TAR=1
  fi
else
  parent=$(dirname "$DEST")
  if [ ! -w "$parent" ]; then
    NEED_SUDO_TAR=1
    DEST_SUDO=1
  else
    :	  
  fi
fi

# --- Ensure destination exists (create with correct privileges) ---
if [ -e "$DEST" ]; then
  :
else
  if [ "$DEST_SUDO" -eq 1 ]; then
    echo "Creating destination directory with sudo: $DEST"
    sudo mkdir -p -- "$DEST"
  else
    mkdir -p -- "$DEST"
  fi
fi




# Run tar; only elevate tar when needed. STDERR redirection remains in user shell (log stays user-owned).
if [ "$NEED_SUDO_TAR" -eq 1 ]; then
  log "Elevating tar with sudo (insufficient read/write permissions detected)."
  sudo tar -czf "$ARCHIVE_PATH" --warning=no-file-changed --absolute-names "${SRC[@]}" 2>"$LOG_DIR/backup_stderr.log" || {
    log "ERROR: tar failed (sudo). See $LOG_DIR/backup_stderr.log"
    exit 2
  }
else
  tar -czf "$ARCHIVE_PATH" --warning=no-file-changed --absolute-names "${SRC[@]}" 2>"$LOG_DIR/backup_stderr.log" || {
    log "ERROR: tar failed. See $LOG_DIR/backup_stderr.log"
    exit 2
  }
fi

if [ -f "$ARCHIVE_PATH" ]; then
  log "Backup created: $ARCHIVE_PATH (size=$(du -h "$ARCHIVE_PATH" | cut -f1))"
else
  log "ERROR: Expected archive not found: $ARCHIVE_PATH"
  exit 3
fi

# Rotation: delete backups older than retention
find "$DEST" -maxdepth 1 -type f -name "*_backup.tar.gz" -mtime +$RETENTION_DAYS -print -exec rm -f {} \; | while read -r removed; do
  log "Removed old backup: $removed"
done

log "Backup complete."
