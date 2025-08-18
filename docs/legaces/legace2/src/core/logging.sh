#!/usr/bin/env bash
# core/logging.sh — logs de uso (user.log) e depuração (debug.log)

set -euo pipefail

EASYENV_HOME="${EASYENV_HOME:-$HOME/easyenv}"
LOG_DIR="$EASYENV_HOME/var/logs"
USER_LOG="$LOG_DIR/user.log"
DEBUG_LOG="$LOG_DIR/debug.log"

ensure_log_dirs() {
  mkdir -p "$LOG_DIR"
}

guid_new() {
  if command -v uuidgen >/dev/null 2>&1; then
    uuidgen
  elif command -v openssl >/dev/null 2>&1; then
    openssl rand -hex 16
  else
    echo "easyenv-$(date +%s%N)-$$"
  fi
}

now_iso() {
  date -u +"%Y-%m-%dT%H:%M:%SZ"
}

__escape_json() {
  # Escapa aspas, barras e novas linhas para JSON
  # (sem usar printf --; tudo com formatos explícitos)
  local s="${1:-}"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  s="${s//$'\n'/\\n}"
  s="${s//$'\r'/}"
  echo "$s"
}

# logging_begin <cmd> [args...]
# Retorna por stdout o req_id gerado
logging_begin() {
  ensure_log_dirs
  local cmd="${1:-}"; shift || true
  local args_str="${*:-}"
  local req_id; req_id="$(guid_new)"
  local ts; ts="$(now_iso)"
  export EASYENV_REQ_ID="$req_id"

  # user.log: ts, id, stage, cmd, args
  printf '%s\t%s\t%s\t%s\t%s\n' "$ts" "$req_id" "BEGIN" "$cmd" "$args_str" >> "$USER_LOG"

  echo "$req_id"
}

# logging_end <req_id> <cmd> <exit_code> <stdout_file> <stderr_file> [args_str]
logging_end() {
  ensure_log_dirs
  local req_id="${1:-}"
  local cmd="${2:-}"
  local exit_code="${3:-0}"
  local out_file="${4:-}"
  local err_file="${5:-}"
  local args_str="${6:-}"

  local ts; ts="$(now_iso)"
  local result="Success"
  [[ "$exit_code" != "0" ]] && result="Error"

  # user.log: ts, id, result, cmd, args
  printf '%s\t%s\t%s\t%s\t%s\n' "$ts" "$req_id" "$result" "$cmd" "$args_str" >> "$USER_LOG"

  # Captura stdout/stderr gerados pelo router (se existirem)
  local out="" err=""
  if [[ -n "$out_file" && -f "$out_file" ]]; then
    out="$(cat "$out_file")"
  fi
  if [[ -n "$err_file" && -f "$err_file" ]]; then
    err="$(cat "$err_file")"
  fi

  # Escapa para JSON
  local out_json err_json cmd_json args_json
  out_json="$(__escape_json "$out")"
  err_json="$(__escape_json "$err")"
  cmd_json="$(__escape_json "$cmd")"
  args_json="$(__escape_json "$args_str")"

  # debug.log (uma linha JSON por execução)
  # (sem "printf --"; formato explícito sempre)
  printf '{\"ts\":\"%s\",\"id\":\"%s\",\"cmd\":\"%s\",\"args\":\"%s\",\"exit\":%s,\"result\":\"%s\",\"stdout\":\"%s\",\"stderr\":\"%s\"}\n' \
    "$ts" "$req_id" "$cmd_json" "$args_json" "$exit_code" "$result" "$out_json" "$err_json" >> "$DEBUG_LOG"
}

# Compat opcional com código legado
log_line() {
  ensure_log_dirs
  local cmd="${1:-}" stage="${2:-}" note="${3:-}"
  local ts; ts="$(now_iso)"
  printf '%s\t%s\t%s\t%s\n' "$ts" "$cmd" "$stage" "$note" >> "$USER_LOG"
}