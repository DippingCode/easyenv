#!/usr/bin/env bash
# src/core/guards.sh
# Guardas mínimos para comandos.

set -euo pipefail

guard_cmd(){
  local c="$1"; local hint="${2:-instale e tente novamente.}"
  if ! command -v "$c" >/dev/null 2>&1; then
    err "Dependência ausente: $c — $hint"
    return 1
  fi
}

guard_file_exists(){
  local f="$1"; local msg="${2:-Arquivo não encontrado: $1}"
  [[ -f "$f" ]] || { err "$msg"; return 1; }
}

guard_dir_exists(){
  local d="$1"; local msg="${2:-Diretório não encontrado: $1}"
  [[ -d "$d" ]] || { err "$msg"; return 1; }
}