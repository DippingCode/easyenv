#!/usr/bin/env bash
# src/core/utils.sh
# Utilitários básicos: cores, prints, datas, prompt, strings, uuid, tamanhos humanos.

set -euo pipefail

# --------- Cores / Estilo ----------
__CLR_RESET="\033[0m"
__CLR_BOLD="\033[1m"
__CLR_RED="\033[31m"
__CLR_GRN="\033[32m"
__CLR_YEL="\033[33m"
__CLR_BLU="\033[34m"

_bld(){ printf "${__CLR_BOLD}%s${__CLR_RESET}\n" "$*"; }
_red(){ printf "${__CLR_RED}%s${__CLR_RESET}\n" "$*"; }
_grn(){ printf "${__CLR_GRN}%s${__CLR_RESET}\n" "$*"; }
_yel(){ printf "${__CLR_YEL}%s${__CLR_RESET}\n" "$*"; }
_blu(){ printf "${__CLR_BLU}%s${__CLR_RESET}\n" "$*"; }

ok(){ _grn "✅ $*"; }
warn(){ _yel "⚠️  $*"; }
err(){ _red "❌ $*" >&2; }
info(){ printf "➜ %s\n" "$*"; }

# --------- Datas ----------
# ISO-8601 com timezone: 2025-08-17T13:20:00-03:00
iso_now(){
  local raw tzfix
  raw="$(date +"%Y-%m-%dT%H:%M:%S%z")"
  tzfix="$(printf "%s" "$raw" | sed -E 's/([0-9]{2})([0-9]{2})$/\1:\2/')"
  printf "%s" "$tzfix"
}

# --------- Prompt ----------
confirm(){
  local msg="${1:-Confirmar?}"
  local def="${2:-NO}"   # yes/NO
  local hint="(yes/NO)"
  [[ "${def,,}" == "yes" ]] && hint="(YES/no)"
  read -r -p "$msg $hint " ans || true
  if [[ "${def,,}" == "yes" ]]; then
    [[ "$ans" =~ ^(y|Y|yes|YES)?$ ]]
  else
    [[ "$ans" =~ ^(y|Y|yes|YES)$ ]]
  fi
}

# --------- Strings ----------
join_by(){ local IFS="$1"; shift; printf "%s" "$*"; }

# --------- Tamanho humano ----------
human_size(){
  local bytes="${1:-0}"
  if [[ "$bytes" -lt 1024 ]]; then printf "%dB" "$bytes"; return; fi
  local kb=$((bytes/1024))
  if [[ "$kb" -lt 1024 ]]; then printf "%dKB" "$kb"; return; fi
  local mb=$((kb/1024))
  if [[ "$mb" -lt 1024 ]]; then printf "%dMB" "$mb"; return; fi
  local gb=$((mb/1024))
  printf "%dGB" "$gb"
}

# --------- FS ----------
ensure_dir(){ mkdir -p "$1"; }

# --------- Dependências simples ----------
require_cmd(){
  local c="$1"; local hint="${2:-instale e tente novamente.}"
  command -v "$c" >/dev/null 2>&1 || { err "Dependência ausente: $c — $hint"; exit 1; }
}

# --------- UUID/GUID ----------
# Gera um GUID (preferindo uuidgen; fallbacks compatíveis com macOS/Linux)
gen_uuid(){
  if command -v uuidgen >/dev/null 2>&1; then
    uuidgen
    return
  fi
  if command -v python3 >/dev/null 2>&1; then
    python3 - <<'PY'
import uuid; print(str(uuid.uuid4()))
PY
    return
  fi
  # fallback simples (não RFC) baseado em /dev/urandom
  hexdump -n 16 -v -e '4/4 "%08X" 1 "\n"' /dev/urandom 2>/dev/null \
    | awk '{print tolower(substr($0,1,8) "-" substr($0,9,4) "-" substr($0,13,4) "-" substr($0,17,4) "-" substr($0,21,12))}'
}