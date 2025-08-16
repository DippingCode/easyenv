#!/usr/bin/env bash
set -euo pipefail

REPO_USER="dippingcode"
REPO_NAME="easyenv"
REPO_URL="https://github.com/${REPO_USER}/${REPO_NAME}.git"

EASYENV_HOME="$HOME/easyenv"
BIN_SRC="$EASYENV_HOME/src/bin/easyenv.sh"

BIN_DST_APPLE="/opt/homebrew/bin/easyenv"   # Apple Silicon padrão
BIN_DST_INTEL="/usr/local/bin/easyenv"      # Intel / instalações antigas
BIN_DST_USER="$HOME/.local/bin/easyenv"     # fallback sem sudo

bold(){ printf "\033[1m%s\033[0m\n" "$*"; }
info(){ printf "➜ %s\n" "$*"; }
ok(){ printf "✅ %s\n" "$*"; }
warn(){ printf "⚠️  %s\n" "$*"; }
err(){ printf "❌ %s\n" "$*" >&2; }

on_error(){
  err "Instalação falhou (linha ${BASH_LINENO[0]})."
  err "Verifique sua conexão, permissões (sudo) e tente novamente."
}
trap on_error ERR

# Ativa brew no PATH se já instalado (antes de qualquer uso)
prime_brew_shellenv(){
  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
}

need_brew(){
  if ! command -v brew >/dev/null 2>&1; then
    info "Homebrew não encontrado. Instalando..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
  prime_brew_shellenv
}

ensure_git(){
  if ! command -v git >/dev/null 2>&1; then
    info "git não encontrado. Instalando via Homebrew..."
    need_brew
    brew install git
  fi
}

install_yq(){
  need_brew
  brew update >/dev/null || true
  if ! command -v yq >/dev/null 2>&1; then
    info "Instalando yq..."
    brew install yq
  fi
}

fetch_repo(){
  ensure_git
  if [[ -d "$EASYENV_HOME/.git" ]]; then
    info "Atualizando $EASYENV_HOME..."
    git -C "$EASYENV_HOME" pull --ff-only
  else
    info "Clonando em $EASYENV_HOME..."
    git clone "$REPO_URL" "$EASYENV_HOME"
  fi
}

link_bin_global(){
  chmod +x "$BIN_SRC"

  # Tenta Apple Silicon
  if [[ -d "/opt/homebrew/bin" ]]; then
    if sudo ln -sf "$BIN_SRC" "$BIN_DST_APPLE"; then
      ok "easyenv instalado em $BIN_DST_APPLE"
      return 0
    else
      warn "Sem permissão para linkar em /opt/homebrew/bin (tentando outras opções)."
    fi
  fi

  # Tenta Intel
  if [[ -d "/usr/local/bin" ]]; then
    if sudo ln -sf "$BIN_SRC" "$BIN_DST_INTEL"; then
      ok "easyenv instalado em $BIN_DST_INTEL"
      return 0
    else
      warn "Sem permissão para linkar em /usr/local/bin (usando fallback no HOME)."
    fi
  fi

  # Fallback no usuário
  mkdir -p "$HOME/.local/bin"
  ln -sf "$BIN_SRC" "$BIN_DST_USER"
  ok "easyenv instalado em $BIN_DST_USER"

  # Garante PATH para o fallback
  if ! grep -q 'export PATH="$HOME/.local/bin:$PATH"' "$HOME/.zshrc" 2>/dev/null; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.zshrc"
    info 'Adicionado ~/.local/bin ao PATH no ~/.zshrc.'
  fi
}

post_install(){
  echo
  # Verifica se o comando já está resolvido no PATH atual
  if command -v easyenv >/dev/null 2>&1; then
    ok "Instalação concluída! Comando 'easyenv' disponível."
  else
    warn "O PATH do shell atual ainda não contém o binário 'easyenv'."
    warn "Abra um novo terminal ou rode:  source ~/.zshrc"
  fi
  echo
  bold "Próximos passos:"
  echo "  - easyenv help"
  echo "  - easyenv status"
  echo "  - easyenv init -steps"
  echo
}

main(){
  bold "EasyEnv - Installer"
  prime_brew_shellenv
  fetch_repo
  install_yq
  link_bin_global
  post_install
}

main "$@"