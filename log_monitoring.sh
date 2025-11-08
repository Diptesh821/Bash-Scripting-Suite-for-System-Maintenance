#!/usr/bin/env bash
# log_monitoring.sh - search log files for a pattern or run tail -F continuous monitoring
# Usage: ./log_monitoring.sh -f /var/log/syslog -p 'Failed password' -c
set -o errexit
set -o nounset
set -o pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/utils.sh" || true

LOG_FILE="${LOG_FILE:-/var/log/syslog}"
PATTERN="${PATTERN:-"ERROR|Failed"}"
CONTINUOUS=0

usage() {
  echo "Usage: $0 -f /path/to/log -p 'pattern' [-c continuous]"
  exit 1
}

while getopts ":f:p:c" opt; do
  case $opt in
    f) LOG_FILE="$OPTARG" ;;
    p) PATTERN="$OPTARG" ;;
    c) CONTINUOUS=1 ;;
    *) usage ;;
  esac
done

ALERT_LOG="./maintenance_alerts.log"


# Ensure alert log file auto-creates in project folder
# touch "$ALERT_LOG"

run_scan() {
  if [ -r "$LOG_FILE" ]; then
    tail -n 1000 "$LOG_FILE" | grep -Ein "$PATTERN" --color=never | tee -a "$ALERT_LOG" || true
  else
    log "No read permission for $LOG_FILE — using sudo for one-shot scan"
    sudo tail -n 1000 "$LOG_FILE" | grep -Ein "$PATTERN" --color=never | tee -a "$ALERT_LOG" || true
  fi
}

run_continuous() {
  log "Running continuous monitor on $LOG_FILE for pattern: $PATTERN"

  if [ -r "$LOG_FILE" ]; then
    tail -n 0 -F "$LOG_FILE" | while read -r line; do
      if echo "$line" | grep -Eiq "$PATTERN"; then
        echo "[$(date -u +'%Y-%m-%dT%H:%M:%SZ')] ALERT: $line" | tee -a "$ALERT_LOG"
      fi
    done
  else
    log "No read permission for $LOG_FILE — using sudo for continuous monitor"
    sudo tail -n 0 -F "$LOG_FILE" | while read -r line; do
      if echo "$line" | grep -Eiq "$PATTERN"; then
        echo "[$(date -u +'%Y-%m-%dT%H:%M:%SZ')] ALERT: $line" | tee -a "$ALERT_LOG" >/dev/null
      fi
    done
  fi
}

if [ "$CONTINUOUS" -eq 1 ]; then
  run_continuous
else
  run_scan
fi
