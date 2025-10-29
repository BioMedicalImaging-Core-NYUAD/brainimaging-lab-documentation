#!/usr/bin/env bash
set -euo pipefail

RUNNER_DIR="${1:-/Users/stimulus/actions-runner}"
LOG_OUT="$RUNNER_DIR/runner.out.log"
LOG_ERR="$RUNNER_DIR/runner.err.log"

divider() { printf '%*s\n' "${COLUMNS:-80}" '' | tr ' ' -; }
green(){ printf "\033[32m%s\033[0m\n" "$*"; }
red(){ printf "\033[31m%s\033[0m\n" "$*"; }
brown(){ printf "\033[33m%s\033[0m\n" "$*"; }
bold(){ printf "\033[1m%s\033[0m\n" "$*"; }

try() { "$@" 2>/dev/null || { command -v sudo >/dev/null && sudo "$@"; }; }

header(){ divider; bold "$1"; divider; }
summary(){ [[ $1 -eq 0 ]] && green "✔ $2" || red "✖ $2"; }

json_val(){  # best-effort (uses jq if present)
  local k="$1" f="$2"
  if command -v jq >/dev/null; then jq -r --arg k "$k" '.[$k] // empty' "$f" 2>/dev/null || true
  else sed -n -E "s/.*\"$k\"[[:space:]]*:[[:space:]]*\"([^\"]*)\".*/\1/p" "$f" | head -n1; fi
}

# --- Environment
header "Environment"
echo "User: $(id -un) (uid $(id -u))"
echo "Host: $(scutil --get ComputerName 2>/dev/null || hostname)"
echo "Runner dir: $RUNNER_DIR"
[[ -d "$RUNNER_DIR" ]] || { red "Runner directory not found"; exit 2; }

# --- Config file
header "Configuration (.runner)"
CFG_OK=1
if [[ -f "$RUNNER_DIR/.runner" ]]; then
  CFG_OK=0
  NAME="$(json_val name "$RUNNER_DIR/.runner")"
  URL="$(json_val url "$RUNNER_DIR/.runner")"
  LABELS="$(json_val labels "$RUNNER_DIR/.runner")"
  EPHEMERAL="$(json_val ephemeral "$RUNNER_DIR/.runner")"
  echo "Config present ✅"
  echo "Name:   ${NAME:-<unknown>}"
  echo "URL:    ${URL:-<unknown>}"
  echo "Labels: ${LABELS:-<unknown>}"
  echo "Mode:   $( [[ "${EPHEMERAL:-false}" == "true" ]] && echo 'ephemeral' || echo 'persistent' )"
else
  brown "No .runner file found."
fi
summary $CFG_OK "Config present"

# --- svc.sh status (if installed that way)
header "Service via svc.sh"
SVC_OK=1
if [[ -x "$RUNNER_DIR/svc.sh" ]]; then
  (cd "$RUNNER_DIR" && ./svc.sh status) && SVC_OK=0 || SVC_OK=$?
else
  brown "svc.sh not found; skipping."
fi
summary $SVC_OK "svc.sh status OK"

# --- Detect LaunchAgent/Daemon labels created by svc.sh
header "launchctl (LaunchAgents/Daemons)"
OWNER="$(stat -f %Su "$RUNNER_DIR" 2>/dev/null || echo "")"
OUID="$(id -u "$OWNER" 2>/dev/null || echo "")"

# Common label patterns:
#  - LaunchAgent (per-user): actions.runner.<org>.<repo>.<runnername>
#  - If you made a custom LaunchDaemon, it might be com.github.actions.runner
LABELS_FOUND=()

# Per-user LaunchAgents under the runner owner:
if [[ -n "$OUID" ]]; then
  AGENTS_DIR="/Users/$OWNER/Library/LaunchAgents"
  if [[ -d "$AGENTS_DIR" ]]; then
    while IFS= read -r f; do
      base="$(basename "$f" .plist)"
      LABELS_FOUND+=("$base")
    done < <(ls "$AGENTS_DIR"/actions.runner.*.plist 2>/dev/null || true)
  fi
fi

# System LaunchDaemons common custom label:
if [[ -f "/Library/LaunchDaemons/com.github.actions.runner.plist" ]]; then
  LABELS_FOUND+=("com.github.actions.runner")
fi

if [[ ${#LABELS_FOUND[@]} -eq 0 ]]; then
  brown "No matching LaunchAgent/Daemon plists detected. Will still check processes & logs."
else
  printf "Detected labels:\n"; printf "  - %s\n" "${LABELS_FOUND[@]}"
  echo
  for L in "${LABELS_FOUND[@]}"; do
    if [[ "$L" == com.github.actions.runner ]]; then
      echo "System daemon: $L"
      try launchctl print "system/$L" >/dev/null 2>&1 && try launchctl print "system/$L" | sed -n '1,120p' || brown "Not loaded."
    else
      echo "User agent ($OWNER): $L"
      try launchctl print "gui/$OUID/$L" >/dev/null 2>&1 && try launchctl print "gui/$OUID/$L" | sed -n '1,120p' || brown "Not loaded."
    fi
    echo
  done
fi

# --- Process check
header "Process check (Runner.Listener)"
PROC_OK=1
if pgrep -fl Runner.Listener >/dev/null 2>&1; then
  pgrep -fl Runner.Listener
  PROC_OK=0
else
  red "No Runner.Listener process found."
fi
summary $PROC_OK "Listener running"

# --- Logs
header "Recent logs"
LOG_OK=0
if [[ -f "$LOG_OUT" ]]; then
  echo "== $LOG_OUT (last 40) =="; tail -n 40 "$LOG_OUT" || true
else
  brown "Missing $LOG_OUT"; LOG_OK=1
fi
echo
if [[ -f "$LOG_ERR" ]]; then
  echo "== $LOG_ERR (last 40) =="; tail -n 40 "$LOG_ERR" || true
else
  brown "Missing $LOG_ERR"; LOG_OK=$((LOG_OK|1))
fi

# --- Summary
header "Quick Summary"
summary $CFG_OK  ".runner present"
summary $SVC_OK  "svc.sh status OK"
summary $PROC_OK "Runner.Listener running"
summary $LOG_OK  "Logs available"

echo
brown "Handy fixes:"
echo "  • Start via svc.sh: (cd \"$RUNNER_DIR\" && ./svc.sh start)"
echo "  • Kick a user LaunchAgent: launchctl kickstart -k gui/$OUID/<label>"
echo "  • Kick a system Daemon:    sudo launchctl kickstart -k system/com.github.actions.runner"
echo "  • Watch live logs:         tail -f \"$LOG_OUT\""
