#!/usr/bin/env bash
# src/presenter/cli/help.sh
# Ajuda dinâmica + execução com logging completo.

set -euo pipefail

__help_render(){
  local base="${EASYENV_HOME:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)}"
  local cli_dir="$base/src/presenter/cli"

  _bld "EasyEnv — ajuda"
  echo
  echo "Uso:"
  echo "  easyenv <comando> [opções]"
  echo
  echo "Comandos principais:"
  # lista arquivos *.sh em presenter/cli
  if [[ -d "$cli_dir" ]]; then
    local f name
    for f in "$cli_dir"/*.sh; do
      [[ -f "$f" ]] || continue
      name="$(basename "$f" .sh)"
      # pular arquivos internos (se houver)
      printf "  - %s\n" "$name"
    done | sort
  else
    echo "  (nenhum comando encontrado — diretório vazio)"
  fi
  echo
  echo "Atalhos:"
  echo "  -h, --help       Abre esta ajuda"
  echo "  -v, --version    Mostra versão atual (usa dev-log [tasks[0]])"
  echo "      --detailed   (em 'version') mostra a build atual com summary/notes/next_steps"
  echo
  echo "Exemplos:"
  echo "  easyenv help"
  echo "  easyenv version --detailed"
  echo "  easyenv status --detailed"
  echo "  easyenv push"
}

cmd_help(){
  # Registra a saída completa do help
  run_with_logging "__help_render"
}