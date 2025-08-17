#!/usr/bin/env bash
# presenter/cli/tools.sh — CLI de ferramentas (lista/instala/atualiza/remove)

set -euo pipefail

# Locais base
EASYENV_HOME="${EASYENV_HOME:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)}"
CONFIG_DIR="${EASYENV_HOME}/config"
TOOLS_YML="${CONFIG_DIR}/tools.yml"

# Core e serviços
source "${EASYENV_HOME}/src/core/utils.sh"
source "${EASYENV_HOME}/src/core/guards.sh"
source "${EASYENV_HOME}/src/data/services/tools.sh"

cmd_tools(){
  local sub="${1:-}"; shift || true

  case "${sub}" in
    ""|-h|--help|help)
      cmd_tools_help
      ;;

    list)
      local fmt="plain"
      if [[ "${1:-}" == "--detailed" ]]; then fmt="detailed"; fi
      if [[ "${1:-}" == "--json" ]]; then fmt="json"; fi
      tools_cmd_list "$fmt"
      ;;

    install)
      tools_cmd_install_all
      ;;

    update)
      tools_cmd_update_all
      ;;

    uninstall)
      tools_cmd_uninstall_all
      ;;

    *)
      err "Subcomando inválido: ${sub}"
      echo
      cmd_tools_help
      return 1
      ;;
  esac
}

cmd_tools_help(){
  cat <<'EOF'
Uso:
  easyenv tools <subcomando>

Subcomandos:
  install                    Instala os pré-requisitos e utilitários definidos em config/tools.yml
  list [--detailed|--json]   Lista o catálogo de ferramentas
  update                     Atualiza todas as ferramentas do catálogo
  uninstall                  Desinstala todas as ferramentas do catálogo (confirmação interativa)

Exemplos:
  easyenv tools install
  easyenv tools list
  easyenv tools list --detailed
  easyenv tools update
  easyenv tools uninstall
EOF
}

# --------- Implementações de CLI (chamam o serviço data/services/tools.sh) ---------

tools_cmd_list(){
  local mode="${1:-plain}"

  if [[ ! -f "$TOOLS_YML" ]]; then
    warn "Catálogo não encontrado em: $TOOLS_YML"
    echo "Crie/adicione um 'config/tools.yml'."
    return 0
  fi

  case "$mode" in
    json)     tools_service_list_json "$TOOLS_YML" ;;
    detailed) tools_service_list_detailed "$TOOLS_YML" ;;
    *)        tools_service_list_plain "$TOOLS_YML" ;;
  esac
}

tools_cmd_install_all(){ tools_service_install_all "$TOOLS_YML"; }
tools_cmd_update_all(){  tools_service_update_all  "$TOOLS_YML"; }
tools_cmd_uninstall_all(){ tools_service_uninstall_all "$TOOLS_YML"; }