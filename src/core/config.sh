#!/usr/bin/env bash
# src/core/config.sh — variáveis globais e paths

set -euo pipefail

# Diretórios base
export EASYENV_SRC="$EASYENV_HOME/src"
export EASYENV_CORE="$EASYENV_SRC/core"
export EASYENV_PRESENTER="$EASYENV_SRC/presenter"
export EASYENV_CLI="$EASYENV_PRESENTER/cli"
export EASYENV_TEMPLATES="$EASYENV_PRESENTER/templates"
export EASYENV_VIEWMODELS="$EASYENV_PRESENTER/viewmodels"
export EASYENV_DATA="$EASYENV_SRC/data"
export EASYENV_PLUGINS="$EASYENV_DATA/plugins"
export EASYENV_STACKS="$EASYENV_DATA/stacks"

# Config e runtime
export EASYENV_CONFIG_DIR="$EASYENV_HOME/config"
export EASYENV_VAR_DIR="$EASYENV_HOME/var"
export EASYENV_BACKUPS_DIR="$EASYENV_VAR_DIR/backups"
export EASYENV_LOGS_DIR="$EASYENV_VAR_DIR/logs"
export EASYENV_SNAPSHOT_DIR="$EASYENV_VAR_DIR/snapshot"

# Arquivos “fontes de verdade” do catálogo e snapshot
export EASYENV_TOOLS_FILE="$EASYENV_CONFIG_DIR/tools.yml"                 # (opcional, se migrarmos p/ plugins/.yml de cada tool)
export EASYENV_SNAPSHOT_FILE="$EASYENV_SNAPSHOT_DIR/.zshrc-tools.yml"     # reflexo do ambiente

# Dev-log (changelog de desenvolvimento)
find_devlog_file() {
  local candidates=(
    "$EASYENV_HOME/dev-log.yml"
    "$EASYENV_HOME/dev-log.yaml"
    "$EASYENV_HOME/docs/dev-log.yml"
    "$EASYENV_HOME/docs/dev-log.yaml"
  )
  local f
  for f in "${candidates[@]}"; do
    [[ -f "$f" ]] && { echo "$f"; return 0; }
  done
  echo ""
}
export -f find_devlog_file

# Garante estrutura de runtime
mkdir -p "$EASYENV_BACKUPS_DIR" "$EASYENV_LOGS_DIR" "$EASYENV_SNAPSHOT_DIR"