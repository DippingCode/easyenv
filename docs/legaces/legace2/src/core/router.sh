#!/usr/bin/env bash
# core/router.sh — despacho de subcomandos + captura e logging centralizados

set -euo pipefail

# --- dependências mínimas ---
EASYENV_HOME="${EASYENV_HOME:-$HOME/easyenv}"
PRESENTER_DIR="$EASYENV_HOME/src/presenter/cli"

# temp/log files (sempre inicializados p/ evitar erros com set -u)
: "${TMPDIR:="/tmp"}"
EASYENV_TMP_DIR="${EASYENV_TMP_DIR:-$TMPDIR/easyenv.$USER}"
mkdir -p "$EASYENV_TMP_DIR"
EASYENV_LOG_STDOUT="${EASYENV_LOG_STDOUT:-"$(mktemp "$EASYENV_TMP_DIR/easyenv.out.XXXXXX")"}"
EASYENV_LOG_STDERR="${EASYENV_LOG_STDERR:-"$(mktemp "$EASYENV_TMP_DIR/easyenv.err.XXXXXX")"}"
export EASYENV_LOG_STDOUT EASYENV_LOG_STDERR

# helpers locais
_router_list_commands() {
  if [[ -d "$PRESENTER_DIR" ]]; then
    (
      cd "$PRESENTER_DIR"
      for f in *.sh; do
        [[ "$f" == "*.sh" ]] && continue
        printf "%s\n" "${f%.sh}"
      done | sort -u
    )
  fi
}

router_usage() {
  cat <<'EOF'
Uso:
  easyenv <comando> [opções]

Atalhos:
  -h, --help      → help
  -v, --version   → version
  upgrade         → update
  diag            → doctor

Comandos disponíveis:
EOF
  while IFS= read -r c; do
    printf "  - %s\n" "$c"
  done < <(_router_list_commands)
}

# despacho
router_dispatch() {
  local cmd="${1:-help}"
  shift || true

  # aliases
  case "$cmd" in
    -h|--help) cmd="help" ;;
    -v|--version) cmd="version" ;;
    upgrade) cmd="update" ;;
    diag) cmd="doctor" ;;
  esac

  # logging begin (NÃO imprime nada)
  local REQ_ID=""
  if declare -F logging_begin >/dev/null 2>&1; then
    REQ_ID="$(logging_begin "$cmd" "$@")"
  fi

  # garante arquivos de captura
  : > "$EASYENV_LOG_STDOUT"
  : > "$EASYENV_LOG_STDERR"

  # carga do comando
  local script="$PRESENTER_DIR/$cmd.sh"
  if [[ ! -f "$script" ]]; then
    {
      echo "Comando desconhecido: $cmd"
      router_usage
    } 2>"$EASYENV_LOG_STDERR" | tee -a "$EASYENV_LOG_STDOUT"
    local ec=1
    if declare -F logging_end >/dev/null 2>&1; then
      logging_end "$REQ_ID" "$cmd" "$ec" "$EASYENV_LOG_STDOUT" "$EASYENV_LOG_STDERR" "$*"
    fi
    return "$ec"
  fi

  # executa o comando capturando stdout/stderr
  # shellcheck source=/dev/null
  {
    source "$script"
    "cmd_${cmd}" "$@"
  } >"$EASYENV_LOG_STDOUT" 2>"$EASYENV_LOG_STDERR"
  local ec=$?

  # encaminha saída ao usuário
  cat "$EASYENV_LOG_STDOUT"
  if (( ec != 0 )); then
    # em erro, também mostra stderr para facilitar diagnóstico
    if [[ -s "$EASYENV_LOG_STDERR" ]]; then
      printf "\n" 1>&2
      cat "$EASYENV_LOG_STDERR" 1>&2
    fi
  fi

  # logging end
  if declare -F logging_end >/dev/null 2>&1; then
    logging_end "$REQ_ID" "$cmd" "$ec" "$EASYENV_LOG_STDOUT" "$EASYENV_LOG_STDERR" "$*"
  fi
  return "$ec"
}