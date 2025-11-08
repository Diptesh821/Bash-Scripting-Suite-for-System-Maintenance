#!/usr/bin/env bash
# menu.sh - small interactive menu to run maintenance tasks
set -o errexit
set -o nounset
set -o pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/utils.sh" || true

PS3="Choose an action: "

options=("Run backup" "Run update & cleanup" "Run log scan (one-shot)" "Run log monitor (continuous)" "Exit")

select opt in "${options[@]}"; do
  case $REPLY in
    1)
      read -rp "Enter source dir (comma separated for multiple): " srcs
      IFS=',' read -r -a raw_arr <<< "$srcs"

      normalized=()
      for s in "${raw_arr[@]}"; do
        # trim leading/trailing whitespace, preserve internal spaces
        s="${s#"${s%%[![:space:]]*}"}"
        s="${s%"${s##*[![:space:]]}"}"
        [ -n "$s" ] && normalized+=( "$s" )
      done

      if [ ${#normalized[@]} -eq 0 ]; then
        echo "No valid source provided. Cancelling."
        continue
      fi

      read -rp "Enter dest dir (default ./backups): " dest
      dest=${dest:-./backups}

      missing=()
      unreadable=()
      for s in "${normalized[@]}"; do
        if [ ! -e "$s" ]; then
          missing+=( "$s" )
        elif [ ! -r "$s" ]; then
          unreadable+=( "$s" )
        fi
      done

      # If any source is missing -> abort immediately
      if [ ${#missing[@]} -ne 0 ]; then
        echo "ERROR: The following source(s) do not exist:"
        for m in "${missing[@]}"; do echo "  - $m"; done
        echo "Please correct the paths and try again."
        continue
      fi

      echo ""
      echo "Sources to back up:"
      for s in "${normalized[@]}"; do echo "  - $s"; done
      echo "Destination: $dest"
      if [ ${#unreadable[@]} -ne 0 ]; then
        echo ""
        echo "Permission issues detected (these will require elevation):"
        for u in "${unreadable[@]}"; do echo "  * No read permission: $u"; done
      fi

      read -rp $'\nProceed with backup now? [y/N]: ' proceed
      if [[ ! "${proceed,,}" =~ ^(y|yes)$ ]]; then
        echo "Backup cancelled by user."
        continue
      fi

      args=()
      for s in "${normalized[@]}"; do args+=( -s "$s" ); done

      echo "Starting backup..."
      "$SCRIPT_DIR/system_backup.sh" "${args[@]}" -d "$dest"

      rc=$?
      if [ $rc -eq 0 ]; then
        echo "Backup finished successfully."
        log "Backup completed successfully for dest=$dest"
      else
        echo "Backup failed with exit code $rc."
        log "Backup failed with exit code $rc for dest=$dest"
      fi
      ;;
    2)
      "$SCRIPT_DIR/system_update_cleanup.sh"
      ;;
    3)
      read -rp "Log file (default /var/log/syslog): " lf
      lf=${lf:-/var/log/syslog}
      read -rp "Pattern (default 'ERROR|Failed'): " pat
      pat=${pat:-ERROR|Failed}
      echo "running one-shot scan"
      "$SCRIPT_DIR/log_monitoring.sh" -f "$lf" -p "$pat"
      ;;
    4)
      read -rp "Log file (default /var/log/syslog): " lf
      lf=${lf:-/var/log/syslog}
      read -rp "Pattern (default 'ERROR|Failed'): " pat
      pat=${pat:-ERROR|Failed}
      "$SCRIPT_DIR/log_monitoring.sh" -f "$lf" -p "$pat" -c
      ;;
    5)
      echo "Goodbye"
      break
      ;;
    *)
      echo "Invalid choice" ;;
  esac
done
