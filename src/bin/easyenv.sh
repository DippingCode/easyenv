#!/usr/bin/env bash
set -euo pipefail

# -----------------------------------------------------------------------------
# EasyEnv - bootstrap para ambiente de dev
# -----------------------------------------------------------------------------

EASYENV_VERSION="0.1.0"   # atualize conforme for lançando

# Define diretórios
EASYENV_HOME="${EASYENV_HOME:-$HOME/easyenv}"
SRC_DIR="$EASYENV_HOME/src"
CORE_DIR="$SRC_DIR/core"
BIN_DIR="$SRC_DIR/bin"
CFG_FILE="$EASYENV_HOME/tools.yml"
SNAP_FILE="$EASYENV_HOME/snapshot.yml"
BACKUP_DIR="$EASYENV_HOME/backups"

source "$EASYENV_HOME/src/bin/switch.sh"
source "$EASYENV_HOME/src/bin/versions.sh"

source "$CORE_DIR/plugins.sh"
source "$CORE_DIR/themes.sh"

# -----------------------------------------------------------------------------
# Carregar núcleo (core helpers)
# -----------------------------------------------------------------------------
for f in "$CORE_DIR"/*.sh; do
  [ -r "$f" ] && source "$f"
done

# -----------------------------------------------------------------------------
# Carregar comandos (cada um em src/bin/*.sh, exceto este easyenv.sh)
# -----------------------------------------------------------------------------
for f in "$BIN_DIR"/*.sh; do
  [[ "$f" != "$BIN_DIR/easyenv.sh" ]] && source "$f"
done

# -----------------------------------------------------------------------------
# Dispatcher principal
# -----------------------------------------------------------------------------
main() {
  # ---- FLAGS GLOBAIS (capturadas antes do roteamento) ----
  case "${1:-}" in
    -v|--v|--version|version)
      log_line "version" "start" "-"
      cmd_version
      log_line "version" "success" "ok"
      return 0
      ;;
    -h|--h|--help| -help|help)
      log_line "help" "start" "-"
      cmd_help
      log_line "help" "success" "ok"
      return 0
      ;;
  esac

  # ---- ROTEAMENTO DE SUBCOMANDOS ----
  local cmd="${1:-help}"; shift || true

  case "$cmd" in
    status)
      cmd_status "$@"
      ;;
    init)
      cmd_init "$@"
      ;;
    backup)
      cmd_backup "$@"
      ;;
    theme)
      cmd_theme "$@"
      ;;
    add)
      cmd_add "$@"
      ;;
    clean)
      cmd_clean "$@"
      ;;
    update)
      cmd_update "$@"
      ;;
    versions)
      cmd_versions "$@"
      ;;
    doctor)
      cmd_doctor "$@"
      ;;
    *)
      err "Comando desconhecido: $cmd"
      echo
      cmd_help
      exit 1
      ;;
  esac
}

# -----------------------------------------------------------------------------
# Ajuda central
# -----------------------------------------------------------------------------
cmd_help() {
  cat <<EOF
Uso: easyenv <comando> [opções]

Comandos disponíveis:
  status       Mostra status do workspace (tools, prefs, backups)
  init         Inicializa ambiente (instala seções e tema)
  backup       Cria/lista/restaura/apaga backups
  theme        Gerencia tema do Oh My Zsh
  add          Instala tool via brew e registra no catálogo
  clean        Limpa cache, locks e diretórios temporários
  update       Atualiza ferramentas/temas e snapshot

Opções globais:
  -h, --help   Mostra esta ajuda

Exemplos:
  easyenv status --detailed
  easyenv init -steps
  easyenv backup -list
  easyenv theme set powerlevel10k
  easyenv add jq
  easyenv clean
  easyenv update

EOF
}

cmd_version(){
  echo "easyenv v$EASYENV_VERSION"
}

# -----------------------------------------------------------------------------
# Bootstrap
# -----------------------------------------------------------------------------
main "$@"