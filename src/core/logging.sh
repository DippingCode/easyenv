#!/usr/bin/env bash
# src/core/logging.sh
# Logging estruturado:
#  - user.log: id | timestamp | cmd | args | result(Success|Error)
#  - debug.log: linhas com id | timestamp | stream(STDOUT|STDERR|META) | mensagem
# Fornece run_with_logging <function> [args...] para capturar toda a saída.

set -euo pipefail

# Requer utils (iso_now, gen_uuid, ensure_dir)
: "${EASYENV_HOME:="${EASYENV_HOME:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"}"}"
LOG_DIR="$EASYENV_HOME/var/logs"
USER_LOG="$LOG_DIR/user.log"
DEBUG_LOG="$LOG_DIR/debug.log"

log_init(){
  ensure_dir "$LOG_DIR"
  : "${USER_LOG:?}"; : "${DEBUG_LOG:?}"
  # cria arquivos se não existirem
  : > /dev/null >> "$USER_LOG"
  : > /dev/null >> "$DEBUG_LOG"
}

# Inicia contexto, retorna GUID
log_start(){
  local cmd="$1"; shift || true
  local args_str; args_str="$(printf "%q " "$@")"
  local id; id="$(gen_uuid)"
  local ts; ts="$(iso_now)"
  echo -e "${id}\t${ts}\t${cmd}\t${args_str}\tSTART" >> "$DEBUG_LOG"
  # salva contexto atual
  export EASYENV_LAST_LOG_ID="$id"
  echo "$id"
}

# Linha detalhada no debug (stream = META|STDOUT|STDERR)
log_debug_line(){
  local id="$1" stream="$2" msg="$3"
  local ts; ts="$(iso_now)"
  # preserva quebras múltiplas
  while IFS= read -r line || [[ -n "$line" ]]; do
    echo -e "${id}\t${ts}\t${stream}\t${line}" >> "$DEBUG_LOG"
  done <<<"$msg"
}

# Finaliza contexto e escreve user.log
log_finish(){
  local id="$1" cmd="$2"; shift 2 || true
  local args_str; args_str="$(printf "%q " "$@")"
  local status="${!#}" # último argumento deve ser status numérico
  # remove status do args_str
  args_str="${args_str% ${status}}"
  local ts; ts="$(iso_now)"
  local result="Success"
  [[ "$status" -ne 0 ]] && result="Error"

  # user log (compacto)
  echo -e "${id}\t${ts}\t${cmd}\t${args_str}\t${result}" >> "$USER_LOG"
  # debug log (marcador de fim)
  echo -e "${id}\t${ts}\tMETA\tEND status=${status} result=${result}" >> "$DEBUG_LOG"
}

# Executa uma função e captura TODA a saída (stdout/stderr) para o debug.log,
# mantendo a saída visível ao usuário.
# Uso: run_with_logging func_name [args...]
run_with_logging(){
  log_init
  local func="$1"; shift || true
  local id; id="$(log_start "$func" "$@")"
  local status=0

  # Encaminha STDOUT/STDERR para debug + terminal
  {
    {
      # executa a função no ambiente atual
      "$func" "$@"
    } 2> >(while IFS= read -r line; do
             log_debug_line "$id" "STDERR" "$line"
             printf "%s\n" "$line" >&2
           done)
  } | while IFS= read -r line; do
        log_debug_line "$id" "STDOUT" "$line"
        printf "%s\n" "$line"
      done
  status=${PIPESTATUS[0]}

  log_finish "$id" "$func" "$@" "$status"
  return "$status"
}