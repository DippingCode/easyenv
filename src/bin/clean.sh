# CLEAN: remove ferramentas e/ou caches
cmd_clean(){
  ensure_workspace_dirs
  prime_brew_shellenv

  local mode="all"   # all | soft
  local steps=0
  local section=""
  local dryrun=0
  local args_tools=()

  # parse flags
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -all)      mode="all" ;;
      -soft)     mode="soft" ;;
      -steps)    steps=1 ;;
      -section)  shift; section="${1:-}"; [[ -z "$section" ]] && { err "Faltou o nome da seção após -section"; exit 1; } ;;
      --dry-run) dryrun=1 ;;
      -h|--help) cmd_clean_help; return 0 ;;
      -*)
        warn "Opção desconhecida: $1"
        ;;
      *)
        args_tools+=("$1")
        ;;
    esac
    shift || true
  done

  # ---------- SOFT ----------
  if [[ "$mode" == "soft" ]]; then
    echo
    _bld "Limpeza (soft)"
    info "Ações: remover logs, brew cleanup (safe), limpar auxiliares do zsh e restaurar prelúdios."

    if (( dryrun==1 )); then
      echo
      _bld "(dry-run) Plano:"
      echo " - zshrc_backup (não será executado)"
      echo " - (remover blocos easyenv por ferramenta) (não será executado)"
      echo " - rm -rf \"$LOG_DIR\"/* (não será executado)"
      echo " - brew cleanup -s (não será executado)"
      echo " - cleanup_zsh_aux_files (não será executado)"
      echo " - ensure_zprofile_prelude / ensure_zshrc_prelude (não será executado)"
      info "(dry-run) Nenhuma alteração foi feita."
      return 0
    fi

    zshrc_backup

    # Remova blocos mais comuns geridos pelo easyenv (idempotente)
    for t in android nvm fvm python dotnet java go rust deno kotlin angular; do
      zshrc_remove_tool_blocks "$t" 2>/dev/null || true
    done

    rm -rf "$LOG_DIR"/* || true
    brew_cleanup_safe
    cleanup_zsh_aux_files
    ensure_zprofile_prelude
    ensure_zshrc_prelude

    ok "Limpeza soft concluída."
    return 0
  fi

  # ---------- ALL ----------
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

  if (( dryrun==1 )); then
    info "(dry-run) Nenhuma alteração será feita."
    return 0
  fi

  if (( steps==1 )); then
    if ! confirm "Deseja prosseguir com a remoção destas ferramentas?"; then
      info "Operação cancelada."
      return 1
    fi
  fi

  for t in "${targets[@]}"; do
    if (( steps==1 )); then
      if ! confirm "Remover '$t'?"; then
        info "Pulando $t."
        continue
      fi
    fi

    local ver
    ver="$(_tool_field "$t" ".version")"
    [[ "$ver" == "null" ]] && ver=""

    # 1) tenta plugin: tool_uninstall
    if call_plugin_func_if_exists "$t" tool_uninstall "${ver:-}"; then
      ok "$t removido (plugin)."
    # 2) tenta catálogo
    elif uninstall_tool "$t" "${ver:-}"; then
      ok "$t removido (catálogo)."
    else
      # 3) fallback brew
      info "Removendo $t via Homebrew (formula/cask)…"
      brew list --formula | grep -qx "$t" && brew uninstall "$t" || true
      brew list --cask    | grep -qx "$t" && brew uninstall --cask "$t" || true
      ok "$t removido (brew)."
    fi

    # Remover blocos dessa ferramenta do ~/.zshrc
    zshrc_remove_tool_blocks "$t" 2>/dev/null || true
  done

  zshrc_backup
  brew_cleanup_safe
  cleanup_zsh_aux_files
  ensure_zprofile_prelude
  ensure_zshrc_prelude

  ok "Clean concluído."
}

cmd_clean_help(){
  cat <<EOF
Uso: easyenv clean [-all|-soft] [-steps] [-section <nome>] [--dry-run] [<tool>...]

Exemplos:
  easyenv clean -all
  easyenv clean -soft --dry-run
  easyenv clean -steps -section "CLI Tools"
  easyenv clean git fzf
EOF
}