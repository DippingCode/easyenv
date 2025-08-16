#!/usr/bin/env bash
# utils.sh - helpers genéricos

set -euo pipefail

# Cores simples
_red(){ printf "\033[31m%s\033[0m\n" "$*"; }
_yel(){ printf "\033[33m%s\033[0m\n" "$*"; }
_grn(){ printf "\033[32m%s\033[0m\n" "$*"; }
_bld(){ printf "\033[1m%s\033[0m\n" "$*"; }

ts(){ date +"%Y-%m-%d %H:%M:%S"; }

ok(){ _grn "✅ $*"; }
warn(){ _yel "⚠️  $*"; }
err(){ _red "❌ $*" >&2; }
info(){ printf "➜ %s\n" "$*"; }

confirm(){
  local msg="${1:-Confirmar?}"
  read -r -p "$msg (yes/NO) " ans || true
  [[ "$ans" =~ ^(y|Y|yes|YES)$ ]]
}

require_cmd(){
  local c="$1"; local hint="${2:-instale a dependência e tente novamente.}"
  if ! command -v "$c" >/dev/null 2>&1; then
    err "Dependência ausente: $c. $hint"
    exit 1
  fi
}

ensure_dir(){ mkdir -p "$1"; }

append_once(){
  local file="$1" marker="$2" block="$3"
  touch "$file"
  if ! grep -qF "$marker" "$file"; then
    printf "\n%s\n%s\n" "$marker" "$block" >> "$file"
  fi
}