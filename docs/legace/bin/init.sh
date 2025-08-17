# INIT: instala ambiente (zero | default | stack)
cmd_init(){
  require_cmd "yq" "Instale com: brew install yq."
  ensure_workspace_dirs
  prime_brew_shellenv
  ensure_zprofile_prelude      # garante brew shellenv no login shell
  ensure_zshrc_prelude         # garante dedup de PATH no zshrc

  local steps=0
  local reload=0
  local autoy=0
  local force_no_steps=0
  local mode=""         # zero | default | stack
  local stack=""        # flutter | dotnet | web

  # steps default vindos do snapshot (se existir)
  if [[ -f "$SNAP_FILE" ]]; then
    local def_steps
    def_steps="$(yq -r '.preferences.init.steps_mode_default // false' "$SNAP_FILE" 2>/dev/null || echo false)"
    [[ "$def_steps" == "true" ]] && steps=1
  fi

  # parse flags
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -steps)       steps=1 ;;
      -no-steps)    steps=0; force_no_steps=1 ;;
      -reload)      reload=1 ;;
      -y|--yes)     autoy=1 ;;
      -mode)        shift; mode="${1:-}";;
      -stack)       shift; stack="${1:-}";;
      -h|--help)
        cat <<'HLP'
Uso: easyenv init [opções]

Modos:
  -mode zero        Limpa blocos/ajustes e instala a partir do zero (sem desinstalar fórmulas)
  -mode default     Instala conforme o catálogo (todas as seções)
  -mode stack       Instala uma stack específica (use -stack ...)

Stacks suportadas:
  -stack flutter    (dart+flutter+android+xcode+kotlin+java+firebase+supabase)
  -stack dotnet     (.NET SDK e utilidades associadas)
  -stack web        (pergunta Node/Deno e Angular/React)

Outras opções:
  -steps            Pergunta por seção e por ferramenta (modo default)
  -no-steps         Força não interativo
  -y, --yes         Auto-confirmar prompts
  -reload           Recarrega o shell ao final (exec zsh -l)

Exemplos:
  easyenv init -mode default -steps -y
  easyenv init -mode stack -stack flutter -reload
  easyenv init -mode zero
HLP
        return 0
        ;;
      *)
        warn "Opção desconhecida: $1"
        ;;
    esac
    shift || true
  done

  brew_update_quick || true
  echo

  # ----------------------------
  # Funções auxiliares locais
  # ----------------------------
  _install_one(){
    local t="$1"
    [[ -z "$t" || "$t" == "null" ]] && return 0

    # plugin?
    if plugin_load "$t" && declare -F tool_install >/dev/null 2>&1; then
      info "Instalando '$t' via plugin…"
      if plugin_call tool_install; then
        ok "$t instalado (plugin)."
        return 0
      else
        warn "Falha via plugin. Tentando catálogo/brew…"
      fi
    fi

    # via catálogo (tools.yml)
    if declare -F install_tool >/dev/null 2>&1; then
      if install_tool "$t"; then
        ok "$t instalado (catálogo)."
        return 0
      fi
      warn "Catálogo não conseguiu instalar '$t'. Tentando Homebrew direto…"
    fi

    # fallback: brew formula/cask
    if brew install "$t"; then
      ok "$t instalado (brew)."
      return 0
    fi
    if brew install --cask "$t"; then
      ok "$t instalado (cask)."
      return 0
    fi

    err "Falha ao instalar '$t'. Verifique nome/manager no tools.yml ou crie um plugin."
    return 1
  }

  _install_many(){
    local title="$1"; shift || true
    local arr=( "$@" )
    (( ${#arr[@]} == 0 )) && return 0

    echo
    _bld "Instalando: $title"
    for t in "${arr[@]}"; do
      # pode vir vazio por escolhas do usuário
      [[ -z "$t" || "$t" == "null" ]] && continue
      if (( steps==1 && autoy==0 )); then
        if ! confirm "Instalar '$t'?"; then
          info "Pulando $t."
          continue
        fi
      fi
      _install_one "$t"
    done
  }

  _prompt_mode(){
    local choice
    echo "Selecione o modo de instalação:"
    echo "  1) Instalação do zero (reset de blocos e prelúdios)"
    echo "  2) Instalação default (catálogo completo)"
    echo "  3) Instalação por stack (flutter | dotnet | web)"
    read -r -p "Escolha [1-3]: " choice
    case "$choice" in
      1) mode="zero" ;;
      2) mode="default" ;;
      3) mode="stack" ;;
      *) mode="default" ;;
    esac
  }

  _prompt_stack(){
    local choice
    echo "Stacks disponíveis:"
    echo "  1) flutter"
    echo "  2) dotnet"
    echo "  3) web"
    read -r -p "Escolha [1-3]: " choice
    case "$choice" in
      1) stack="flutter" ;;
      2) stack="dotnet" ;;
      3) stack="web" ;;
      *) stack="web" ;;
    esac
  }

  # ----------------------------
  # Escolha do modo / stack
  # ----------------------------
  [[ -z "$mode" ]] && _prompt_mode
  if [[ "$mode" == "stack" && -z "$stack" ]]; then
    _prompt_stack
  fi

  # ----------------------------
  # MODO: ZERO
  # - Não sai desinstalando fórmulas; apenas
  #   * limpa blocos EasyEnv do ~/.zshrc
  #   * garante prelúdios padrão
  #   * segue para uma stack rápida default (opcional)
  # ----------------------------
  if [[ "$mode" == "zero" ]]; then
    echo
    _bld "Inicialização do zero (reset de blocos e prelúdios)"
    zshrc_backup

    # remove blocos de ferramentas comuns (idempotente)
    for t in android nvm fvm python dotnet java go rust deno kotlin angular flutter; do
      zshrc_remove_tool_blocks "$t" 2>/dev/null || true
    done
    ensure_zprofile_prelude
    ensure_zshrc_prelude
    ok "Ambiente base pronto (prelúdios aplicados)."

    # pergunta se quer seguir com default/stack após reset
    if (( autoy==1 )) || confirm "Deseja seguir com instalação default (catálogo completo)?"; then
      mode="default"
    else
      if confirm "Deseja seguir com instalação por stack?"; then
        mode="stack"
        _prompt_stack
      else
        ok "Init (zero) concluído. Rode: source ~/.zshrc"
        return 0
      fi
    fi
  fi

  # ----------------------------
  # MODO: DEFAULT (catálogo inteiro)
  # ----------------------------
  if [[ "$mode" == "default" ]]; then
    echo
    _bld "Instalação por seções (DEFAULT)"
    (( steps==1 )) && echo "Modo interativo (-steps) habilitado."
    echo

    local skip=""
    if [[ -f "$SNAP_FILE" ]]; then
      skip="$(yq -r '.preferences.init.skip_sections[]? // empty' "$SNAP_FILE" 2>/dev/null | tr '\n' ' ')"
    fi

    local sections; mapfile -t sections < <(list_sections)
    if (( ${#sections[@]} == 0 )); then
      err "Nenhuma seção encontrada em $CFG_FILE (.tools[].section)."
      exit 1
    fi

    for sec in "${sections[@]}"; do
      if [[ " $skip " == *" $sec "* ]]; then
        info "Pulando seção '$sec' (configurada para pular)."
        continue
      fi

      if (( steps==1 && autoy==0 )); then
        if ! confirm "Deseja instalar a seção '$sec'?"; then
          info "Seção '$sec' ignorada."
          continue
        fi
      fi

      local tools; mapfile -t tools < <(list_tools_by_section "$sec")
      (( ${#tools[@]} == 0 )) && { warn "Seção '$sec' sem ferramentas."; continue; }

      echo "➜ Instalando seção: $sec"
      for t in "${tools[@]}"; do
        if (( steps==1 && autoy==0 )); then
          if ! confirm "Instalar '$t'?"; then
            info "Pulando $t."
            continue
          fi
        fi
        _install_one "$t"
      done
      echo
    done

    ensure_zprofile_prelude
    ensure_zshrc_prelude

    if (( reload==1 )); then
      ok "Init (default) concluído. Recarregando shell…"
      exec zsh -l
    else
      ok "Init (default) concluído. Rode: source ~/.zshrc"
    fi
    return 0
  fi

  # ----------------------------
  # MODO: STACK
  # ----------------------------
  if [[ "$mode" == "stack" ]]; then
    case "$stack" in
      flutter)
        # pacote Flutter
        # (flutter já traz dart; android/xcode/kotlin/java para mobile; firebase/supabase CLIs)
        local flutter_tools=(flutter android java kotlin firebase supabase)
        _install_many "Flutter stack (núcleo)" "${flutter_tools[@]}"

        # Xcode é cask; mantenha como 'xcode' no catálogo se tiver entrada
        # (ou o usuário já tem instalado manualmente)
        if confirm "Também deseja instalar Xcode (via App Store/manual)? (Responder 'no' se já tiver)"; then
          info "Dica: instale via App Store. Se tiver cask próprio no catálogo, adicione entrada 'xcode' e rodaremos via brew cask."
        fi
        ;;

      dotnet)
        local dotnet_tools=(dotnet)
        _install_many ".NET stack" "${dotnet_tools[@]}"

        # Ferramentas úteis .NET extra (opcional)
        if (( autoy==1 )) || confirm "Instalar utilitários extras (.NET tool workloads)?"; then
          # Se tiver entradas no catálogo para dotnet-ef, etc., adicione aqui:
          # _install_many ".NET extras" dotnet-ef
          info "Sem extras no catálogo por enquanto."
        fi
        ;;

      web)
        # Runtimes
        local want_node="" want_deno=""
        if (( autoy==1 )); then
          want_node="y"; want_deno="y"
        else
          read -r -p "Instalar Node (NVM + node)? [y/N] " want_node
          read -r -p "Instalar Deno? [y/N] " want_deno
        fi

        local runtimes=()
        [[ "$want_node" =~ ^[yY] ]] && runtimes+=(node)
        [[ "$want_deno" =~ ^[yY] ]] && runtimes+=(deno)
        _install_many "Web runtimes" "${runtimes[@]}"

        # Frameworks
        local fw_choice
        if (( autoy==1 )); then
          fw_choice="3"
        else
          echo "Frameworks web:"
          echo "  1) Angular"
          echo "  2) React"
          echo "  3) Ambos"
          read -r -p "Escolha [1-3]: " fw_choice
        fi

        case "$fw_choice" in
          1) _install_many "Framework: Angular" angular ;;
          2)
            # React não é “ferramenta” única — instale utilitários (opcional)
            if command -v npm >/dev/null 2>&1; then
              info "Instalando utilitários React (vite) via npm…"
              bash -lc 'npm i -g create-vite' || true
            else
              warn "npm não disponível; pulei utilitários React."
            fi
            ;;
          3)
            _install_many "Framework: Angular" angular
            if command -v npm >/dev/null 2>&1; then
              info "Instalando utilitários React (vite) via npm…"
              bash -lc 'npm i -g create-vite' || true
            else
              warn "npm não disponível; pulei utilitários React."
            fi
            ;;
          *) warn "Opção inválida; pulando frameworks." ;;
        esac
        ;;

      *)
        err "Stack desconhecida: $stack (use flutter | dotnet | web)."
        return 1
        ;;
    esac

    # Pós-instalação comum
    ensure_zprofile_prelude
    ensure_zshrc_prelude
    if (( reload==1 )); then
      ok "Init (stack: $stack) concluído. Recarregando shell…"
      exec zsh -l
    else
      ok "Init (stack: $stack) concluído. Rode: source ~/.zshrc"
    fi
    return 0
  fi

  # fallback se algo cair fora do fluxo
  warn "Nada a fazer no init. Use: -mode zero|default|stack"
  return 0
}