#!/usr/bin/env bash
# workspace.sh - paths, arquivos e logging

set -euo pipefail

EASYENV_HOME="${EASYENV_HOME:-$HOME/easyenv}"
CFG_FILE="$EASYENV_HOME/src/config/tools.yml"
SNAP_FILE="$EASYENV_HOME/src/config/.zshrc-tools.yml"
LOG_FILE="$EASYENV_HOME/src/logs/easyenv.log"

ensure_workspace_dirs(){
  ensure_dir "$EASYENV_HOME"
  ensure_dir "$(dirname "$CFG_FILE")"
  ensure_dir "$(dirname "$SNAP_FILE")"
  ensure_dir "$(dirname "$LOG_FILE")"
}

log_line(){
  local cmd="$1" status="$2" msg="$3"
  ensure_workspace_dirs
  printf "[%s] cmd=%s status=%s msg=%s\n" "$(ts)" "$cmd" "$status" "$msg" >> "$LOG_FILE"
}