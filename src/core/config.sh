#!/usr/bin/env bash
# src/core/config.sh — configuração e caminhos

set -euo pipefail

# EASYENV_HOME deve apontar para a RAIZ do projeto (definido por main.sh)
if [[ -z "${EASYENV_HOME:-}" ]]; then
  # fallback robusto (se alguém carregar este arquivo isolado)
  _CFG_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  export EASYENV_HOME="$(cd "$_CFG_BASE/../.." && pwd)"
fi

# Caminhos padrão
export EASYENV_VAR_DIR="${EASYENV_VAR_DIR:-$EASYENV_HOME/var}"
export EASYENV_LOG_DIR="${EASYENV_LOG_DIR:-$EASYENV_VAR_DIR/logs}"
export EASYENV_SNAPSHOT_DIR="${EASYENV_SNAPSHOT_DIR:-$EASYENV_VAR_DIR/snapshot}"

# Arquivos de log
export EASYENV_LOG_USER="${EASYENV_LOG_USER:-$EASYENV_LOG_DIR/user.log}"
export EASYENV_LOG_DEBUG="${EASYENV_LOG_DEBUG:-$EASYENV_LOG_DIR/debug.log}"

# Catálogo de ferramentas
export EASYENV_TOOLS_YML="${EASYENV_TOOLS_YML:-$EASYENV_HOME/config/tools.yml}"

# Cria diretórios se não existirem
mkdir -p "$EASYENV_LOG_DIR" "$EASYENV_SNAPSHOT_DIR"

# ZSH defaults usados por algumas operações
export EASYENV_ZSHRC="${EASYENV_ZSHRC:-$HOME/.zshrc}"
export EASYENV_ZPROFILE="${EASYENV_ZPROFILE:-$HOME/.zprofile}"