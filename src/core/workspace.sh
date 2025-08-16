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