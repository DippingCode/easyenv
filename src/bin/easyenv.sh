#!/usr/bin/env bash
# EasyEnv - CLI
# Passo 1/2: roteador, help, status e logging básico

set -euo pipefail

# Caminhos do projeto
EASYENV_HOME="${EASYENV_HOME:-$HOME/easyenv}"
CORE_DIR="$EASYENV_HOME/src/core"
CFG_DIR="$EASYENV_HOME/src/config"
LOG_DIR="$EASYENV_HOME/src/logs"

# Fonte dos módulos core
# (mantemos sourcing explícito para clareza nesta fase)
source "$CORE_DIR/utils.sh"
source "$CORE_DIR/workspace.sh"

# --------------- Subcomandos ---------------

cmd_help(){
  cat <<EOF
EasyEnv — manage your development workspace.

Usage:
  easyenv <command> [options]

Commands:
  help           Show this help
  status         Show current workspace status
  init           (coming next step) Install sections/tools from YAML
  clean          (coming next step) Remove tools/caches
  restore        (coming next step) Restore workspace (all/section/tool/backup)
  update         (coming next step) Update tools
  backup         (coming next step) Create a backup archive
  add            (coming next step) Add a tool by name
  theme          (coming next step) Manage oh-my-zsh themes

Examples:
  easyenv status
  easyenv help
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

# --------------- Dispatcher ---------------

main(){
  ensure_workspace_dirs
  local cmd="${1:-help}"; shift || true

  case "$cmd" in
    help|-h|--help) log_line "help" "start" "-"; cmd_help; log_line "help" "success" "ok" ;;
    status)         log_line "status" "start" "-"; cmd_status; log_line "status" "success" "ok" ;;
    init|clean|restore|update|backup|add|theme)
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