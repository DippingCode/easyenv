#!/usr/bin/env bash
set -euo pipefail

REPO_URL="https://github.com/DippingCode/easyenv.git"
INSTALL_DIR="${EASYENV_HOME:-$HOME/easyenv}"
SHIM_DIR="$HOME/.local/bin"
SHIM_PATH="$SHIM_DIR/easyenv"

banner() {
  cat <<'B'
=====================================
          EasyEnv Installer
=====================================
B
}

main() {
  banner
  printf "\n>> Instalando easyenv em: %s\n" "$INSTALL_DIR"

  if [[ -d "$INSTALL_DIR/.git" ]]; then
    echo "-> Atualizando repositório…"
    git -C "$INSTALL_DIR" pull --ff-only
  else
    echo "-> Clonando repositório…"
    rm -rf "$INSTALL_DIR"
    git clone "$REPO_URL" "$INSTALL_DIR"
  fi

  mkdir -p "$SHIM_DIR"
  cat > "$SHIM_PATH" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
EASYENV_HOME="${EASYENV_HOME:-$HOME/easyenv}"
exec /usr/bin/env bash "$EASYENV_HOME/src/main.sh" "$@"
SH
  chmod +x "$SHIM_PATH"
  echo "✅ Shim criado: $SHIM_PATH"

  # Garante PATH para o shim
  if ! grep -q "$SHIM_DIR" "$HOME/.zprofile" 2>/dev/null; then
    {
      echo
      echo '# EasyEnv: add ~/.local/bin to PATH'
      echo 'export PATH="$HOME/.local/bin:$PATH"'
    } >> "$HOME/.zprofile"
    echo "✅ PATH atualizado em ~/.zprofile (adicione ~/.local/bin)."
  fi

  # Tenta carregar para a sessão atual
  if [[ ":$PATH:" != *":$SHIM_DIR:"* ]]; then
    export PATH="$SHIM_DIR:$PATH"
  fi

  # ==== Bootstrap de ferramentas via comando oficial ====
  # Usa o dispatcher (gera logs e mantém a organização)
  if command -v easyenv >/dev/null 2>&1; then
    easyenv tools install || true
  else
    # Fallback muito raro: se o shim não estiver no PATH, chama serviço direto
    /usr/bin/env bash "$INSTALL_DIR/src/data/services/tools.sh" bootstrap || true
  fi

  cat <<EOM

✅ Instalação concluída!
Abra um novo terminal ou rode:
    source "$HOME/.zprofile" && source "$HOME/.zshrc"

e então:  easyenv --help
EOM
}

main "$@"