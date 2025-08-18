# =========================
# ADD: instalar e catalogar
# =========================
cmd_add(){
  ensure_workspace_dirs
  prime_brew_shellenv
  require_cmd "yq"  "Instale yq com: brew install yq."
  require_cmd "brew" "Instale Homebrew: https://brew.sh"

  local section="CLI Tools"
  local manager=""          # brew|cask|npm
  local zshrc_block=""
  local autoy=0

  local args=()
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -section|--section) shift; section="${1:-CLI Tools}" ;;
      --manager)          shift; manager="${1:-}" ;;
      --zshrc-block)      shift; zshrc_block="${1:-}" ;;
      -y|--yes)           autoy=1 ;;
      -h|--help)          cmd_add_help; return 0 ;;
      *)                  args+=("$1") ;;
    esac
    shift || true
  done

  local name="${args[0]:-}"
  [[ -z "$name" ]] && { err "Uso: easyenv add [-section \"Seção\"] [--manager brew|cask|npm] [--zshrc-block '...'] <tool>"; return 1; }

  # -------- detecção do manager se não informado --------
  local id_form="" id_cask="" npm_ok=0
  if [[ -z "$manager" ]]; then
    # tenta fórmula brew exata (com sua função guess_brew_formula se existir)
    if command -v guess_brew_formula >/dev/null 2>&1; then
      id_form="$(guess_brew_formula "$name" || true)"
    fi
    # fallback: busca direta (exata) por formula
    if [[ -z "$id_form" ]]; then
      id_form="$(brew search --formula --eval-all "^${name}\$" 2>/dev/null | grep -x "$name" || true)"
    fi

    if [[ -n "$id_form" ]]; then
      manager="brew"
    else
      # tenta cask exato
      id_cask="$(brew search --cask "^${name}\$" 2>/dev/null | grep -x "$name" || true)"
      if [[ -n "$id_cask" ]]; then
        manager="cask"
      else
        # tenta npm (precisa npm disponível)
        if command -v npm >/dev/null 2>&1 && npm view "$name" version >/dev/null 2>&1; then
          manager="npm"; npm_ok=1
        else
          warn "Não foi possível inferir o gerenciador automaticamente. Tentarei Homebrew (formula)."
          manager="brew"; id_form="$name"
        fi
      fi
    fi
  fi

  # normaliza identificador conforme manager
  case "$manager" in
    brew)
      [[ -z "$id_form" ]] && id_form="${name}"
      info "Fórmula candidata (brew): $id_form"
      ;;
    cask)
      [[ -z "$id_cask" ]] && id_cask="${name}"
      info "Cask candidato (brew cask): $id_cask"
      ;;
    npm)
      if (( npm_ok==0 )) && ! (command -v npm >/dev/null 2>&1 && npm view "$name" version >/dev/null 2>&1); then
        err "npm ou pacote '$name' indisponível. Informe --manager brew/cask ou instale npm primeiro."
        return 1
      fi
      info "Pacote global (npm): $name"
      ;;
    *)
      err "Manager inválido: $manager (use brew|cask|npm)"; return 1 ;;
  esac

  # -------- confirmação ----------
  if (( autoy==0 )); then
    case "$manager" in
      brew)  confirm "Instalar '${id_form}' via Homebrew (formula) e registrar no catálogo?" || { info "Operação cancelada."; return 1; };;
      cask)  confirm "Instalar '${id_cask}' via Homebrew (cask) e registrar no catálogo?"   || { info "Operação cancelada."; return 1; };;
      npm)   confirm "Instalar '${name}' globalmente via npm e registrar no catálogo?"       || { info "Operação cancelada."; return 1; };;
    esac
  fi

  # -------- instalação ----------
  case "$manager" in
    brew)
      if ! brew list --formula | grep -qx "$id_form"; then
        info "Instalando (brew): $id_form"
        brew install "$id_form"
      else
        info "Já instalado (brew formula): $id_form"
      fi
      ;;
    cask)
      if ! brew list --cask | grep -qx "$id_cask"; then
        info "Instalando (brew cask): $id_cask"
        brew install --cask "$id_cask"
      else
        info "Já instalado (brew cask): $id_cask"
      fi
      ;;
    npm)
      info "Instalando global (npm): $name"
      npm install -g "$name"
      ;;
  esac

  # -------- registrar no catálogo (tools.yml) ----------
  __add_tool_to_catalog "$name" "$manager" "$section" "$id_form" "$id_cask"

  # -------- bloco opcional no .zshrc ----------
  if [[ -n "$zshrc_block" ]]; then
    inject_zshrc_block "$name" "$zshrc_block" "default"
  fi

  ok "easyenv add concluído: '$name' (manager=$manager, seção=\"$section\")."
}

cmd_add_help(){
  cat <<'EOF'
Uso:
  easyenv add [-section "<Seção>"] [--manager brew|cask|npm] [--zshrc-block '<conteúdo>'] [-y] <tool>

Exemplos:
  easyenv add jq
  easyenv add -section "CLI Tools" yq
  easyenv add --manager cask iterm2
  easyenv add --manager npm @angular/cli -section "Web" -y
  easyenv add bat --zshrc-block 'alias cat="bat"'

Notas:
- Se --manager não for informado, o easyenv tenta: brew (formula exata) → brew (cask exato) → npm.
- O tools.yml é atualizado com: name, section, manager e o identificador correspondente (formula/cask/npm_global).
EOF
}

# -----------------------
# Helpers internos (YAML)
# -----------------------
__yaml_has_tool(){
  local name="$1"
  yq -e ".tools[] | select(.name==\"$name\")" "$CFG_FILE" >/dev/null 2>&1
}

__ensure_tools_array(){
  if ! yq -e '.tools' "$CFG_FILE" >/dev/null 2>&1; then
    info "Criando estrutura base em $CFG_FILE…"
    printf "tools: []\n" > "$CFG_FILE"
  fi
}

__append_yaml(){
  # Acrescenta entrada YAML ao final (sem sobrescrever outras)
  local payload="$1"
  # Garante .tools array
  __ensure_tools_array
  # Apenas concatena ao fim do arquivo (mantendo YAML válido)
  printf "\n%s\n" "$payload" >> "$CFG_FILE"
}

__add_tool_to_catalog(){
  local name="$1" manager="$2" section="$3" id_form="$4" id_cask="$5"

  if __yaml_has_tool "$name"; then
    warn "Ferramenta '$name' já existe no catálogo — não vou duplicar."
    return 0
  fi

  local payload
  case "$manager" in
    brew)
      payload=$(cat <<YML
- name: $name
  section: $section
  manager: brew
  formula: ${id_form:-$name}
YML
)
      ;;
    cask)
      payload=$(cat <<YML
- name: $name
  section: $section
  manager: cask
  cask: ${id_cask:-$name}
YML
)
      ;;
    npm)
      payload=$(cat <<YML
- name: $name
  section: $section
  manager: npm_global
  npm_global: $name
YML
)
      ;;
    *)
      # fallback seguro
      payload=$(cat <<YML
- name: $name
  section: $section
  manager: brew
  formula: ${id_form:-$name}
YML
)
      ;;
  esac

  __append_yaml "$payload"
  ok "tools.yml atualizado com '$name' (seção: $section, manager: $manager)."
}