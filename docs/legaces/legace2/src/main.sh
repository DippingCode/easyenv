#!/usr/bin/env bash
# src/main.sh — ponto de entrada

set -euo pipefail

# BASE_DIR = .../easyenv/src
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# PROJECT_ROOT = .../easyenv
PROJECT_ROOT="$(cd "$BASE_DIR/.." && pwd)"

# EASYENV_HOME aponta para a RAIZ do projeto (não para src/)
export EASYENV_HOME="${EASYENV_HOME:-$PROJECT_ROOT}"

# Carrega core
source "$BASE_DIR/core/config.sh"
source "$BASE_DIR/core/utils.sh"
source "$BASE_DIR/core/logging.sh"
source "$BASE_DIR/core/guards.sh"
source "$BASE_DIR/core/router.sh"

# Despacha
router_dispatch "$@"