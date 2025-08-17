#!/usr/bin/env bash
# src/core/router.sh
# Dispatch central de subcomandos:
# - Resolve aliases (-h/--help → help, -v/--version → version, upgrade→update etc.)
# - Carrega presenter/cli/<cmd>.sh e executa cmd_<cmd>
# - Aplica logging central: se o cmd_* NÃO chama run_with_logging, o router envolve.
#   (se o cmd_* já usa run_with_logging, executa direto para evitar double logging)

set -euo pipefail

# Dependências esperadas já carregadas em main.sh:
# - core/config.sh   (define EASYENV_HOME)
# - core/utils.sh    (_bld, err, info etc.)
# - core/logging.sh  (run_with_logging, log_init)
# - core/guards.sh   (opcional)

# ---------- Helpers internos ----------

__router_cli_dir(){
  local base="${EASYENV_HOME:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
  printf "%s" "$base/src/presenter/cli"
}

__router_list_cmds(){
  local cli_dir; cli_dir="$(__router_cli_dir)"
  if [[ -d "$cli_dir" ]]; then
    for f in "$cli_dir"/*.sh; do
      [[ -f "$f" ]] || continue
      basename "$f" .sh
    done | sort
  fi
}

__router_print_unknown(){
  local bad="$1"
  err "Comando desconhecido: $bad"
  echo
  _bld "Comandos disponíveis:"
  __router_list_cmds | sed 's/^/  - /'
  echo
  echo "Use: easyenv help"
}

__router_resolve_alias(){
  local raw="$1"
  case "$raw" in
    ""|"help"|"-h"|"--help")          echo "help" ;;
    "version"|"-v"|"--version")       echo "version" ;;
    "upgrade")                        echo "update" ;;
    "diag"|"doctor")                  echo "doctor" ;;
    "ls"|"list")                      echo "status" ;;
    *)                                echo "$raw" ;;
  esac
}

# Retorna 0 se a função informada contém "run_with_logging" no corpo (para evitar dupla)
__router_func_uses_logging(){
  local fn="$1"
  local def
  def="$(declare -f "$fn" 2>/dev/null || true)"
  [[ -n "$def" && "$def" == *"run_with_logging"* ]]
}

# ---------- Execução do comando ----------
__router_exec_cmd(){
  local cmd="$1"; shift || true
  local cli_dir; cli_dir="$(__router_cli_dir)"
  local file="$cli_dir/${cmd}.sh"
  local fn="cmd_${cmd}"

  if [[ ! -f "$file" ]]; then
    __router_print_unknown "$cmd"
    return 1
  fi

  # Carrega o comando
  # shellcheck source=/dev/null
  source "$file"

  if ! declare -F "$fn" >/dev/null 2>&1; then
    err "Arquivo encontrado, mas função '$fn' ausente em $file"
    return 1
  fi

  # Se o comando JÁ usa run_with_logging internamente, apenas executa direto.
  if __router_func_uses_logging "$fn"; then
    "$fn" "$@"
    return $?
  fi

  # Centraliza logging aqui
  run_with_logging "$fn" "$@"
}

# ---------- API pública ----------
router_dispatch(){
  local cmd="${1:-help}"
  shift || true

  cmd="$(__router_resolve_alias "$cmd")"

  # Execução com logging central
  __router_exec_cmd "$cmd" "$@"
}