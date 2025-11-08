#!/usr/bin/env bash
# system_update_cleanup.sh - system update and cleanup helper
set -o errexit
set -o nounset
set -o pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/utils.sh" || true

log "Starting update & cleanup"
PKG=$(detect_pkg_mgr)
log "Detected package manager: $PKG"

case "$PKG" in
  apt)
    safe_sudo apt-get update
    safe_sudo apt-get -y upgrade
    safe_sudo apt-get -y autoremove
    safe_sudo apt-get -y autoclean
    ;;
  dnf)
    safe_sudo dnf -y upgrade
    safe_sudo dnf -y autoremove
    ;;
  yum)
    safe_sudo yum -y update
    safe_sudo yum -y autoremove || true
    ;;
  pacman)
    safe_sudo pacman -Syu --noconfirm
    ;;
  *)
    log "Unknown package manager. Exiting."
    exit 1
    ;;
esac

log "Update & cleanup finished."
