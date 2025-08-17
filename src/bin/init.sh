cmd_init(){
  require_cmd "yq" "Instale com: brew install yq."
  ensure_workspace_dirs
  prime_brew_shellenv
  ensure_zprofile_prelude      # garante brew shellenv no login shell
  ensure_zshrc_prelude         # garante dedup de PATH no zshrc

  local steps=0
  local reload=0
  local autoy=0      # -y/--yes
  local force_no_steps=0

  # steps default vindos do snapshot (se existir)
  if [[ -f "$SNAP_FILE" ]]; then
    local def_steps
    def_steps="$(yq -r '.preferences.init.steps_mode_default // false' "$SNAP_FILE" 2>/dev/null || echo false)"
    [[ "$def_steps" == "true" ]] && steps=1
  fi

  # parse flags
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -steps)    steps=1 ;;
      -no-steps) steps=0; force_no_steps=1 ;;
      -reload)   reload=1 ;;
      -y|--yes)  autoy=1 ;;
      *)
        warn "Opção desconhecida: $1"
        ;;
    esac
    shift || true
  done

  # skip_sections do snapshot (opcional)
  local skip=""
  if [[ -f "$SNAP_FILE" ]]; then
    skip="$(yq -r '.preferences.init.skip_sections[]? // empty' "$SNAP_FILE" 2>/dev/null | tr '\n' ' ')"
  fi

  brew_update_quick || true

  echo
  _bld "Instalação por seções"
  (( steps==1 )) && echo "Modo interativo (-steps) habilitado."
  echo

  # coleta seções a partir do catálogo
  local sections; mapfile -t sections < <(list_sections)
  if (( ${#sections[@]} == 0 )); then
    err "Nenhuma seção encontrada em $CFG_FILE (.tools[].section)."
    exit 1
  fi

  for sec in "${sections[@]}"; do
    # pular seção se estiver listada em skip_sections
    if [[ " $skip " == *" $sec "* ]]; then
      info "Pulando seção '$sec' (configurada para pular)."
      continue
    fi

    # pergunta por seção quando -steps e não houver -y
    if (( steps==1 && autoy==0 )); then
      if ! confirm "Deseja instalar a seção '$sec'?"; then
        info "Seção '$sec' ignorada."
        continue
      fi
    fi

    # lista ferramentas da seção
    local tools; mapfile -t tools < <(list_tools_by_section "$sec")
    if (( ${#tools[@]} == 0 )); then
      warn "Seção '$sec' não possui ferramentas no catálogo."
      continue
    fi

    echo "➜ Instalando seção: $sec"
    for t in "${tools[@]}"; do
      # confirmação por ferramenta quando -steps sem -y
      if (( steps==1 && autoy==0 )); then
        if ! confirm "Instalar '$t'?"; then
          info "Pulando $t."
          continue
        fi
      fi

      # 1) tenta plugin: tool_install
      if plugin_load "$t" && declare -F tool_install >/dev/null 2>&1; then
        info "Instalando '$t' via plugin…"
        if plugin_call tool_install; then
          ok "$t instalado (plugin)."
          continue
        else
          warn "Falha ao instalar '$t' via plugin. Tentando fallback (catálogo/Homebrew)…"
        fi
      fi

      # 2) tenta operador do core (install_tool) — usa dados do tools.yml
      if declare -F install_tool >/dev/null 2>&1; then
        if install_tool "$t"; then
          ok "$t instalado (catálogo)."
          continue
        fi
        warn "Catálogo não conseguiu instalar '$t'. Tentando Homebrew direto…"
      fi

      # 3) fallback: brew formula / cask diretos
      if brew install "$t"; then
        ok "$t instalado (brew)."
        continue
      fi
      if brew install --cask "$t"; then
        ok "$t instalado (cask)."
        continue
      fi

      err "Falha ao instalar '$t'. Verifique nome/manager no tools.yml ou crie um plugin."
    done

    echo
  done

  # Pós-instalação: re-injete prelúdios para garantir consistência
  ensure_zprofile_prelude
  ensure_zshrc_prelude

  if (( reload==1 )); then
    ok "Init concluído. Recarregando shell…"
    exec zsh -l
  else
    ok "Init concluído. Rode: source ~/.zshrc"
  fi
}