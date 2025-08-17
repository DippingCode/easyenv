#!/usr/bin/env bash
# tools.sh — operações dirigidas por YAML (install/upgrade/uninstall) + hooks/env/paths/checks

set -euo pipefail

# Dependências externas esperadas:
#  - yq (v4)
#  - brew
# Helpers vindos de utils.sh/workspace.sh:
#  - ok, info, warn, err, _bld, confirm
#  - ensure_dir, append_once, zshrc_backup, ensure_zprofile_prelude, ensure_zshrc_prelude

# -----------------------------------------------------------
# Acesso ao catálogo YAML
# -----------------------------------------------------------
CFG_FILE="${CFG_FILE:-$EASYENV_HOME/src/config/tools.yml}"
SNAP_FILE="${SNAP_FILE:-$EASYENV_HOME/src/config/.zshrc-tools.yml}"

list_sections(){
  [[ -f "$CFG_FILE" ]] || { echo ""; return 0; }
  yq -r '.tools[].section' "$CFG_FILE" 2>/dev/null | sort -u
}

list_all_tools(){
  [[ -f "$CFG_FILE" ]] || { echo ""; return 0; }
  yq -r '.tools[].name' "$CFG_FILE" 2>/dev/null
}

list_tools_by_section(){
  local section="$1"
  [[ -f "$CFG_FILE" ]] || { echo ""; return 0; }
  yq -r --arg sec "$section" '.tools[] | select(.section == $sec) | .name' "$CFG_FILE" 2>/dev/null
}

get_tool_obj(){ # imprime JSON do objeto tool
  local name="$1"
  yq -o=json -r --arg n "$name" '.tools[] | select(.name==$n)' "$CFG_FILE" 2>/dev/null || true
}

get_tool_field(){ # get campo simples do objeto
  local name="$1" field="$2"
  yq -r --arg n "$name" --arg f "$field" '.tools[] | select(.name==$n) | .[$f] // empty' "$CFG_FILE" 2>/dev/null || true
}

# -----------------------------------------------------------
# Marcadores por ferramenta no ~/.zshrc
#   Formato:
#   # >>> easyenv:tool:<NAME>
#   export VAR=...
#   export PATH="X:$PATH"
#   # <<< easyenv:tool:<NAME>
# -----------------------------------------------------------
zshrc_tool_block_add(){
  local name="$1" body="$2"
  local start="# >>> easyenv:tool:${name}"
  local end="# <<< easyenv:tool:${name}"
  local file="$HOME/.zshrc"

  zshrc_backup
  touch "$file"

  # remove bloco anterior, se existir
  if grep -qF "$start" "$file"; then
    # remove da linha start até end (inclusive)
    perl -0777 -pe 'BEGIN{ $^I=""; } s/\n?# >>> easyenv:tool:'"$name"'.*?\n?# <<< easyenv:tool:'"$name"'[^\n]*\n?//s' -i "$file"
  fi

  {
    echo "$start"
    echo "$body"
    echo "$end"
  } >> "$file"
}

zshrc_tool_block_remove(){
  local name="$1"
  local file="$HOME/.zshrc"
  local start="# >>> easyenv:tool:${name}"
  if [[ -f "$file" ]] && grep -qF "$start" "$file"; then
    zshrc_backup
    perl -0777 -pe 'BEGIN{ $^I=""; } s/\n?# >>> easyenv:tool:'"$name"'.*?\n?# <<< easyenv:tool:'"$name"'[^\n]*\n?//s' -i "$file"
    ok "Bloco do .zshrc removido (tool: $name)."
  fi
}

# -----------------------------------------------------------
# ENV & PATHs por ferramenta
# -----------------------------------------------------------
inject_env_and_paths(){
  local name="$1"

  # monta corpo do bloco
  local body=""
  # env (mapa VAR=valor)
  local env_count
  env_count="$(yq -r --arg n "$name" '.tools[] | select(.name==$n) | .env | length // 0' "$CFG_FILE" 2>/dev/null || echo 0)"
  if (( env_count > 0 )); then
    # para cada par chave:valor
    while IFS= read -r line; do
      local k v
      k="$(echo "$line" | cut -d'|' -f1)"
      v="$(echo "$line" | cut -d'|' -f2-)"
      body+=$'export '"$k"'='"'"$v"'"$'\n'
    done < <(yq -r --arg n "$name" '.tools[] | select(.name==$n) | .env | to_entries[] | "\(.key)|\(.value)"' "$CFG_FILE")
  fi

  # paths (lista)
  local path_len
  path_len="$(yq -r --arg n "$name" '.tools[] | select(.name==$n) | .paths | length // 0' "$CFG_FILE" 2>/dev/null || echo 0)"
  if (( path_len > 0 )); then
    body+=$'# PATHs da ferramenta (prepend)\n'
    while IFS= read -r p; do
      # expand ~ em runtime (zsh), não aqui
      body+=$'if [ -d '"\"$p\""']; then export PATH='"\"$p"':$PATH'"; fi\n"
    done < <(yq -r --arg n "$name" '.tools[] | select(.name==$n) | .paths[]' "$CFG_FILE")
  fi

  if [[ -n "$body" ]]; then
    zshrc_tool_block_add "$name" "$body"
    ok "ENV/PATH aplicados no ~/.zshrc (tool: $name)."
  fi
}

remove_env_and_paths(){
  local name="$1"
  zshrc_tool_block_remove "$name"
}

# -----------------------------------------------------------
# Hooks: post_install / post_uninstall
# -----------------------------------------------------------
_run_cmds(){
  local desc="$1"; shift || true
  local cmds=("$@")
  (( ${#cmds[@]} == 0 )) && return 0

  _bld "$desc"
  local c
  for c in "${cmds[@]}"; do
    info "\$ $c"
    # executa em bash -lc para expandir ~, PATH atualizado do shell
    bash -lc "$c" || { warn "Comando falhou: $c (continuando)"; }
  done
}

run_post_install(){
  local name="$1"
  local count
  count="$(yq -r --arg n "$name" '.tools[] | select(.name==$n) | .post_install | length // 0' "$CFG_FILE" 2>/dev/null || echo 0)"
  (( count==0 )) && return 0
  mapfile -t cmds < <(yq -r --arg n "$name" '.tools[] | select(.name==$n) | .post_install[]' "$CFG_FILE")
  _run_cmds "Pós-instalação ($name)" "${cmds[@]}"
}

run_post_uninstall(){
  local name="$1"
  local count
  count="$(yq -r --arg n "$name" '.tools[] | select(.name==$n) | .post_uninstall | length // 0' "$CFG_FILE" 2>/dev/null || echo 0)"
  (( count==0 )) && return 0
  mapfile -t cmds < <(yq -r --arg n "$name" '.tools[] | select(.name==$n) | .post_uninstall[]' "$CFG_FILE")
  _run_cmds "Pós-remoção ($name)" "${cmds[@]}"
}

# -----------------------------------------------------------
# Instalar / Remover / Atualizar ferramenta
# - Suporta brew formula e/ou cask em .install.brew e .install.cask
# -----------------------------------------------------------
_install_via_brew(){
  local formula="$1"
  if brew list "$formula" >/dev/null 2>&1; then
    info "brew: $formula já instalado."
  else
    info "brew install $formula"
    brew install "$formula"
  fi
}

_install_cask_via_brew(){
  local cask="$1"
  if brew list --cask "$cask" >/dev/null 2>&1; then
    info "brew cask: $cask já instalado."
  else
    info "brew install --cask $cask"
    brew install --cask "$cask"
  fi
}

# install_tool <tool>
# instala a ferramenta <tool> conforme definido no tools.yml
install_tool(){
  local tool="$1"
  [[ -z "$tool" ]] && { err "Uso: install_tool <tool>"; return 1; }
  [[ ! -f "$CFG_FILE" ]] && { err "Catálogo não encontrado em $CFG_FILE"; return 1; }

  # extrai campos do catálogo
  local manager formula cask npm_global post_install zshrc_blocks
  manager="$(yq -r ".tools[] | select(.name==\"$tool\") | .manager // empty" "$CFG_FILE")"
  formula="$(yq -r ".tools[] | select(.name==\"$tool\") | .formula // empty" "$CFG_FILE")"
  cask="$(yq -r ".tools[] | select(.name==\"$tool\") | .cask // empty" "$CFG_FILE")"
  npm_global="$(yq -r ".tools[] | select(.name==\"$tool\") | .npm_global // empty" "$CFG_FILE")"
  post_install="$(yq -r ".tools[] | select(.name==\"$tool\") | .post_install // empty" "$CFG_FILE")"
  zshrc_blocks="$(yq -r ".tools[] | select(.name==\"$tool\") | .zshrc_blocks[]? // empty" "$CFG_FILE" | tr '\n' ';')"

  # fallback: se não definiu manager, assume brew
  [[ -z "$manager" ]] && manager="brew"

  case "$manager" in
    brew)
      if [[ -n "$formula" ]]; then
        info "Instalando $tool (brew formula: $formula)…"
        brew install "$formula"
      elif [[ -n "$cask" ]]; then
        info "Instalando $tool (brew cask: $cask)…"
        brew install --cask "$cask"
      else
        info "Instalando $tool (brew: $tool)…"
        brew install "$tool"
      fi
      ;;
    cask)
      local target="${cask:-$tool}"
      info "Instalando $tool (brew cask: $target)…"
      brew install --cask "$target"
      ;;
    npm_global)
      local pkg="${npm_global:-$tool}"
      require_cmd "npm" "Instale Node/npm antes."
      info "Instalando $tool globalmente via npm ($pkg)…"
      npm install -g "$pkg"
      ;;
    *)
      warn "Manager '$manager' não suportado ainda para '$tool'."
      return 1
      ;;
  esac

  # post_install: comandos extras após instalar
  if [[ -n "$post_install" && "$post_install" != "null" ]]; then
    info "Executando pós-instalação para $tool…"
    bash -lc "$post_install" || warn "Falha no pós-install de $tool"
  fi

  # zshrc_blocks: blocos de configuração adicionais
  if [[ -n "$zshrc_blocks" ]]; then
    info "Injetando blocos de configuração no ~/.zshrc…"
    IFS=';' read -ra blocks <<< "$zshrc_blocks"
    for block in "${blocks[@]}"; do
      inject_zshrc_block "$tool" "$block"
    done
  fi

  return 0
}

uninstall_tool(){
  local name="$1"
  local brew_formula cask_name
  brew_formula="$(yq -r --arg n "$name" '.tools[] | select(.name==$n) | .install.brew // empty' "$CFG_FILE")"
  cask_name="$(yq -r --arg n "$name" '.tools[] | select(.name==$n) | .install.cask // empty' "$CFG_FILE")"

  _bld "Desinstalando $name"
  # brew uninstall silencioso se não existir
  if [[ -n "$brew_formula" && "$brew_formula" != "null" ]]; then
    if brew list "$brew_formula" >/dev/null 2>&1; then
      info "brew uninstall $brew_formula"
      brew uninstall "$brew_formula" || warn "Falha ao desinstalar $brew_formula"
    else
      info "brew: $brew_formula não está instalado (formula)."
    fi
  fi
  if [[ -n "$cask_name" && "$cask_name" != "null" ]]; then
    if brew list --cask "$cask_name" >/dev/null 2>&1; then
      info "brew uninstall --cask $cask_name"
      brew uninstall --cask "$cask_name" || warn "Falha ao desinstalar cask $cask_name"
    else
      info "brew: $cask_name não está instalado (cask)."
    fi
  fi

  run_post_uninstall "$name"
  remove_env_and_paths "$name"
  ok "$name removido."
}

upgrade_tool(){
  local name="$1"
  local brew_formula cask_name
  brew_formula="$(yq -r --arg n "$name" '.tools[] | select(.name==$n) | .install.brew // empty' "$CFG_FILE")"
  cask_name="$(yq -r --arg n "$name" '.tools[] | select(.name==$n) | .install.cask // empty' "$CFG_FILE")"

  _bld "Atualizando $name"
  brew update || true
  if [[ -n "$brew_formula" && "$brew_formula" != "null" ]]; then
    if brew list "$brew_formula" >/dev/null 2>&1; then
      info "brew upgrade $brew_formula"
      brew upgrade "$brew_formula" || warn "Falha ao atualizar $brew_formula"
    else
      info "brew: $brew_formula não instalado. Instalando…"
      brew install "$brew_formula"
    fi
  fi
  if [[ -n "$cask_name" && "$cask_name" != "null" ]]; then
    if brew list --cask "$cask_name" >/dev/null 2>&1; then
      info "brew upgrade --cask $cask_name"
      brew upgrade --cask "$cask_name" || warn "Falha ao atualizar cask $cask_name"
    else
      info "brew: cask $cask_name não instalado. Instalando…"
      brew install --cask "$cask_name"
    fi
  fi

  # Reaplica ENV/PATH (idempotente: substitui bloco da ferramenta)
  inject_env_and_paths "$name"
  ok "$name atualizado."
}

do_section_install(){
  local section="$1"
  _bld "Instalando seção: $section"
  while IFS= read -r tool; do
    [[ -z "$tool" || "$tool" == "null" ]] && continue
    install_tool "$tool"
  done < <(list_tools_by_section "$section")
}

restore_section(){
  local section="$1"
  _bld "Restaurando seção: $section"
  while IFS= read -r tool; do
    [[ -z "$tool" || "$tool" == "null" ]] && continue
    # reinstala (uninstall + install) para garantir hooks/ENV/PATH
    uninstall_tool "$tool" || true
    install_tool "$tool"
  done < <(list_tools_by_section "$section")
}

# -----------------------------------------------------------
# Checks (para status --detailed)
#  - tools[].check: lista de comandos (string)
#  Retorno: imprime "OK: <first line>" ou "FAIL: <msg>"
# -----------------------------------------------------------
tool_check_report(){
  local name="$1"
  local count
  count="$(yq -r --arg n "$name" '.tools[] | select(.name==$n) | .check | length // 0' "$CFG_FILE" 2>/dev/null || echo 0)"
  (( count==0 )) && { echo "-"; return 0; }

  local ok_any=0 out_first=""
  while IFS= read -r cmd; do
    [[ -z "$cmd" || "$cmd" == "null" ]] && continue
    if out="$(bash -lc "$cmd" 2>/dev/null | head -n1)"; then
      [[ -n "$out" ]] && out_first="$out"
      ok_any=1
      break
    fi
  done < <(yq -r --arg n "$name" '.tools[] | select(.name==$n) | .check[]' "$CFG_FILE")

  if (( ok_any==1 )); then
    echo "OK: ${out_first:-available}"
  else
    echo "FAIL"
  fi
}

# -----------------------------------------------------------
# Origem/versão (usado no status --detailed atual)
# -----------------------------------------------------------
tool_origin(){
  local name="$1"
  # tenta inferir a partir do brew info ou which
  local formula
  formula="$(yq -r --arg n "$name" '.tools[] | select(.name==$n) | .install.brew // empty' "$CFG_FILE")"
  if [[ -n "$formula" && "$formula" != "null" ]] && brew list "$formula" >/dev/null 2>&1; then
    local p; p="$(brew --prefix "$formula" 2>/dev/null || true)"
    [[ -n "$p" ]] && { echo "homebrew:$p/bin/$name"; return 0; }
  fi
  # fallback
  local w; w="$(command -v "$name" 2>/dev/null || true)"
  [[ -n "$w" ]] && { echo "system:$w"; return 0; }
  echo "-"
}

tool_version(){
  local name="$1"
  # heurística comum --version/-v/version
  for flag in "--version" "-v" "version"; do
    if out="$(bash -lc "$name $flag" 2>/dev/null | head -n1)"; then
      echo "$out"; return 0
    fi
  done
  echo "-"
}

# ==============================
# Blocos idempotentes no ~/.zshrc
# ==============================

# backup simples do ~/.zshrc se disponível helper; caso contrário, cria .bak único
__zshrc_backup_safe(){
  if declare -F zshrc_backup >/dev/null 2>&1; then
    zshrc_backup
  else
    [[ -f "$HOME/.zshrc" ]] && cp "$HOME/.zshrc" "$HOME/.zshrc.bak.$(date +%Y%m%d-%H%M%S)" 2>/dev/null || true
  fi
}

# Remove bloco entre marcadores exatos (linha inteira) preservando resto
# Uso: __zshrc_remove_block_by_markers "START_LINE" "END_LINE"
__zshrc_remove_block_by_markers(){
  local start="$1" end="$2"
  [[ -f "$HOME/.zshrc" ]] || return 0
  awk -v s="$start" -v e="$end" '
    BEGIN{skip=0}
    $0==s {skip=1; next}
    $0==e {skip=0; next}
    skip==0 {print}
  ' "$HOME/.zshrc" > "$HOME/.zshrc.__tmp" && mv "$HOME/.zshrc.__tmp" "$HOME/.zshrc"
}

# Remove todos os blocos de uma TOOL, independente do ID (útil no clean)
# Marcadores aceitos:
#   # >>> EASYENV:TOOL:ID >>>
#   # <<< EASYENV:TOOL:ID <<<
#   # >>> EASYENV:TOOL >>>
#   # <<< EASYENV:TOOL <<<
zshrc_remove_tool_blocks(){
  local tool="$1"
  [[ -z "$tool" ]] && return 0
  local TOOL_UP="$(echo "$tool" | tr '[:lower:]' '[:upper:]')"

  [[ -f "$HOME/.zshrc" ]] || return 0

  __zshrc_backup_safe

  # Remove quaisquer blocos com ou sem :ID para essa tool
  awk -v tu="$TOOL_UP" '
    BEGIN{skip=0}
    $0 ~ "^# >>> EASYENV:" tu "(:[^ ]+)?? >>>$" {skip=1; next}
    $0 ~ "^# <<< EASYENV:" tu "(:[^ ]+)?? <<<$" {skip=0; next}
    skip==0 {print}
  ' "$HOME/.zshrc" > "$HOME/.zshrc.__tmp" && mv "$HOME/.zshrc.__tmp" "$HOME/.zshrc"
}

# Injeta bloco idempotente.
# Parâmetros:
#   $1 = tool (ex.: "android", "nvm", "flutter")
#   $2 = conteúdo (pode ser multilinha)
#   $3 = id (opcional). Se omitido, é gerado um hash curto do conteúdo (estável para aquele conteúdo)
#
# Marcadores gerados:
#   # >>> EASYENV:TOOL:ID >>>
#   (conteúdo)
#   # <<< EASYENV:TOOL:ID <<<
#
# Comportamento:
#   - Se um bloco com MESMO TOOL e MESMO ID já existir, ele é substituído.
#   - Se não passar ID, usamos hash do conteúdo. Assim, se o conteúdo mudar, o ID muda.
#     Nesses casos, removemos qualquer bloco antigo daquela TOOL (sem ID) e injetamos o novo.
inject_zshrc_block(){
  local tool="$1" content="$2" id="${3:-}"
  [[ -z "$tool" || -z "$content" ]] && { err "inject_zshrc_block: params inválidos"; return 1; }

  local TOOL_UP
  TOOL_UP="$(echo "$tool" | tr '[:lower:]' '[:upper:]')"

  # Gera ID padrão a partir do conteúdo, se não vier fornecido
  if [[ -z "$id" ]]; then
    if command -v shasum >/dev/null 2>&1; then
      id="$(printf '%s' "$content" | shasum -a 1 | awk '{print substr($1,1,10)}')"
    else
      id="auto"
    fi
  fi

  local START="# >>> EASYENV:${TOOL_UP}:${id} >>>"
  local END="# <<< EASYENV:${TOOL_UP}:${id} <<<"

  __zshrc_backup_safe

  # 1) remove um bloco com o MESMO marcador (TOOL:ID), se já existir
  if [[ -f "$HOME/.zshrc" ]] && grep -qF "$START" "$HOME/.zshrc" 2>/dev/null; then
    __zshrc_remove_block_by_markers "$START" "$END"
  else
    # 2) Se não há ID explícito anterior, apaga versões antigas sem ID da mesma TOOL
    #    (para evitar acumular blocos legacy do mesmo componente)
    zshrc_remove_tool_blocks "$tool"
  fi

  # 3) anexa o bloco no final do arquivo
  {
    printf "\n%s\n" "$START"
    printf "%s\n" "$content"
    printf "%s\n" "$END"
  } >> "$HOME/.zshrc"

  ok "Bloco '$tool' injetado (id=$id)."
}

# Remove bloco específico por TOOL e ID (não apaga outros IDs da mesma ferramenta)
# Uso: zshrc_remove_block "android" "<id>"
zshrc_remove_block(){
  local tool="$1" id="$2"
  [[ -z "$tool" || -z "$id" ]] && { err "Uso: zshrc_remove_block <tool> <id>"; return 1; }
  local TOOL_UP="$(echo "$tool" | tr '[:lower:]' '[:upper:]')"
  local START="# >>> EASYENV:${TOOL_UP}:${id} >>>"
  local END="# <<< EASYENV:${TOOL_UP}:${id} <<<"
  [[ -f "$HOME/.zshrc" ]] || return 0
  __zshrc_backup_safe
  __zshrc_remove_block_by_markers "$START" "$END"
  ok "Bloco '$tool' (id=$id) removido."
}

# -----------------------------
# Helpers de leitura do catálogo
# -----------------------------
_tool_field(){
  local tool="$1" jq="$2"
  yq -r ".tools[] | select(.name==\"$tool\") | $jq // empty" "$CFG_FILE"
}

# -----------------------------
# uninstall_tool <tool>
# Remove a ferramenta conforme tools.yml:
#  - manager: brew | cask | npm_global (suportados)
#  - formula/cask/npm_global: identificadores específicos
#  - post_uninstall: comandos a rodar após desinstalar
#  - zshrc_blocks: (apenas para remover quaisquer blocos associados)
# Retorna 0 se considerarmos removida/limpa com sucesso.
# -----------------------------
uninstall_tool(){
  local tool="$1"
  [[ -z "$tool" ]] && { err "Uso: uninstall_tool <tool>"; return 1; }
  [[ ! -f "$CFG_FILE" ]] && { err "Catálogo não encontrado em $CFG_FILE"; return 1; }

  # Campos do catálogo
  local manager formula cask npm_global post_uninstall
  manager="$(_tool_field "$tool" ".manager")"
  formula="$(_tool_field "$tool" ".formula")"
  cask="$(_tool_field "$tool" ".cask")"
  npm_global="$(_tool_field "$tool" ".npm_global")"
  post_uninstall="$(_tool_field "$tool" ".post_uninstall")"

  # Fallback: se não tiver manager, assume brew
  [[ -z "$manager" || "$manager" == "null" ]] && manager="brew"

  case "$manager" in
    brew)
      # Se catálogo tem formula/cask use-os; senão, tente pelo nome da ferramenta
      local target="${formula:-$tool}"
      # Primeiro tenta formula
      if brew list --formula | grep -qx "$target"; then
        info "Desinstalando (brew formula): $target"
        brew uninstall "$target" || true
      fi
      # Depois tenta cask específico (se definido)
      if [[ -n "$cask" && "$cask" != "null" ]] && brew list --cask | grep -qx "$cask"; then
        info "Desinstalando (brew cask): $cask"
        brew uninstall --cask "$cask" || true
      fi
      # Fallback: caso não tenha formula definida mas exista cask com mesmo nome da tool
      if brew list --cask | grep -qx "$tool"; then
        info "Desinstalando (brew cask): $tool"
        brew uninstall --cask "$tool" || true
      fi
      ;;

    cask)
      local target="${cask:-$tool}"
      if brew list --cask | grep -qx "$target"; then
        info "Desinstalando (brew cask): $target"
        brew uninstall --cask "$target" || true
      else
        warn "Cask não encontrado: $target (pode já estar removido)."
      fi
      ;;

    npm_global)
      local pkg="${npm_global:-$tool}"
      if command -v npm >/dev/null 2>&1; then
        info "Desinstalando pacote global npm: $pkg"
        npm uninstall -g "$pkg" || true
        # Alguns pacotes criam links binários; npm remove, mas se sobrar algo em /opt/homebrew/bin, ignore.
      else
        warn "npm não encontrado — não foi possível remover global '$pkg'."
      fi
      ;;

    *)
      warn "Manager '$manager' não suportado em uninstall_tool para '$tool'. Tentando fallback Homebrew…"
      # Fallback genérico: tenta brew formula/cask com nomes comuns
      if brew list --formula | grep -qx "$tool"; then
        info "Desinstalando (brew formula): $tool"
        brew uninstall "$tool" || true
      fi
      if brew list --cask | grep -qx "$tool"; then
        info "Desinstalando (brew cask): $tool"
        brew uninstall --cask "$tool" || true
      fi
      ;;
  esac

  # Pós-uninstall do catálogo (opcional)
  if [[ -n "$post_uninstall" && "$post_uninstall" != "null" ]]; then
    info "Executando pós-uninstall para $tool…"
    bash -lc "$post_uninstall" || warn "Falha no pós-uninstall de $tool"
  fi

  # Remover blocos dessa ferramenta no ~/.zshrc (idempotente)
  zshrc_remove_tool_blocks "$tool" 2>/dev/null || true

  return 0
}