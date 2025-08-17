#!/usr/bin/env bash
# EasyEnv - Installer (1-liner friendly)
# Usage:
#   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/DippingCode/easyenv/main/bin/install.sh)"

set -euo pipefail

REPO_URL="${EASYENV_REPO_URL:-https://github.com/DippingCode/easyenv.git}"
INSTALL_DIR="${EASYENV_HOME:-$HOME/easyenv}"
LOCAL_BIN="$HOME/.local/bin"
SHIM="$LOCAL_BIN/easyenv"

banner() {
  printf -- "\n"
  printf -- "=====================================\n"
  printf -- "          EasyEnv Installer          \n"
  printf -- "=====================================\n\n"
}

step() { printf -- ">> %s\n" "$*"; }
sub()  { printf -- "-> %s\n" "$*"; }
ok()   { printf -- "✅ %s\n" "$*"; }
warn() { printf -- "⚠️  %s\n" "$*"; }
err()  { printf -- "❌ %s\n" "$*"; }

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    err "Dependência ausente: $1"
    if [[ "$1" == "git" ]]; then
      warn "Instale o Xcode Command Line Tools (macOS): xcode-select --install"
    fi
    exit 1
  }
}

ensure_local_bin_on_path() {
  # adiciona ~/.local/bin ao PATH via ~/.zprofile (idempotente)
  mkdir -p "$LOCAL_BIN"
  local ZP="$HOME/.zprofile"
  touch "$ZP"

  if ! grep -q "EASYENV:LOCALBIN" "$ZP"; then
    cat >> "$ZP" <<'ZP_EOF'

# >>> EASYENV:LOCALBIN >>>
# Garante que ~/.local/bin esteja no PATH
if [ -d "$HOME/.local/bin" ]; then
  case ":$PATH:" in
    *":$HOME/.local/bin:"*) ;;
    *) export PATH="$HOME/.local/bin:$PATH" ;;
  esac
fi
# <<< EASYENV:LOCALBIN <<<
ZP_EOF
    ok "PATH atualizado em ~/.zprofile (adicione ~/.local/bin)."
  fi
}

make_shim() {
  mkdir -p "$LOCAL_BIN"
  cat > "$SHIM" <<'EOF'
#!/usr/bin/env bash
# EasyEnv shim
exec "$HOME/easyenv/src/main.sh" "$@"
EOF
  chmod +x "$SHIM"
  ok "Shim criado: $SHIM"
}

clone_or_update_repo() {
  if [[ -d "$INSTALL_DIR/.git" ]]; then
    step "Atualizando repositório em: $INSTALL_DIR"
    git -C "$INSTALL_DIR" fetch --depth=1 origin main
    git -C "$INSTALL_DIR" reset --hard origin/main
  else
    step "Instalando easyenv em: $INSTALL_DIR"
    sub "Clonando repositório…"
    git clone --depth=1 "$REPO_URL" "$INSTALL_DIR"
  fi
}

ensure_exec_bits() {
  # deixa todos os .sh executáveis (seguro mesmo se alguns não existirem ainda)
  if command -v find >/dev/null 2>&1; then
    find "$INSTALL_DIR/src" -type f -name "*.sh" -print0 2>/dev/null | xargs -0 chmod +x 2>/dev/null || true
  fi
  # garante principais
  chmod +x "$INSTALL_DIR/src/main.sh" 2>/dev/null || true
  chmod +x "$INSTALL_DIR/src/core/router.sh" 2>/dev/null || true
  chmod +x "$INSTALL_DIR/src/presenter/cli/help.sh" 2>/dev/null || true
}

post_message() {
  printf -- "\n"
  ok "Instalação concluída!"
  printf -- "Abra um novo terminal ou rode:\n"
  printf -- "    source \"%s/.zprofile\"\n" "$HOME"
  printf -- "e então:  easyenv --help\n"
}

main() {
  banner
  need_cmd git
  clone_or_update_repo
  ensure_exec_bits
  make_shim
  ensure_local_bin_on_path
  post_message
}

main "$@"