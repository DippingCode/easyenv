#!/usr/bin/env bash
# EasyEnv - instalador 1-liner (macOS/Linux)
# Uso:
# /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/DippingCode/easyenv/main/bin/install.sh)"
set -euo pipefail

# ---------------- UX helpers ----------------
_bold(){ printf "\033[1m%s\033[0m\n" "$*"; }
_green(){ printf "\033[32m%s\033[0m\n" "$*"; }
_yel(){ printf "\033[33m%s\033[0m\n" "$*"; }
_red(){ printf "\033[31m%s\033[0m\n" "$*"; }
ok(){ _green "✅ $*"; }
warn(){ _yel "⚠️  $*"; }
err(){ _red "❌ $*"; }
info(){ printf "-> %s\n" "$*"; }
step(){ printf "\n>> %s\n" "$*"; }

append_once_line(){ local f="$1" l="$2"; touch "$f"; grep -Fqx "$l" "$f" || echo "$l" >> "$f"; }

# ---------------- Paths/Repo ----------------
INSTALL_DIR="${EASYENV_HOME:-$HOME/easyenv}"
REPO_URL="https://github.com/DippingCode/easyenv.git"
ZPROFILE="$HOME/.zprofile"
WRAP_DIR="$HOME/.local/bin"
WRAP_BIN="$WRAP_DIR/easyenv"

step "Instalando easyenv em: $INSTALL_DIR"

# ---------------- Clone/Update --------------
if [[ -d "$INSTALL_DIR/.git" ]]; then
  info "Atualizando repositório…"
  git -C "$INSTALL_DIR" pull --ff-only || warn "git pull falhou; seguindo com versão local."
else
  info "Clonando repositório…"
  git clone --depth=1 "$REPO_URL" "$INSTALL_DIR"
fi

# ---------------- Wrapper no PATH -----------
mkdir -p "$WRAP_DIR"
cat > "$WRAP_BIN" <<'WRP'
#!/usr/bin/env bash
set -euo pipefail
EASYENV_HOME="${EASYENV_HOME:-$HOME/easyenv}"
# Chama via bash para evitar 'Permission denied' caso main.sh não tenha +x
exec /usr/bin/env bash "$EASYENV_HOME/src/main.sh" "$@"
WRP
chmod +x "$WRAP_BIN"
ok "Shim criado: $WRAP_BIN"

# ---------------- PATH (~/.zprofile) --------
mkdir -p "$(dirname "$ZPROFILE")"
touch "$ZPROFILE"
append_once_line "$ZPROFILE" 'export PATH="$HOME/.local/bin:$PATH"'
ok "PATH atualizado em ~/.zprofile (adicione ~/.local/bin)."

# ---------------- main.sh (perm) ------------
if [[ -f "$INSTALL_DIR/src/main.sh" ]]; then
  chmod +x "$INSTALL_DIR/src/main.sh" || true
fi

# ---------------- Banner EasyEnv ------------
cat <<'BANNER'

 ______                 ______                                               
|  ____|               |  ____|        _     _                                    
| |__   __ _ ___ _   _ | |__    ____  | |  / /                   
|  __| / _` / __| | | ||  __|  |` _ \ | | / /                 
| |___| (_| \__ \ |_| || |____ | | | || |/ /                  
|______\__,_|___/\__, ||______||_| |_||___/                
                   __/ |                                         
                  |___/ EasyEnv — setup & toolbox CLI 

BANNER

ok "Instalação concluída! Abra um novo terminal ou rode:"
echo '    source "$HOME/.zprofile"'
echo "e então:  easyenv --help"