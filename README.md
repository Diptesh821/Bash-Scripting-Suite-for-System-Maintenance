Understood — here is your **clean, professional README.md with no emojis**, ready to paste:

---

# Bash Maintenance Suite

A modular suite of Bash scripts designed to automate essential Linux system maintenance tasks, including system backups, updates & cleanup, and log monitoring. The suite provides both standalone scripts and an interactive menu for ease of use.

---

## Features

* Automated system backups with timestamped archives and retention policy
* System update & cleanup using the detected package manager
* Log scanning and continuous log monitoring with alerts
* Centralized logging for auditing and debugging
* Minimal privilege elevation — only escalates commands that require root
* Modular structure, suitable for cron automation

---

## Project Structure

```
.
├── menu.sh                      # Interactive menu to run maintenance tasks
├── system_backup.sh             # Backup script with retention support
├── system_update_cleanup.sh     # System update & cleanup
├── log_monitoring.sh            # One-shot and continuous log monitoring
├── utils.sh                     # Shared helper functions
├── script.sh                    # Sample log file for testing
├── docs/
│   └── screenshots/             # Screenshots for documentation
├── maintenance_logs/            # (Ignored) Logs generated at runtime
├── backups/                     # (Ignored) Generated backup archives
├── Project_Report.md            # Detailed project report
└── README.md                    # Project overview
```

---

## Prerequisites

* Linux-based system
* Bash (v4+ recommended)
* `tar`, `grep`, `tail`, and a package manager such as apt, dnf, yum, or pacman
* `sudo` privileges required for certain operations

---

## Setup

Make all scripts executable:

```bash
chmod +x *.sh
```

(Optional) Create log directory:

```bash
mkdir -p maintenance_logs
```

---

## Usage

### 1. Run the Interactive Menu

```bash
./menu.sh
```

You will be able to choose from:

* Run backup
* Run update & cleanup
* Run log scan (one-shot)
* Run log monitor (continuous)

### 2. Run Scripts Directly

#### Run Backup

```bash
./system_backup.sh -s /path/to/folder -d /path/to/backup -r 14
```

#### Update and Cleanup

```bash
./system_update_cleanup.sh
```

#### One-Shot Log Scan

```bash
./log_monitoring.sh -f /var/log/syslog -p "ERROR|Failed"
```

#### Continuous Log Monitoring

```bash
./log_monitoring.sh -f /var/log/syslog -p "Failed" -c
```

---

## Logging

All logs are written to:

```
./maintenance_logs/maintenance.log
```

Alerts from log monitoring are written to:

```
./maintenance_alerts.log
```

These files are ignored from Git to avoid cluttering version control.

---

## Cron Job Examples (Optional)

Backup every night at 2 AM:

```
0 2 * * * /full/path/system_backup.sh -s /etc -s /home/user -d /backups >> /var/log/backup_cron.log 2>&1
```

Monitor logs continuously (recommended to run in tmux or systemd service instead of cron).

---

## Screenshots (stored in docs/screenshots)

* menu_ui.png
* backup_start.png
* backup_success.png
* update_cleanup.png
* update_cleanup_logs.png
* log_scan_one_shot.png
* log_monitor_running.png
* alert_log.png
* maintenance_log.png
* script_sh_sample.png

---

## Author

**Diptesh Singh**
Bash Scripting Suite for System Maintenance

---

