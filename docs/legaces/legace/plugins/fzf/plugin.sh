# fzf — plugin easyenv
tool_name(){ echo "FZF"; }
tool_provides(){ echo "versions install uninstall check"; }

tool_install(){
  if ! brew list --formula | grep -qx fzf; then
    brew install fzf
    # key-bindings/completion (não editará zshrc automaticamente)
    "$(brew --prefix)/opt/fzf/install" --key-bindings --completion --no-update-rc <<<"y" >/dev/null 2>&1 || true
  else
    echo "fzf já instalado (brew)."
  fi
}
tool_uninstall(){
  if brew list --formula | grep -qx fzf; then
    brew uninstall fzf
  else
    echo "fzf não está instalado (brew)."
  fi
}

tool_update(){
  brew upgrade fzf || true
}

tool_versions(){
  echo "FZF instalado:"
  if command -v fzf >/dev/null 2>&1; then
    echo "  ✅ $(fzf --version 2>/dev/null | head -n1) (em uso)"
  else
    echo "  ❌ fzf não encontrado"
  fi

  # Arquivos de suporte
  local bp="$(brew --prefix 2>/dev/null || true)"
  [[ -n "$bp" && -d "$bp/opt/fzf/shell" ]] && echo "  Suporte shell: $bp/opt/fzf/shell"
  [[ -f "$HOME/.fzf.zsh" ]] && echo "  ~/.fzf.zsh presente"
}

tool_switch(){
  echo "fzf não suporta múltiplas versões por plugin."
  return 1
}

doctor_tool(){
  if command -v fzf >/dev/null 2>&1; then
    ok "fzf: $(fzf --version 2>/dev/null | head -n1)"
  else
    err "fzf não encontrado. Dica: brew install fzf"
    return 1
  fi

  local bp="$(brew --prefix 2>/dev/null || true)"
  if [[ -n "$bp" && -d "$bp/opt/fzf/shell" ]]; then
    ok "Arquivos de shell do fzf disponíveis."
  else
    warn "Arquivos de shell do fzf não encontrados em $(brew --prefix)/opt/fzf/shell"
  fi
}