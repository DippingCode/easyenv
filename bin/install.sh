#!/usr/bin/env bash
# bin/install.sh — instalador local (sem sudo)
# Uso rápido:
#   curl -fsSL https://raw.githubusercontent.com/DippingCode/easyenv/main/bin/install.sh | bash
#
# - Clona/atualiza o repo em ~/easyenv (ou EASYENV_HOME)
# - Cria shim ~/.local/bin/easyenv que chama src/main.sh
# - Garante ~/.zprofile com ~/.local/bin no PATH

set -euo pipefail

REPO_URL="${REPO_URL:-https://github.com/DippingCode/easyenv.git}"
EASYENV_HOME="${EASYENV_HOME:-$HOME/easyenv}"
LOCAL_BIN="${LOCAL_BIN:-$HOME/.local/bin}"
SHIM="$LOCAL_BIN/easyenv"

log() { printf "\033[1m%s\033[0m\n" "$*"; }
ok()  { printf "\033[32m%s\033[0m\n" "✅ $*"; }
warn(){ printf "\033[33m%s\033[0m\n" "⚠️  $*"; }
err() { printf "\033[31m%s\033[0m\n" "❌ $*" >&2; }

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || { err "Dependência ausente: $1"; exit 1; }
}

require_cmd git

log ">> Instalando easyenv em: $EASYENV_HOME"

if [[ -d "$EASYENV_HOME/.git" ]]; then
  log "-> Atualizando repositório existente…"
  git -C "$EASYENV_HOME" pull --rebase --autostash
else
  log "-> Clonando repositório…"
  git clone --depth=1 "$REPO_URL" "$EASYENV_HOME"
fi

# Cria shim local
mkdir -p "$LOCAL_BIN"
cat > "$SHIM" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
EASYENV_HOME="${EASYENV_HOME:-$HOME/easyenv}"
exec "$EASYENV_HOME/src/main.sh" "$@"
SH
chmod +x "$SHIM"
ok "Shim criado: $SHIM"

# Garante ~/.local/bin no PATH via ~/.zprofile
ZPROFILE="$HOME/.zprofile"
if ! grep -qF 'export PATH="$HOME/.local/bin:$PATH"' "$ZPROFILE" 2>/dev/null; then
  {
    echo ''
    echo '# >>> easyenv installer >>>'
    echo 'export PATH="$HOME/.local/bin:$PATH"'
    echo '# <<< easyenv installer <<<'
  } >> "$ZPROFILE"
  ok "PATH atualizado em ~/.zprofile (adicione ~/.local/bin)."
else
  warn "~/.local/bin já no PATH."
fi

ok "Instalação concluída! Abra um novo terminal ou rode:"
echo "    source \"$ZPROFILE\""
echo "e então:  easyenv --help"