#!/usr/bin/env bash
# utils.sh - helper functions for maintenance scripts
set -o errexit
set -o nounset
set -o pipefail

LOG_DIR="${LOG_DIR:-./maintenance_logs}"
mkdir -p "$LOG_DIR"

log() {
    # usage: log "message"
    local ts
    ts=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    echo "[$ts] $*" | tee -a "$LOG_DIR/maintenance.log"
}

detect_pkg_mgr() {
    if command -v apt-get >/dev/null 2>&1; then
        echo "apt"
    elif command -v dnf >/dev/null 2>&1; then
        echo "dnf"
    elif command -v yum >/dev/null 2>&1; then
        echo "yum"
    elif command -v pacman >/dev/null 2>&1; then
        echo "pacman"
    else
        echo "unknown"
    fi
}

safe_sudo() {
    # wrap commands that may need sudo; call like: safe_sudo apt-get update
    if [ "$EUID" -ne 0 ]; then
        sudo "$@"
    else
        "$@"
    fi
}
