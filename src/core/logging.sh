#!/usr/bin/env bash
# EasyEnv - core/logging.sh
# - user.log: JSON lines com {id, ts, cmd, args, status, exit_code, duration_ms}
# - debug.log: bloco com stdout/stderr correlacionado pelo mesmo id

set -euo pipefail

# ---------- Paths ----------
EASYENV_HOME="${EASYENV_HOME:-$HOME/easyenv}"
LOG_DIR="${EASYENV_LOG_DIR:-$EASYENV_HOME/var/logs}"
USER_LOG="$LOG_DIR/user.log"
DEBUG_LOG="$LOG_DIR/debug.log"

mkdir -p "$LOG_DIR"

# ---------- Helpers ----------
__now_iso() {
  # ISO-8601 com timezone
  date +"%Y-%m-%dT%H:%M:%S%z"
}

__gen_uuid() {
  if command -v uuidgen >/dev/null 2>&1; then
    uuidgen
  elif command -v python3 >/dev/null 2>&1; then
    python3 - <<'PY'
import uuid; print(uuid.uuid4())
PY
  else
    # Fallback: pseudo-uuid estável o suficiente p/ correlação
    local seed hex
    seed="$(date +%s)-$$-$RANDOM-$RANDOM"
    hex="$(printf '%s' "$seed" | shasum -a 1 2>/dev/null | awk '{print $1}')"
    printf "%s-%s-%s-%s-%s\n" "${hex:0:8}" "${hex:8:4}" "${hex:12:4}" "${hex:16:4}" "${hex:20:12}"
  fi
}

# macOS vs GNU date: calcula duração em ms se possível
__duration_ms_or_null() {
  local start_ts="$1"
  # tenta macOS first (-j -f), senão GNU date -d; se falhar, null
  local start_epoch end_epoch
  if start_epoch=$(date -j -f "%Y-%m-%dT%H:%M:%S%z" "$start_ts" "+%s" 2>/dev/null); then
    :
  elif start_epoch=$(date -d "$start_ts" +%s 2>/dev/null); then
    :
  else
    echo "null"; return 0
  fi
  end_epoch=$(date +%s)
  echo $(( (end_epoch - start_epoch) * 1000 ))
}

# ---------- Estado corrente do log (exportado p/ router) ----------
# EASYENV_LOG_ID, EASYENV_LOG_TS, EASYENV_LOG_CMD, EASYENV_LOG_ARGS
# EASYENV_LOG_STDOUT, EASYENV_LOG_STDERR

logging_begin() {
  # Uso: logging_begin <cmd> [args...]
  EASYENV_LOG_ID="$(__gen_uuid)"; export EASYENV_LOG_ID
  EASYENV_LOG_TS="$(__now_iso)"; export EASYENV_LOG_TS
  EASYENV_LOG_CMD="${1:-}"; shift || true
  EASYENV_LOG_ARGS="$*"; export EASYENV_LOG_CMD EASYENV_LOG_ARGS

  # arquivos temporários para captura (o router deve redirecionar para eles)
  EASYENV_LOG_STDOUT="/tmp/easyenv-${EASYENV_LOG_ID}.out"
  EASYENV_LOG_STDERR="/tmp/easyenv-${EASYENV_LOG_ID}.err"
  : > "$EASYENV_LOG_STDOUT"
  : > "$EASYENV_LOG_STDERR"
}

logging_end() {
  # Uso: logging_end <exit_code>
  local code="${1:-0}"
  local status="Success"
  (( code != 0 )) && status="Error"

  local dur_ms
  dur_ms="$(__duration_ms_or_null "${EASYENV_LOG_TS:-}")"

  # user.log como JSONL
  printf '{"id":"%s","ts":"%s","cmd":"%s","args":"%s","status":"%s","exit_code":%d,"duration_ms":%s}\n' \
    "${EASYENV_LOG_ID:-unknown}" \
    "${EASYENV_LOG_TS:-$(__now_iso)}" \
    "${EASYENV_LOG_CMD:-unknown}" \
    "$(printf '%s' "${EASYENV_LOG_ARGS:-}" | sed 's/"/\\"/g')" \
    "$status" "$code" "$dur_ms" >> "$USER_LOG"

  # debug.log detalhado
  {
    printf '----- EASYENV DEBUG id=%s ts=%s cmd=%s args=%q -----\n' \
      "${EASYENV_LOG_ID:-unknown}" \
      "${EASYENV_LOG_TS:-$(__now_iso)}" \
      "${EASYENV_LOG_CMD:-unknown}" \
      "${EASYENV_LOG_ARGS:-}"
    printf '[stdout]\n'
    cat "${EASYENV_LOG_STDOUT:-/dev/null}" 2>/dev/null || true
    printf '\n[stderr]\n'
    cat "${EASYENV_LOG_STDERR:-/dev/null}" 2>/dev/null || true
    printf '\n[exit]=%d\n' "$code"
    printf '----- end id=%s -----\n\n' "${EASYENV_LOG_ID:-unknown}"
  } >> "$DEBUG_LOG"

  # limpeza
  rm -f "${EASYENV_LOG_STDOUT:-}" "${EASYENV_LOG_STDERR:-}" 2>/dev/null || true
}

# ---------- Wrappers de compatibilidade ----------
# Alguns routers/legados podem chamar estes nomes:
log_request_start() { logging_begin "$@"; }
log_request_end()   { logging_end "${1:-0}"; }
router_log_start()  { logging_begin "$@"; }
router_log_end()    { logging_end "${1:-0}"; }
begin_cmd_log()     { logging_begin "$@"; }
end_cmd_log()       { logging_end "${1:-0}"; }

# Evento simples (compat)
# Uso: log_line <cmd> <stage> <status>
log_line() {
  local cmd="${1:-?}" stage="${2:-?}" status="${3:-?}"
  printf '{"id":"%s","ts":"%s","event":"%s","stage":"%s","status":"%s"}\n' \
    "${EASYENV_LOG_ID:-none}" "$(__now_iso)" "$cmd" "$stage" "$status" >> "$USER_LOG"
}