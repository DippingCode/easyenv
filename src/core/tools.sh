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
  local name="$1"
  local formula cask

  formula="$(tool_field "$name" '.brew.formula // ""')"
  cask="$(tool_field "$name" '.brew.cask // ""')"

  prime_brew_shellenv
  if ! command -v brew >/dev/null 2>&1; then
    err "Homebrew não encontrado; não é possível desinstalar '$name' automaticamente."
    return 1
  fi

  info "Desinstalando $name…"
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