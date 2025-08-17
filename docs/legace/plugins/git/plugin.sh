# git — plugin easyenv
tool_name(){ echo "git"; }
tool_provides(){ echo "versions install uninstall check"; }

# Instalação/remoção
tool_install(){
  if ! brew list --formula | grep -qx git; then
    brew install git
  else
    echo "git já instalado (brew)."
  fi
}
tool_uninstall(){
  if brew list --formula | grep -qx git; then
    brew uninstall --ignore-dependencies git
  else
    echo "git não está instalado (brew)."
  fi
}

# Atualização
tool_update(){
  brew upgrade git || true
}

# Versões
tool_versions(){
  echo "Git instalado:"
  local current
  if command -v git >/dev/null 2>&1; then
    current="$(git --version 2>/dev/null)"
    echo "  ✅ ${current} (em uso: $(command -v git))"
  else
    echo "  ❌ git não encontrado"
  fi

  if command -v brew >/dev/null 2>&1; then
    local brewv
    brewv="$(brew list --versions git 2>/dev/null || true)"
    [[ -n "$brewv" ]] && echo "  Brew: $brewv"
  fi

  echo "  Caminhos:"
  which -a git 2>/dev/null | sed 's/^/    - /'
}

# Troca de versão (não suportado nativamente)
tool_switch(){
  echo "Troca de versão para 'git' não suportada via plugin."
  echo "Sugestão: manter apenas um git no PATH (Homebrew vs /usr/bin) ou usar brew pin."
  return 1
}

# Doctor
doctor_tool(){
  if ! command -v git >/dev/null 2>&1; then
    err "git não encontrado. Dica: brew install git"
    return 1
  fi
  ok "git: $(git --version 2>/dev/null)"

  # Config mínima
  git config --global user.name  >/dev/null 2>&1 || warn "git user.name não configurado (global)."
  git config --global user.email >/dev/null 2>&1 || warn "git user.email não configurado (global)."

  # Xcode CLT (útil em macOS)
  if command -v xcode-select >/dev/null 2>&1; then
    xcode-select -p >/dev/null 2>&1 && ok "Xcode Command Line Tools detectado." || warn "Xcode CLT não configurado."
  fi
}