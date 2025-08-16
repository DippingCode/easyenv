#!/usr/bin/env bash
# workspace.sh - paths, arquivos, logging, YAML helpers e brew helpers

set -euo pipefail

EASYENV_HOME="${EASYENV_HOME:-$HOME/easyenv}"
CFG_FILE="$EASYENV_HOME/src/config/tools.yml"
SNAP_FILE="$EASYENV_HOME/src/config/.zshrc-tools.yml"
LOG_FILE="$EASYENV_HOME/src/logs/easyenv.log"
ZSHRC_FILE="$HOME/.zshrc"

ensure_workspace_dirs(){
  mkdir -p "$EASYENV_HOME" \
           "$(dirname "$CFG_FILE")" \
           "$(dirname "$SNAP_FILE")" \
           "$(dirname "$LOG_FILE")"
}

log_line(){
  local cmd="$1" status="$2" msg="$3"
  ensure_workspace_dirs
  printf "[%s] cmd=%s status=%s msg=%s\n" "$(date +"%Y-%m-%d %H:%M:%S")" "$cmd" "$status" "$msg" >> "$LOG_FILE"
}

# ---------- YAML helpers ----------
yq_get(){ yq -r "$1" "$2"; }

list_sections(){
  if [[ -f "$CFG_FILE" ]]; then
    yq -r '.tools[].section' "$CFG_FILE" | sed '/^null$/d' | sort -u
  fi
}

list_tools_by_section(){
  local sec="$1"
  yq -r ".tools[] | select(.section==\"$sec\") | .name" "$CFG_FILE"
}

tool_field(){
  local name="$1" path="$2"
  yq -r ".tools[] | select(.name==\"$name\") | $path" "$CFG_FILE"
}

# ---------- brew helpers ----------
prime_brew_shellenv(){
  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
}

brew_update_quick(){ command -v brew >/dev/null 2>&1 && brew update >/dev/null; }

brew_install_if_needed(){
  local pkg="$1"
  if [[ -z "$pkg" || "$pkg" == "null" ]]; then return 0; fi
  if brew list --formula | grep -qx "$pkg"; then
    info "brew: $pkg já instalado."
  else
    info "brew install $pkg"
    brew install "$pkg"
  fi
}

brew_cask_install_if_needed(){
  local cask="$1"
  if [[ -z "$cask" || "$cask" == "null" ]]; then return 0; fi
  if brew list --cask | grep -qx "$cask"; then
    info "brew cask: $cask já instalado."
  else
    info "brew install --cask $cask"
    brew install --cask "$cask"
  fi
}

# ---------- .zshrc helpers ----------
append_once(){
  local file="$1" marker="$2" block="$3"
  touch "$file"
  if ! grep -qF "$marker" "$file"; then
    printf "\n%s\n%s\n" "$marker" "$block" >> "$file"
  fi
}

append_lines_once(){
  local file="$1" marker="$2"; shift 2
  append_once "$file" "$marker" "$marker"
  while IFS= read -r line; do
    [[ -z "${line:-}" || "$line" == "null" ]] && continue
    grep -qxF "$line" "$file" || printf "%s\n" "$line" >> "$file"
  done < <(printf "%s\n" "$@")
}

# ---------- brew uninstall helpers ----------
brew_uninstall_if_installed(){
  local pkg="$1"
  [[ -z "$pkg" || "$pkg" == "null" ]] && return 0
  if brew list --formula | grep -qx "$pkg"; then
    info "brew uninstall $pkg"
    brew uninstall "$pkg"
  else
    info "brew: $pkg não está instalado (formula)."
  fi
}

brew_cask_uninstall_if_installed(){
  local cask="$1"
  [[ -z "$cask" || "$cask" == "null" ]] && return 0
  if brew list --cask | grep -qx "$cask"; then
    info "brew uninstall --cask $cask"
    brew uninstall --cask "$cask"
  else
    info "brew: $cask não está instalado (cask)."
  fi
}

brew_cleanup_safe(){
  if command -v brew >/dev/null 2>&1; then
    info "Executando brew cleanup -s (safe)…"
    brew cleanup -s || true
  fi
}

# ---------- ferramentas/listas ----------
list_all_tools(){
  yq -r '.tools[].name' "$CFG_FILE"
}

# ---------- zshrc cleanup ----------
zshrc_backup(){
  [[ -f "$ZSHRC_FILE" ]] && cp "$ZSHRC_FILE" "${ZSHRC_FILE}.bak.$(date +%Y%m%d%H%M%S)"
}

zshrc_remove_easyenv_markers(){
  # Remove linhas de marcação do EasyEnv; mantém backup acima.
  [[ ! -f "$ZSHRC_FILE" ]] && return 0
  # Remove linhas que contenham nossos marcadores
  sed -i '' '/^# ----- EASYENV (auto) -----/d' "$ZSHRC_FILE" || true
  sed -i '' '/^# EASYENV env/d' "$ZSHRC_FILE" || true
  sed -i '' '/^# EASYENV alias/d' "$ZSHRC_FILE" || true
}

# remove também as linhas de env/aliases definidas no catálogo (best effort)
zshrc_remove_tool_entries(){
  local name="$1"
  # env
  while IFS= read -r line; do
    [[ -z "${line:-}" || "$line" == "null" ]] && continue
    # escapa / para sed
    local escaped="${line//\//\\/}"
    sed -i '' "/^${escaped//\*/\\*}\$/d" "$ZSHRC_FILE" || true
  done < <(tool_field "$name" '.env[]?')

  # aliases
  while IFS= read -r line; do
    [[ -z "${line:-}" || "$line" == "null" ]] && continue
    local escaped="${line//\//\\/}"
    sed -i '' "/^${escaped//\*/\\*}\$/d" "$ZSHRC_FILE" || true
  done < <(tool_field "$name" '.aliases[]?')
}