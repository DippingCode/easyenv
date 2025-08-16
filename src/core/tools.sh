#!/usr/bin/env bash
# tools.sh - instalação por ferramenta/seção (usado por `init`)

set -euo pipefail

# Instala uma ferramenta com base no catálogo (tools.yml)
install_tool(){
  local name="$1"
  local formula cask install env aliases

  formula="$(tool_field "$name" '.brew.formula // ""')"
  cask="$(tool_field "$name" '.brew.cask // ""')"
  install="$(tool_field "$name" '.install // ""')"
  env="$(tool_field "$name" '.env[]?')"
  aliases="$(tool_field "$name" '.aliases[]?')"

  # respeita pins.enabled=false, se existir no snapshot
  if [[ -f "$SNAP_FILE" ]]; then
    local enabled
    enabled="$(yq -r ".pins.\"$name\".enabled // true" "$SNAP_FILE" || echo true)"
    if [[ "$enabled" != "true" ]]; then
      info "Snapshot: '$name' desabilitado. Pulando."
      return 0
    fi
  fi

  # brew
  prime_brew_shellenv
  if command -v brew >/dev/null 2>&1; then
    brew_install_if_needed "$formula"
    brew_cask_install_if_needed "$cask"
  else
    err "Homebrew não encontrado. Instale com: /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
    exit 1
  fi

  # bloco install (shell)
  if [[ -n "$install" && "$install" != "null" ]]; then
    info "Executando pós-instalação para $name..."
    bash -euo pipefail -c "$install"
  fi

  # env/aliases para .zshrc
  local env_block="" alias_block=""
  while IFS= read -r line; do [[ -z "${line:-}" || "$line" == "null" ]] && continue; env_block+="${line}"$'\n'; done < <(echo "$env")
  while IFS= read -r line; do [[ -z "${line:-}" || "$line" == "null" ]] && continue; alias_block+="${line}"$'\n'; done < <(echo "$aliases")

  if [[ -n "$env_block$alias_block" ]]; then
    append_once "$ZSHRC_FILE" "# ----- EASYENV (auto) -----" "# ----- EASYENV (auto) -----"
    [[ -n "$env_block" ]] && append_lines_once "$ZSHRC_FILE" "# EASYENV env"   "$env_block"
    [[ -n "$alias_block" ]] && append_lines_once "$ZSHRC_FILE" "# EASYENV alias" "$alias_block"
  fi

  ok "$name instalado"
}

# Executa instalação de uma seção inteira
do_section_install(){
  local sec="$1"
  info "Instalando seção: $sec"
  local tools; mapfile -t tools < <(list_tools_by_section "$sec")
  if (( ${#tools[@]} == 0 )); then
    warn "Seção '$sec' vazia."
    return 0
  fi
  for t in "${tools[@]}"; do
    install_tool "$t"
  done
}

# Desinstala uma ferramenta com base no catálogo
uninstall_tool(){
  local name="${1:-}"
  if [[ -z "$name" ]]; then
    err "uninstall_tool: nome da ferramenta vazio"
    return 1
  fi

  local formula cask
  formula="$(tool_field "$name" '.brew.formula // ""' | tr -d '\r')"
  cask="$(tool_field "$name" '.brew.cask // ""' | tr -d '\r')"

  prime_brew_shellenv
  if ! command -v brew >/dev/null 2>&1; then
    err "Homebrew não encontrado; não é possível desinstalar '$name' automaticamente."
    return 1
  fi

  info "Desinstalando $name"
  brew_uninstall_if_installed "$formula"
  brew_cask_uninstall_if_installed "$cask"

  # limpa blocos no zshrc relacionados a essa tool (best effort)
  zshrc_backup
  zshrc_remove_tool_entries "$name"
  ok "$name removido"
}

do_section_uninstall(){
  local sec="$1"
  info "Removendo seção: $sec"
  local tools; mapfile -t tools < <(list_tools_by_section "$sec")
  if (( ${#tools[@]} == 0 )); then
    warn "Seção '$sec' vazia."
    return 0
  fi
  for t in "${tools[@]}"; do
    uninstall_tool "$t"
  done
}

# Reinstala uma ferramenta (usado no restore)
reinstall_tool(){
  local name="$1"
  # mesmo fluxo de install_tool (respeita brew/cask/install/env/aliases)
  install_tool "$name"
}

restore_section(){
  local sec="$1"
  info "Restaurando seção: $sec"
  local tools; mapfile -t tools < <(list_tools_by_section "$sec")
  if (( ${#tools[@]} == 0 )); then
    warn "Seção '$sec' vazia."
    return 0
  fi
  for t in "${tools[@]}"; do
    reinstall_tool "$t"
  done
}

# --- Update helpers ---

# Atualiza uma ferramenta (formula/cask) se instalada via brew.
upgrade_tool(){
  local name="${1:-}"
  [[ -z "$name" ]] && { err "upgrade_tool: nome vazio"; return 1; }

  local formula cask
  formula="$(tool_field "$name" '.brew.formula // ""' | tr -d '\r')"
  cask="$(tool_field "$name" '.brew.cask // ""' | tr -d '\r')"

  prime_brew_shellenv
  if ! command -v brew >/dev/null 2>&1; then
    err "Homebrew não encontrado; não é possível atualizar '$name'."
    return 1
  fi

  local changed=0
  if [[ -n "$formula" && "$formula" != "null" ]]; then
    if brew list --formula | grep -qx "$formula"; then
      info "brew upgrade $formula"
      brew upgrade "$formula" || true
      changed=1
    else
      info "brew: formula $formula não instalada; pulando."
    fi
  fi

  if [[ -n "$cask" && "$cask" != "null" ]]; then
    if brew list --cask | grep -qx "$cask"; then
      info "brew upgrade --cask $cask"
      brew upgrade --cask "$cask" || true
      changed=1
    else
      info "brew: cask $cask não instalada; pulando."
    fi
  fi

  if (( changed==1 )); then
    ok "$name atualizado"
  else
    info "$name já estava atualizado (ou não instalado via brew)."
  fi
}

# Lista pacotes desatualizados no Homebrew (fórmulas e casks).
brew_list_outdated(){
  prime_brew_shellenv
  command -v brew >/dev/null 2>&1 || { echo ""; return 0; }

  echo "Formulas desatualizadas:"
  brew outdated || true
  echo
  echo "Casks desatualizados:"
  brew outdated --cask || true
}