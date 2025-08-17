#!/usr/bin/env bash
# data/services/tools.sh — instala/atualiza/desinstala ferramentas do catálogo (config/tools.yml)

set -euo pipefail

# --------- helpers locais (isolados do core) ----------
_color() { printf "%b%s%b" "\033[$1m" "$2" "\033[0m"; }
_ok()    { printf "✅ %s\n" "$*"; }
_info()  { printf "➜  %s\n" "$*"; }
_warn()  { _color "33" "⚠ "; printf "%s\n" "$*"; }
_err()   { _color "31" "✖ "; printf "%s\n" "$*" 1>&2; }

confirm() {
  local msg="${1:-Confirmar?}"; local ans=""
  read -r -p "$msg (yes/NO) " ans || true
  [[ "$ans" =~ ^(y|Y|yes|YES)$ ]]
}

# --------- paths ----------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EASYENV_HOME="${EASYENV_HOME:-$(cd "$SCRIPT_DIR/../../.." && pwd)}"
CFG="$EASYENV_HOME/config/tools.yml"

# --------- pre-reqs ----------
ensure_git()  { command -v git  >/dev/null 2>&1 || { _err "git é necessário."; exit 1; }; }
ensure_curl() { command -v curl >/dev/null 2>&1 || { _err "curl é necessário."; exit 1; }; }

ensure_brew() {
  if command -v brew >/dev/null 2>&1; then return 0; fi
  _info "Homebrew não encontrado. Instalando…"
  ensure_curl
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  _ok "Homebrew instalado."
}

brew_shellenv() {
  if ! command -v brew >/dev/null 2>&1; then return 0; fi
  # Aplica no ambiente deste processo
  eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null || /usr/local/bin/brew shellenv)"
  # Garante no zprofile (idempotente)
  local zpf="$HOME/.zprofile"
  grep -q 'brew shellenv' "$zpf" 2>/dev/null || {
    {
      echo ''
      echo '# Added by easyenv (brew shellenv)'
      echo 'eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null || /usr/local/bin/brew shellenv)"'
    } >> "$zpf"
    _ok "PATH do Homebrew adicionado ao ~/.zprofile"
  }
}

ensure_yq() {
  if command -v yq >/dev/null 2>&1; then return 0; fi
  _info "Instalando yq…"
  brew install yq
  _ok "yq instalado."
}

ensure_node_for_npm() {
  if command -v npm >/dev/null 2>&1; then return 0; fi
  _warn "npm não encontrado. Instalando Node (LTS) via Homebrew…"
  brew install node
  _ok "Node instalado (para npm global)."
}

# --------- runners ----------
_run_install_script() {
  local code="$1"
  [[ -z "${code:-}" || "$code" == "null" ]] && return 0
  bash -lc "$code"
}

_run_uninstall_script() {
  local code="$1"
  [[ -z "${code:-}" || "$code" == "null" ]] && return 0
  bash -lc "$code"
}

# --------- unitários ----------
_install_one() {
  local name="$1" formula="$2" cask="$3" install_code="$4" extra_git_repo="$5" extra_git_dest="$6" extra_npm="$7"

  # brew (formula/cask)
  if [[ -n "$formula" && "$formula" != "null" ]]; then
    if brew list "$formula" >/dev/null 2>&1; then
      _info "brew: $formula já instalado."
    else
      _info "brew install $formula"
      brew install "$formula"
    fi
  fi
  if [[ -n "$cask" && "$cask" != "null" ]]; then
    if brew list --cask "$cask" >/dev/null 2>&1; then
      _info "cask: $cask já instalado."
    else
      _info "brew install --cask $cask"
      brew install --cask "$cask"
    fi
  fi

  # extra: git clone
  if [[ -n "$extra_git_repo" && "$extra_git_repo" != "null" && -n "$extra_git_dest" && "$extra_git_dest" != "null" ]]; then
    if [[ -d "$extra_git_dest/.git" ]]; then
      _info "git: destino já existe ($extra_git_dest)."
    else
      _info "git clone $extra_git_repo → $extra_git_dest"
      git clone "$extra_git_repo" "$extra_git_dest"
    fi
  fi

  # extra: npm global
  if [[ -n "$extra_npm" && "$extra_npm" != "null" ]]; then
    ensure_node_for_npm
    _info "npm i -g $extra_npm"
    npm install -g "$extra_npm"
  fi

  # install script
  _run_install_script "$install_code"

  _ok "$name instalado."
}

_update_one() {
  local name="$1" formula="$2" cask="$3" update_cmd="$4" extra_git_dest="$5" extra_npm="$6"

  brew update || true

  if [[ -n "$update_cmd" && "$update_cmd" != "null" ]]; then
    _info "$name: executando update_cmd…"
    bash -lc "$update_cmd" || _warn "$name: update_cmd falhou (continuando)."
    _ok "$name atualizado (update_cmd)."
    return 0
  fi

  if [[ -n "$formula" && "$formula" != "null" ]] && brew list "$formula" >/dev/null 2>&1; then
    _info "brew upgrade $formula"
    brew upgrade "$formula" || _warn "$name: falha no brew upgrade (continuando)."
  fi
  if [[ -n "$cask" && "$cask" != "null" ]] && brew list --cask "$cask" >/dev/null 2>&1; then
    _info "brew upgrade --cask $cask"
    brew upgrade --cask "$cask" || _warn "$name: falha no brew upgrade --cask (continuando)."
  fi

  # git pull
  if [[ -n "$extra_git_dest" && "$extra_git_dest" != "null" && -d "$extra_git_dest/.git" ]]; then
    _info "git -C \"$extra_git_dest\" pull"
    git -C "$extra_git_dest" pull || _warn "$name: git pull falhou (continuando)."
  fi

  # npm update -g
  if [[ -n "$extra_npm" && "$extra_npm" != "null" ]]; then
    if command -v npm >/dev/null 2>&1; then
      _info "npm update -g $extra_npm"
      npm update -g "$extra_npm" || _warn "$name: npm update falhou (continuando)."
    fi
  fi

  _ok "$name atualizado."
}

_uninstall_one() {
  local name="$1" formula="$2" cask="$3" uninstall_code="$4" extra_git_dest="$5" extra_npm="$6"

  # desinstala via brew
  if [[ -n "$formula" && "$formula" != "null" ]] && brew list "$formula" >/dev/null 2>&1; then
    _info "brew uninstall $formula"
    brew uninstall "$formula" || true
  fi
  if [[ -n "$cask" && "$cask" != "null" ]] && brew list --cask "$cask" >/dev/null 2>&1; then
    _info "brew uninstall --cask $cask"
    brew uninstall --cask "$cask" || true
  fi

  # remove clone git, se existir (opcional)
  if [[ -n "$extra_git_dest" && "$extra_git_dest" != "null" && -d "$extra_git_dest/.git" ]]; then
    _info "removendo diretório git: $extra_git_dest"
    rm -rf "$extra_git_dest"
  fi

  # remove npm global (opcional)
  if [[ -n "$extra_npm" && "$extra_npm" != "null" ]] && command -v npm >/dev/null 2>&1; then
    _info "npm uninstall -g $extra_npm"
    npm uninstall -g "$extra_npm" || true
  fi

  # script custom
  _run_uninstall_script "$uninstall_code"

  _ok "$name desinstalado."
}

# --------- pipelines ----------
install_all() {
  ensure_git
  ensure_brew
  brew_shellenv
  ensure_yq

  if [[ ! -f "$CFG" ]]; then
    _err "Catálogo não encontrado: $CFG"
    exit 1
  fi

  while IFS=$'\t' read -r name formula cask install_code repo dest npm_pkg; do
    [[ -z "$name" || "$name" == "null" ]] && continue
    _info "Instalando: $name"
    _install_one "$name" "$formula" "$cask" "$install_code" "$repo" "$dest" "$npm_pkg"
  done < <(yq -r '.tools[] | [
      .name,
      (.brew.formula // ""),
      (.brew.cask // ""),
      (.install // ""),
      (.extra.install_git.repo // ""),
      (.extra.install_git.dest // ""),
      (.extra.install_npm // "")
    ] | @tsv' "$CFG")
}

update_all() {
  ensure_brew
  brew_shellenv
  ensure_yq

  if [[ ! -f "$CFG" ]]; then
    _err "Catálogo não encontrado: $CFG"
    exit 1
  fi

  while IFS=$'\t' read -r name formula cask update_cmd dest npm_pkg; do
    [[ -z "$name" || "$name" == "null" ]] && continue
    _info "Atualizando: $name"
    _update_one "$name" "$formula" "$cask" "$update_cmd" "$dest" "$npm_pkg"
  done < <(yq -r '.tools[] | [
      .name,
      (.brew.formula // ""),
      (.brew.cask // ""),
      (.update_cmd // ""),
      (.extra.install_git.dest // ""),
      (.extra.install_npm // "")
    ] | @tsv' "$CFG")
}

uninstall_all() {
  ensure_brew
  brew_shellenv
  ensure_yq

  if [[ ! -f "$CFG" ]]; then
    _err "Catálogo não encontrado: $CFG"
    exit 1
  fi

  while IFS=$'\t' read -r name formula cask uninstall_code dest npm_pkg; do
    [[ -z "$name" || "$name" == "null" ]] && continue
    _info "Desinstalando: $name"
    _uninstall_one "$name" "$formula" "$cask" "$uninstall_code" "$dest" "$npm_pkg"
  done < <(yq -r '.tools[] | [
      .name,
      (.brew.formula // ""),
      (.brew.cask // ""),
      (.uninstall // ""),
      (.extra.install_git.dest // ""),
      (.extra.install_npm // "")
    ] | @tsv' "$CFG")
}

# --------- CLI local ----------
usage() {
  cat <<'EOF'
Uso (serviço interno):
  tools.sh bootstrap      # instala todas as ferramentas do catálogo
  tools.sh update-all     # atualiza todas
  tools.sh uninstall-all  # desinstala todas (sem confirmação)

Observação: este arquivo é invocado por "easyenv tools <subcomando>".
EOF
}

cmd="${1:-}"
case "$cmd" in
  bootstrap)      install_all ;;
  update-all)     update_all ;;
  uninstall-all)  uninstall_all ;;
  ""|-h|--help)   usage; exit 0 ;;
  *)              _err "Comando inválido: $cmd"; usage; exit 1 ;;
esac