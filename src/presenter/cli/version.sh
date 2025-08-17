#!/usr/bin/env bash
# presenter/cli/version.sh — easyenv version command

set -euo pipefail

# Caminho do dev_log.yml
__devlog_file() {
  local base="${EASYENV_HOME:-$HOME/easyenv}"
  echo "$base/docs/dev_log.yml"
}

# Lê (com yq) a versão/build da primeira task
__read_version_with_yq() {
  local f="$1"
  local ver="" build=""
  ver="$(yq -r '.tasks[0].version // "0.0.0"' "$f")"
  build="$(yq -r '.tasks[0].build // ""' "$f")"
  printf '%s\t%s\n' "$ver" "$build"
}

# Fallback robusto sem yq (grep+sed)
__read_version_fallback() {
  local f="$1"
  local ver="" build=""

  if [[ -f "$f" ]]; then
    # pega a PRIMEIRA ocorrência de 'version:' (após o topo do arquivo)
    ver="$(
      grep -m1 -E '^[[:space:]]*version:[[:space:]]*' "$f" \
      | sed -E 's/^[[:space:]]*version:[[:space:]]*"?([^"]*)"?/\1/'
    )"
    build="$(
      grep -m1 -E '^[[:space:]]*build:[[:space:]]*' "$f" \
      | sed -E 's/^[[:space:]]*build:[[:space:]]*"?([^"]*)"?/\1/'
    )"
  fi

  [[ -z "${ver:-}" ]] && ver="0.0.0"
  printf '%s\t%s\n' "$ver" "${build:-}"
}

__read_details_with_yq() {
  local f="$1"

  echo
  echo "Detalhes da build:"
  echo

  local ver build
  ver="$(yq -r '.tasks[0].version // "0.0.0"' "$f")"
  build="$(yq -r '.tasks[0].build // ""' "$f")"
  echo "  version: $ver"
  echo "  build  : ${build:-}"

  local count=0

  count="$(yq -r '.tasks[0].summary | length // 0' "$f")"
  if (( count > 0 )); then
    echo
    echo "Resumo:"
    yq -r '.tasks[0].summary[]' "$f" | sed 's/^/  - /'
  fi

  count="$(yq -r '.tasks[0].notes | length // 0' "$f")"
  if (( count > 0 )); then
    echo
    echo "Notas:"
    yq -r '.tasks[0].notes[]' "$f" | sed 's/^/  - /'
  fi

  count="$(yq -r '.tasks[0].next_steps | length // 0' "$f")"
  if (( count > 0 )); then
    echo
    echo "Próximos passos:"
    yq -r '.tasks[0].next_steps[]' "$f" | sed 's/^/  - /'
  fi
}

cmd_version() {
  local detailed=0
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --detailed) detailed=1 ;;
      -h|--help)  cmd_version_help; return 0 ;;
      *) ;;
    esac
    shift || true
  done

  local devlog; devlog="$(__devlog_file)"
  if [[ ! -f "$devlog" ]]; then
    echo "easyenv v0.0.0"
    (( detailed==1 )) && echo "(docs/dev_log.yml não encontrado)"
    return 0
  fi

  local ver build
  if command -v yq >/dev/null 2>&1; then
    IFS=$'\t' read -r ver build < <(__read_version_with_yq "$devlog")
  else
    IFS=$'\t' read -r ver build < <(__read_version_fallback "$devlog")
  fi

  if [[ -n "${build:-}" ]]; then
    echo "easyenv v${ver} (build ${build})"
  else
    echo "easyenv v${ver}"
  fi

  if (( detailed==1 )); then
    if command -v yq >/dev/null 2>&1; then
      __read_details_with_yq "$devlog"
    else
      echo
      echo "Para detalhes completos, instale o yq: brew install yq"
    fi
  fi
}

cmd_version_help() {
  cat <<'EOF'
Uso:
  easyenv version [--detailed]

Mostra a versão atual baseada no topo de docs/dev_log.yml.
Opções:
  --detailed   Exibe resumo, notas e próximos passos da build mais recente.
EOF
}