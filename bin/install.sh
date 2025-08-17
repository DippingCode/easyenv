#!/usr/bin/env bash
# EasyEnv - Installer (1-liner friendly)
# curl -fsSL https://raw.githubusercontent.com/DippingCode/easyenv/main/bin/install.sh | /bin/bash

set -euo pipefail

# --------- UI helpers ----------
hr() { printf '%*s\n' "${1:-37}" '' | tr ' ' '='; }
banner_install() {
  hr 37
  printf "          EasyEnv Installer\n"
  hr 37
  printf "\n"
}
banner_welcome() {
  printf "\n"
  printf "=====================================\n"
  printf "            Welcome to EasyEnv       \n"
  printf "=====================================\n"
  printf "\n"
}

# --------- Paths ----------
REPO_URL="${REPO_URL:-https://github.com/DippingCode/easyenv.git}"
TARGET_DIR="${EASYENV_HOME:-$HOME/easyenv}"
BIN_DIR="$HOME/.local/bin"
SHIM="$BIN_DIR/easyenv"

# --------- Idempotent append ----------
append_once() {
  # append_once <file> <marker_line> <block>
  local file="$1" marker="$2" block="$3"
  mkdir -p "$(dirname "$file")"
  touch "$file"
  if ! grep -qF "$marker" "$file"; then
    {
      printf "\n%s\n" "$marker"
      printf "%s\n" "$block"
    } >> "$file"
  fi
}

# --------- Begin ----------
banner_install
printf ">> Instalando easyenv em: %s\n" "$TARGET_DIR"

# Clone or update repo
if [[ -d "$TARGET_DIR/.git" ]]; then
  printf "-> Repositório já existe, atualizando (git pull)…\n"
  git -C "$TARGET_DIR" pull --ff-only --quiet
else
  printf "-> Clonando repositório…\n"
  git clone --quiet "$REPO_URL" "$TARGET_DIR"
fi

# Ensure runtime dirs
mkdir -p "$BIN_DIR"
mkdir -p "$TARGET_DIR/src" "$TARGET_DIR/var/logs" "$TARGET_DIR/var/backups" "$TARGET_DIR/var/snapshot"

# Make every *.sh under src executable
if command -v find >/dev/null 2>&1; then
  find "$TARGET_DIR/src" -type f -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true
fi

# Create shim (~/.local/bin/easyenv)
cat > "$SHIM" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
exec "$HOME/easyenv/src/main.sh" "$@"
SH
chmod +x "$SHIM"
printf "✅ Shim criado: %s\n" "$SHIM"

# Ensure ~/.zprofile adds ~/.local/bin to PATH (idempotente)
ZP="$HOME/.zprofile"
ZP_MARK="# >>> easyenv:PATH >>>"
ZP_BLOCK='case ":$PATH:" in
  *":"$HOME"/.local/bin:"*) ;;
  *) export PATH="$HOME/.local/bin:$PATH" ;;
esac'
append_once "$ZP" "$ZP_MARK" "$ZP_BLOCK"
printf "✅ PATH atualizado em ~/.zprofile (adicione ~/.local/bin).\n"

# Final message + auto help using absolute shim
banner_welcome
printf "✅ Instalação concluída!\n"
printf "Abrindo ajuda automática do EasyEnv…\n\n"

# Executa help sem depender do PATH atual
# Captura eventuais erros mas não quebra a instalação
if ! "$SHIM" help 2>/dev/null; then
  printf "\n⚠️  Não foi possível executar o help automaticamente.\n"
  printf "   Abra um novo terminal ou rode:\n"
  printf "       source \"%s\"\n" "$ZP"
  printf "   e então:  easyenv --help\n"
fi

printf "\nDica: para atualizar o PATH nesta sessão, rode:\n"
printf "    source \"%s\"\n\n" "$ZP"