#!/usr/bin/env bash
# EasyEnv - CLI
# Núcleo: roteador, help, status, init -steps e logging

set -euo pipefail

# Caminhos do projeto
EASYENV_HOME="${EASYENV_HOME:-$HOME/easyenv}"
CORE_DIR="$EASYENV_HOME/src/core"
CFG_DIR="$EASYENV_HOME/src/config"
LOG_DIR="$EASYENV_HOME/src/logs"

# Fonte dos módulos core
source "$CORE_DIR/utils.sh"
source "$CORE_DIR/workspace.sh"
source "$CORE_DIR/tools.sh"    # << novo: instaladores/operadores de ferramentas

# --------------- Subcomandos ---------------

cmd_help(){
  cat <<EOF
EasyEnv — manage your development workspace.

Usage:
  easyenv <command> [options]

Commands:
  help           Show this help
  status         Show current workspace status
  init           Install sections/tools from YAML (supports -steps)
  clean          (coming) Remove tools/caches
  restore        (coming) Restore workspace (all/section/tool/backup)
  update         (coming) Update tools
  backup         (coming) Create a backup archive
  add            (coming) Add a tool by name
  theme          (coming) Manage oh-my-zsh themes

Examples:
  easyenv status
  easyenv init -steps
EOF
}

cmd_status(){
  require_cmd "yq" "Por favor instale yq (brew install yq)."

  echo "EasyEnv status"
  echo "  HOME: $EASYENV_HOME"
  echo "  CFG : $CFG_FILE"
  echo "  SNAP: $SNAP_FILE"
  echo

  if [[ -f "$SNAP_FILE" ]]; then
    echo "Workspace:"
    yq -r '.workspace // {}' "$SNAP_FILE" || true
    echo
    echo "Preferences:"
    yq -r '.preferences // {}' "$SNAP_FILE" || true
  else
    warn "Snapshot não encontrado em: $SNAP_FILE"
    echo "Crie um a partir de $CFG_FILE ou rode: easyenv init"
  fi

  echo
  if [[ -f "$CFG_FILE" ]]; then
    echo "Sections (tools.yml):"
    yq -r '.tools[].section' "$CFG_FILE" | sort -u || true
  else
    warn "Catálogo não encontrado em: $CFG_FILE"
  fi
}

cmd_init(){
  require_cmd "yq" "Instale com: brew install yq."
  ensure_workspace_dirs
  prime_brew_shellenv

  local steps=0
  if [[ -f "$SNAP_FILE" ]]; then
    local def_steps
    def_steps="$(yq -r '.preferences.init.steps_mode_default // false' "$SNAP_FILE" || echo false)"
    [[ "$def_steps" == "true" ]] && steps=1
  fi

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -steps) steps=1 ;;
      *) warn "Opção desconhecida: $1" ;;
    esac
    shift
  done

  # Lê skip_sections de forma segura (array opcional)
  local skip=""
  if [[ -f "$SNAP_FILE" ]]; then
    skip="$(yq -r '(.preferences.init.skip_sections // [])[]' "$SNAP_FILE" 2>/dev/null | tr '\n' ' ')"
  fi

  brew_update_quick || true

  echo
  _bld "Instalação por seções"
  (( steps==1 )) && echo "Modo interativo (-steps) habilitado."
  echo

  local sections; mapfile -t sections < <(list_sections)
  if (( ${#sections[@]} == 0 )); then
    err "Nenhuma seção encontrada em $CFG_FILE (.tools[].section)."
    exit 1
  fi

  for sec in "${sections[@]}"; do
    if [[ " $skip " == *" $sec "* ]]; then
      info "Pulando seção '$sec' (skip_sections do snapshot)."
      continue
    fi

    if (( steps==1 )); then
      if ! confirm "Deseja instalar a seção '$sec'? (yes/NO) "; then
        info "Seção '$sec' ignorada."
        continue
      fi
    fi

    do_section_install "$sec"
  done

  ok "Init concluído. Você pode rodar: source ~/.zshrc"
}

# --------------- Dispatcher ---------------

main(){
  ensure_workspace_dirs
  local cmd="${1:-help}"; shift || true

  case "$cmd" in
    help|-h|--help)      log_line "help" "start" "-";  cmd_help;   log_line "help" "success" "ok" ;;
    status)              log_line "status" "start" "-"; cmd_status; log_line "status" "success" "ok" ;;
    init)                log_line "init" "start" "-";   cmd_init "$@"; log_line "init" "success" "ok" ;;
    clean|restore|update|backup|add|theme)
      err "O subcomando '$cmd' será implementado no próximo passo do backlog."
      log_line "$cmd" "todo" "not-implemented"
      exit 2
      ;;
    *)
      err "Comando desconhecido: $cmd"
      echo "Use: easyenv help"
      log_line "$cmd" "error" "unknown-command"
      exit 1
      ;;
  esac
}

main "$@"