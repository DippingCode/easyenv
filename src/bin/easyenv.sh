#!/usr/bin/env bash
# EasyEnv - CLI
# Núcleo: roteador, help, status, init -steps e logging

EASYENV_VERSION="0.1.0"

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

cmd_version(){
  echo "easyenv v$EASYENV_VERSION"
}

cmd_help(){
  cat <<EOF
EasyEnv v$EASYENV_VERSION — gerencie seu ambiente de desenvolvimento.

Uso:
  easyenv <comando> [opções]

Comandos:
  help             Mostra esta ajuda
  status           Mostra o status atual do workspace (YAMLs carregados, seções)
  init             Instala ferramentas por seções (dirigido por YAML)
                   Opções:
                     -steps        Modo interativo: pergunta por seção
                     -no-steps     Força modo não interativo (ignora snapshot)
                     -y, --yes     Auto-confirmar "sim" nas perguntas do -steps
                     -reload       Reinicia o shell ao final (exec zsh -l)
  clean            Remove ferramentas e/ou caches
                   Uso:
                     easyenv clean [-all|-soft] [-steps] [-section <nome>] [<tool> ...]
                   Exemplos:
                     easyenv clean -all
                     easyenv clean -soft
                     easyenv clean -steps -section "CLI Tools"
                     easyenv clean git fzf
  restore          (em breve) Restaurar workspace (all/section/tool/backup)
  update           (em breve) Atualizar ferramentas
  backup           (em breve) Criar um arquivo zip de backup
  add              (em breve) Adicionar ferramenta por nome
  theme            (em breve) Gerenciar temas do Oh My Zsh

Exemplos:
  easyenv status
  easyenv init -steps -y
  easyenv init -no-steps -reload
  easyenv clean -all
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
  local reload=0

  # se no snapshot preferências dizem para usar steps por default, ativa
  if [[ -f "$SNAP_FILE" ]]; then
    local def_steps
    def_steps="$(yq -r '.preferences.init.steps_mode_default // false' "$SNAP_FILE" || echo false)"
    [[ "$def_steps" == "true" ]] && steps=1
  fi

  # parametros CLI
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -steps) steps=1 ;;
      -reload) reload=1 ;;
      *) warn "Opção desconhecida: $1" ;;
    esac
    shift
  done

  local skip="$(yq -r '(.preferences.init.skip_sections // [])[]' "$SNAP_FILE" 2>/dev/null | tr '\n' ' ')"
  brew_update_quick || true

  echo
  _bld "Instalação por seções"
  if (( steps==1 )); then
    echo "Modo interativo (-steps) habilitado."
  fi
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
      if ! confirm "Deseja instalar a seção '$sec'? "; then
        info "Seção '$sec' ignorada."
        continue
      fi
    fi

    do_section_install "$sec"
  done

  if (( reload==1 )); then
    ok "Init concluído. Recarregando ~/.zshrc ..."
    exec zsh -l
  else
    ok "Init concluído. Rode: source ~/.zshrc"
  fi
}

cmd_clean(){
  ensure_workspace_dirs
  prime_brew_shellenv

  local mode="all"   # all | soft
  local steps=0
  local section=""
  local args_tools=()

  # parse flags
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -all)   mode="all" ;;
      -soft)  mode="soft" ;;
      -steps) steps=1 ;;
      -section)
        shift
        section="${1:-}"
        [[ -z "$section" ]] && { err "Faltou o nome da seção após -section"; exit 1; }
        ;;
      -*)
        warn "Opção desconhecida: $1"
        ;;
      *) # nomes de ferramentas
        args_tools+=("$1")
        ;;
    esac
    shift || true
  done

  # modo soft: só limpa caches/logs e marcadores
  if [[ "$mode" == "soft" ]]; then
    info "Limpeza (soft): logs, cache do Homebrew, marcadores do EasyEnv no .zshrc"
    zshrc_backup
    zshrc_remove_easyenv_markers
    rm -rf "$LOG_DIR"/* || true
    brew_cleanup_safe
    ok "Limpeza soft concluída."
    return 0
  fi

  # modo all (desinstalar ferramentas + limpar)
  # determina alvo (tools): argumentos explícitos > seção > todas
  local targets=()
  if (( ${#args_tools[@]} )); then
    mapfile -t targets < <(printf "%s\n" "${args_tools[@]}")
  elif [[ -n "$section" ]]; then
    mapfile -t targets < <(list_tools_by_section "$section")
    if (( ${#targets[@]} == 0 )); then
      warn "Seção '$section' não encontrada ou sem ferramentas."
      return 0
    fi
  else
    mapfile -t targets < <(list_all_tools)
  fi

  if (( ${#targets[@]} == 0 )); then
    warn "Nenhuma ferramenta alvo para remover."
    return 0
  fi

  echo
  _bld "Plano de remoção:"
  printf ' - %s\n' "${targets[@]}"

  if (( steps==1 )); then
    if ! confirm "Deseja prosseguir com a remoção destas ferramentas?"; then
      info "Operação cancelada."
      return 1
    fi
  fi

  # remove ferramentas
  for t in "${targets[@]}"; do
    uninstall_tool "$t" || warn "Falha ao desinstalar $t (continuando)."
  done

  # limpeza pós-remoção
  zshrc_backup
  zshrc_remove_easyenv_markers
  rm -rf "$LOG_DIR"/* || true
  brew_cleanup_safe

  ok "Clean concluído."
}

# --------------- Dispatcher ---------------

main(){
  ensure_workspace_dirs

  case "${1:-}" in
    -v|--version)
      log_line "version" "start" "-"
      cmd_version
      log_line "version" "success" "ok"
      exit 0
      ;;
  esac

  local cmd="${1:-help}"; shift || true

  case "$cmd" in
    help|-h|--help)      log_line "help" "start" "-";  cmd_help;   log_line "help" "success" "ok" ;;
    status)              log_line "status" "start" "-"; cmd_status; log_line "status" "success" "ok" ;;
    init)                log_line "init" "start" "-";   cmd_init "$@"; log_line "init" "success" "ok" ;;
    clean)               log_line "clean" "start" "-";   cmd_clean "$@"; log_line "clean" "success" "ok" ;;
    restore|update|backup|add|theme)
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