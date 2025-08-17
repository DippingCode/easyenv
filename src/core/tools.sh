#!/usr/bin/env bash
# core/tools.sh — operações sobre ferramentas (install / uninstall / update) dirigidas por YAML e plugins

set -euo pipefail

# Espera que utils.sh e workspace.sh já tenham sido "sourceados":
# - ok, info, warn, err, _bld, confirm
# - zshrc_backup, inject_zshrc_block, zshrc_remove_tool_blocks
# - ensure_workspace_dirs, ensure_zprofile_prelude, ensure_zshrc_prelude

# Arquivos padrão
CFG_FILE="${CFG_FILE:-$EASYENV_HOME/src/config/tools.yml}"
SNAP_FILE="${SNAP_FILE:-$EASYENV_HOME/src/config/.zshrc-tools.yml}"

# ==============================
# Leitura do catálogo (yq)
# ==============================
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

yaml_has_tool(){
  local name="$1"
  [[ -f "$CFG_FILE" ]] || return 1
  yq -e ".tools[] | select(.name == \"$name\")" "$CFG_FILE" >/dev/null 2>&1
}

yaml_add_tool(){
  local name="$1" section="$2"
  [[ -f "$CFG_FILE" ]] || { err "Catálogo não encontrado: $CFG_FILE"; return 1; }
  info "Registrando '$name' em '$section' no catálogo."
  local tmp; tmp="$(mktemp)"
  yq ".tools += [{\"name\":\"$name\",\"section\":\"$section\"}]" "$CFG_FILE" > "$tmp"
  mv "$tmp" "$CFG_FILE"
}

_tool_field(){
  local tool="$1" jq="$2"
  yq -r ".tools[] | select(.name==\"$tool\") | $jq // empty" "$CFG_FILE" 2>/dev/null
}

# ==============================
# Plugins (prioridade)
# ==============================
_plugin_path_for(){
  local tool="$1"
  local p="$EASYENV_HOME/src/plugins/$tool/plugin.sh"
  [[ -f "$p" ]] && echo "$p" || echo ""
}

call_plugin_func_if_exists(){
  local tool="$1" fn="$2"
  local p; p="$(_plugin_path_for "$tool")"
  [[ -z "$p" ]] && return 1
  # shellcheck disable=SC1090
  source "$p"
  if declare -F "$fn" >/dev/null 2>&1; then
    "$fn" "${@:3}"
    return 0
  fi
  return 1
}

# ==============================
# Brew / NPM helpers
# ==============================
brew_update_quick(){
  command -v brew >/dev/null 2>&1 || return 0
  brew update >/dev/null 2>&1 || true
}

brew_cleanup_safe(){
  command -v brew >/dev/null 2>&1 || return 0
  info "Executando brew cleanup -s (safe)…"
  brew cleanup -s || true
}

brew_list_outdated(){
  command -v brew >/dev/null 2>&1 || { echo "Homebrew não instalado."; return 0; }
  echo "Fórmulas desatualizadas:"
  brew outdated || true
  echo
  echo "Casks desatualizados:"
  brew outdated --cask || true
}

install_by_brew(){
  local formula="$1" ver="${2:-}"
  if [[ -n "$ver" ]]; then
    brew install "${formula}@${ver}" || brew install "$formula"
  else
    brew install "$formula"
  fi
}

install_by_brew_cask(){
  local cask="$1"
  brew install --cask "$cask"
}

install_by_npm_global(){
  local pkg="$1" ver="${2:-}"
  require_cmd "npm" "Instale Node/npm antes."
  if [[ -n "$ver" ]]; then
    npm install -g "${pkg}@${ver}"
  else
    npm install -g "$pkg"
  fi
}

# ==============================
# ZSHRC blocks (EASYENV markers)
# ==============================
inject_tool_zshrc_blocks(){
  local tool="$1"
  # Espera estrutura: zshrc_blocks: [ {id: "...", content: "..."}, ... ]
  local count; count="$(yq -r ".tools[] | select(.name==\"$tool\") | (.zshrc_blocks // []) | length" "$CFG_FILE" 2>/dev/null || echo 0)"
  (( count == 0 )) && return 0

  local i
  for ((i=0; i<count; i++)); do
    local id content
    id="$(yq -r ".tools[] | select(.name==\"$tool\") | .zshrc_blocks[$i].id // \"\"" "$CFG_FILE")"
    content="$(yq -r ".tools[] | select(.name==\"$tool\") | .zshrc_blocks[$i].content // \"\"" "$CFG_FILE")"
    [[ "$content" == "null" || -z "$content" ]] && continue
    inject_zshrc_block "$tool" "$content" "$id"
  done
}

remove_tool_zshrc_blocks(){
  local tool="$1"
  zshrc_remove_tool_blocks "$tool" 2>/dev/null || true
}

# ==============================
# install_tool / uninstall_tool / upgrade_tool
# ==============================
install_tool(){
  local name="$1"; local version="${2:-}"
  [[ -z "$name" ]] && { err "Uso: install_tool <tool> [version]"; return 1; }
  [[ -f "$CFG_FILE" ]] || { err "Catálogo não encontrado em $CFG_FILE"; return 1; }

  # 1) Plugin tem prioridade
  if call_plugin_func_if_exists "$name" tool_install "$version"; then
    inject_tool_zshrc_blocks "$name"
    ok "$name instalado (plugin)."
    return 0
  fi()

  # 2) Manager do YAML
  local manager formula cask npm_global tap
  manager="$(_tool_field "$name" ".manager")"
  formula="$(_tool_field "$name" ".formula")"
  cask="$(_tool_field "$name" ".cask")"
  npm_global="$(_tool_field "$name" ".npm_global")"
  tap="$(_tool_field "$name" ".tap")"

  [[ -z "$manager" || "$manager" == "null" ]] && manager="brew"

  case "$manager" in
    brew)
      [[ -n "$tap" && "$tap" != "null" ]] && brew tap "$tap" || true
      local target="${formula:-$name}"
      info "Instalando (brew): $target ${version:+(@$version)}"
      install_by_brew "$target" "$version"
      ;;
    brew-cask|cask)
      local target="${cask:-$name}"
      info "Instalando (brew cask): $target"
      install_by_brew_cask "$target"
      ;;
    npm|npm_global)
      local pkg="${npm_global:-$formula}"
      [[ -z "$pkg" || "$pkg" == "null" ]] && pkg="$name"
      info "Instalando (npm -g): $pkg ${version:+@$version}"
      install_by_npm_global "$pkg" "$version"
      ;;
    sdkmanager)
      # Deve existir plugin android com tool_install
      if ! call_plugin_func_if_exists "$name" tool_install "$version"; then
        err "Manager 'sdkmanager' requer plugin (src/plugins/android/plugin.sh)."
        return 1
      fi
      ;;
    *)
      warn "Manager desconhecido '$manager' para '$name' — tentando plugin como fallback."
      if ! call_plugin_func_if_exists "$name" tool_install "$version"; then
        err "Sem rota de instalação para '$name'."
        return 1
      fi
      ;;
  esac

  inject_tool_zshrc_blocks "$name"
  ok "$name instalado."
}

uninstall_tool(){
  local name="$1"
  [[ -z "$name" ]] && { err "Uso: uninstall_tool <tool>"; return 1; }
  [[ -f "$CFG_FILE" ]] || { err "Catálogo não encontrado em $CFG_FILE"; return 1; }

  # 1) Plugin tem prioridade
  if call_plugin_func_if_exists "$name" tool_uninstall; then
    remove_tool_zshrc_blocks "$name"
    ok "$name removido (plugin)."
    return 0
  fi

  # 2) Manager do YAML
  local manager formula cask npm_global tap
  manager="$(_tool_field "$name" ".manager")"
  formula="$(_tool_field "$name" ".formula")"
  cask="$(_tool_field "$name" ".cask")"
  npm_global="$(_tool_field "$name" ".npm_global")"
  tap="$(_tool_field "$name" ".tap")"

  [[ -z "$manager" || "$manager" == "null" ]] && manager="brew"

  case "$manager" in
    brew)
      local target="${formula:-$name}"
      if brew list --formula | grep -qx "$target"; then
        info "Desinstalando (brew formula): $target"
        brew uninstall "$target" || true
      fi
      # se tiver cask também definido, tenta remover
      if [[ -n "$cask" && "$cask" != "null" ]] && brew list --cask | grep -qx "$cask"; then
        info "Desinstalando (brew cask): $cask"
        brew uninstall --cask "$cask" || true
      fi
      ;;
    brew-cask|cask)
      local target="${cask:-$name}"
      if brew list --cask | grep -qx "$target"; then
        info "Desinstalando (brew cask): $target"
        brew uninstall --cask "$target" || true
      else
        info "Cask não instalado: $target"
      fi
      ;;
    npm|npm_global)
      local pkg="${npm_global:-$formula}"
      [[ -z "$pkg" || "$pkg" == "null" ]] && pkg="$name"
      if command -v npm >/dev/null 2>&1; then
        info "Desinstalando (npm -g): $pkg"
        npm rm -g "$pkg" || true
      else
        warn "npm não encontrado — não foi possível remover '$pkg'."
      fi
      ;;
    sdkmanager)
      if ! call_plugin_func_if_exists "$name" tool_uninstall; then
        warn "Sem rotina de remoção para '$name' (sdkmanager)."
      fi
      ;;
    *)
      warn "Manager desconhecido para '$name' — tentando plugin como fallback."
      call_plugin_func_if_exists "$name" tool_uninstall || true
      ;;
  esac

  remove_tool_zshrc_blocks "$name"
  ok "$name removido."
}

upgrade_tool(){
  local name="$1"
  [[ -z "$name" ]] && { err "Uso: upgrade_tool <tool>"; return 1; }
  [[ -f "$CFG_FILE" ]] || { err "Catálogo não encontrado em $CFG_FILE"; return 1; }

  # 1) Plugin?
  if call_plugin_func_if_exists "$name" tool_update; then
    ok "$name atualizado (plugin)."
    return 0
  fi

  # 2) Manager
  local manager formula cask npm_global tap
  manager="$(_tool_field "$name" ".manager")"
  formula="$(_tool_field "$name" ".formula")"
  cask="$(_tool_field "$name" ".cask")"
  npm_global="$(_tool_field "$name" ".npm_global")"
  tap="$(_tool_field "$name" ".tap")"

  [[ -z "$manager" || "$manager" == "null" ]] && manager="brew"

  case "$manager" in
    brew)
      [[ -n "$tap" && "$tap" != "null" ]] && brew tap "$tap" || true
      local target="${formula:-$name}"
      if brew list --formula | grep -qx "$target"; then
        info "Atualizando (brew): $target"
        brew upgrade "$target" || true
      else
        info "Não instalado via brew. Instalando $target…"
        brew install "$target"
      fi
      ;;
    brew-cask|cask)
      local target="${cask:-$name}"
      if brew list --cask | grep -qx "$target"; then
        info "Atualizando (brew cask): $target"
        brew upgrade --cask "$target" || true
      else
        info "Cask não instalado. Instalando $target…"
        brew install --cask "$target"
      fi
      ;;
    npm|npm_global)
      local pkg="${npm_global:-$formula}"
      [[ -z "$pkg" || "$pkg" == "null" ]] && pkg="$name"
      if command -v npm >/dev/null 2>&1; then
        info "Atualizando (npm -g): $pkg"
        npm install -g "$pkg" || true
      else
        warn "npm não encontrado — não foi possível atualizar '$pkg'."
      fi
      ;;
    sdkmanager)
      if ! call_plugin_func_if_exists "$name" tool_update; then
        warn "Sem rotina de update para '$name' (sdkmanager)."
      fi
      ;;
    *)
      warn "Manager desconhecido para '$name' — tentando plugin como fallback."
      call_plugin_func_if_exists "$name" tool_update || true
      ;;
  esac

  # Reaplica blocos (idempotente)
  inject_tool_zshrc_blocks "$name"
  ok "$name atualizado."
}

# ==============================
# Checks / origem / versão
# ==============================
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

tool_origin(){
  local name="$1"
  local w; w="$(command -v "$name" 2>/dev/null || true)"
  [[ -n "$w" ]] && { echo "path:$w"; return 0; }

  local manager formula
  manager="$(_tool_field "$name" ".manager")"
  formula="$(_tool_field "$name" ".formula")"
  case "$manager" in
    brew|brew-cask|cask) echo "${manager}:${formula:-$name}";;
    npm|npm_global)      echo "npm:${formula:-$name}";;
    sdkmanager)          echo "android:sdkmanager";;
    *)                   echo "unknown";;
  esac
}

tool_version(){
  local name="$1"
  if command -v "$name" >/dev/null 2>&1; then
    for flag in "--version" "-v" "version"; do
      if out="$(bash -lc "$name $flag" 2>/dev/null | head -n1)"; then
        [[ -n "$out" ]] && { echo "$out"; return 0; }
      fi
    done
  fi
  echo ""
}