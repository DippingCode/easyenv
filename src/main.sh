#!/usr/bin/env bash
# src/main.sh — ponto de entrada do easyenv

set -euo pipefail

# Raiz do projeto (src/..)
EASYENV_HOME="$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd)"
export EASYENV_HOME

# Carrega core
source "$EASYENV_HOME/src/core/config.sh"
source "$EASYENV_HOME/src/core/utils.sh"
source "$EASYENV_HOME/src/core/logging.sh"
source "$EASYENV_HOME/src/core/guards.sh"
source "$EASYENV_HOME/src/core/router.sh"

# Despacha
router_dispatch "$@"