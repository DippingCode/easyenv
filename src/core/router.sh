#!/usr/bin/env bash
# EasyEnv - core/router.sh
# Responsável por despachar subcomandos para presenter/cli/<cmd>.sh
# e centralizar o logging (user.log / debug.log) via logging_begin/logging_end.

set -euo pipefail

# Diretórios base (assumindo que main.sh setou EASYENV_HOME antes)
EASYENV_HOME="${EASYENV_HOME:-$HOME/easyenv}"
CLI_DIR="$EASYENV_HOME/src/presenter/cli"

# ---- Helpers de listagem/uso ----
router_list_commands() {
  # Lista nomes base (sem extensão) dos arquivos *.sh em presenter/cli
  if [[ -d "$CLI_DIR" ]]; then
    find "$CLI_DIR" -maxdepth 1 -type f -name "*.sh" -print \
      | sed 's#.*/##' | sed 's#\.sh$##' | sort
  fi
}

router_print_unknown() {
  local cmd="$1"
  echo "Comando desconhecido: $cmd"
  echo
  echo "Comandos disponíveis:"
  router_list_commands | sed 's/^/  - /'
  echo
  echo "Use: easyenv help"
}

# Normaliza o nome da função (cmd_<nome>) aceitando hífens no arquivo/CLI
# ex.: "doctor" -> "cmd_doctor", "react-native" -> "cmd_react_native"
__router_fn_name() {
  local raw="$1"
  raw="${raw//-/_}"
  printf "cmd_%s" "$raw"
}

# ---- Aliases de comandos (ergonomia) ----
__router_resolve_alias() {
  local c="$1"
  case "$c" in
    ""|"help"|"-h"|"--help") echo "help" ;;
    "-v"|"--version"|"version") echo "version" ;;
    "upgrade") echo "update" ;;
    "diag"|"doctor") echo "doctor" ;;
    "ls"|"list") echo "help" ;;     # por ora, "list" cai no help
    *) echo "$c" ;;
  esac
}

# ---- Dispatcher com logging centralizado ----
router_dispatch() {
  # Dependências mínimas do core (esperado que main.sh já tenha source em config/utils/logging)
  if ! declare -F logging_begin >/dev/null 2>&1; then
    echo "logging_begin não encontrado. Certifique-se de carregar core/logging.sh antes do router." >&2
    exit 1
  fi
  if ! declare -F logging_end >/dev/null 2>&1; then
    echo "logging_end não encontrado. Certifique-se de carregar core/logging.sh antes do router." >&2
    exit 1
  fi

  local cmd="${1:-}"; shift || true
  cmd="$(__router_resolve_alias "$cmd")"

  # Default para help se vazio
  [[ -z "$cmd" ]] && cmd="help"

  # Arquivo do comando
  local cli_file="$CLI_DIR/${cmd}.sh"

  # Pré-carrega help mínimo se help não existir
  if [[ ! -f "$cli_file" && "$cmd" != "help" ]]; then
    # tentar ainda carregar help para fallback
    [[ -f "$CLI_DIR/help.sh" ]] && source "$CLI_DIR/help.sh"
  fi

  # Carrega arquivo do comando, se existir
  if [[ -f "$cli_file" ]]; then
    # shellcheck source=/dev/null
    source "$cli_file"
  fi

  # Nome da função esperada
  local fn; fn="$(__router_fn_name "$cmd")"

  # Inicia logging (gera GUID, timestamps, arquivos de captura)
  logging_begin "$cmd" "$@"

  local rc=0

  if declare -F "$fn" >/dev/null 2>&1; then
    # Execução com captura e exibição simultânea:
    # - stdout vai para TTY e também para EASYENV_LOG_STDOUT
    # - stderr vai para TTY e também para EASYENV_LOG_STDERR
    {
      "$fn" "$@"
    } > >(tee -a "${EASYENV_LOG_STDOUT:?}") \
      2> >(tee -a "${EASYENV_LOG_STDERR:?}" >&2) || rc=$?
  else
    # Função não encontrada: mensagem amigável e status 1
    {
      router_print_unknown "$cmd"
    } > >(tee -a "${EASYENV_LOG_STDOUT:?}") \
      2> >(tee -a "${EASYENV_LOG_STDERR:?}" >&2)
    rc=1
  fi

  # Finaliza logging com código de saída
  logging_end "$rc"

  return "$rc"
}