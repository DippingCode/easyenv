#!/usr/bin/env bash
# EasyEnv — ponto de entrada
# Responsável apenas por compor os módulos core e delegar ao router.

set -euo pipefail

# Resolve diretórios
# main.sh fica em: <repo>/src/main.sh  → EASYENV_HOME = <repo>
__BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export EASYENV_HOME="${EASYENV_HOME:-"$(cd "${__BASE_DIR}/.." && pwd)"}"

# Caminhos core
CORE_DIR="$EASYENV_HOME/src/core"
LOG_DIR="$EASYENV_HOME/var/logs"

# Carrega módulos core (alguns podem ainda não existir nas primeiras builds)
# Cada "source" é tolerante a ausência, mas o router é obrigatório.
[[ -f "$CORE_DIR/config.sh"   ]] && source "$CORE_DIR/config.sh"
[[ -f "$CORE_DIR/utils.sh"    ]] && source "$CORE_DIR/utils.sh"
[[ -f "$CORE_DIR/logging.sh"  ]] && source "$CORE_DIR/logging.sh"
[[ -f "$CORE_DIR/guards.sh"   ]] && source "$CORE_DIR/guards.sh"

# Router é obrigatório
if [[ ! -f "$CORE_DIR/router.sh" ]]; then
  echo "❌ core/router.sh não encontrado em: $CORE_DIR" >&2
  echo "   Estrutura esperada: $EASYENV_HOME/src/core/router.sh" >&2
  exit 1
fi
source "$CORE_DIR/router.sh"

# Garante diretório de logs
mkdir -p "$LOG_DIR"

# Despacha o comando
router_dispatch "$@"