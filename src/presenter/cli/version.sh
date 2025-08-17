#!/usr/bin/env bash
# src/presenter/cli/version.sh
# Mostra versão atual do projeto a partir do dev-log (primeira entrada, newest-first)
# Flags:
#   easyenv version           -> "easyenv vX (build Y)"
#   easyenv version --detailed -> imprime detalhes: version, build, commit, date, scope, author, summary, notes, next_steps

set -euo pipefail

__find_devlog_file() {
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

# Caminho rápido: ler só o topo para pegar version/build (mais performático)
# Por padrão, tenta ler apenas as N primeiras linhas para extrair .tasks[0].version/build
__read_quick_version_build() {
  local devlog="$1" head_lines="${DEVLOG_HEAD_LINES:-20}"
  # Tenta com head; se falhar, tenta arquivo completo.
  local out
  if out="$(head -n "$head_lines" "$devlog" | yq -r '.tasks[0] | [( .version // "" ), ( .build // "" )] | @tsv' 2>/dev/null)"; then
    printf "%s" "$out"
    return 0
  fi
  # Fallback: arquivo inteiro
  yq -r '.tasks[0] | [( .version // "" ), ( .build // "" )] | @tsv' "$devlog"
}

__print_array_section() {
  local title="$1" devlog="$2" jq_path="$3"
  # Extrai array como linhas
  mapfile -t arr < <(yq -r "$jq_path" "$devlog" 2>/dev/null || true)
  if (( ${#arr[@]} == 0 )) || [[ "${arr[0]}" == "null" ]]; then
    printf "  %s:\n    —\n" "$title"
    return 0
  fi
  printf "  %s:\n" "$title"
  local line
  for line in "${arr[@]}"; do
    # yq -r pode imprimir strings já sem aspas
    [[ -z "$line" || "$line" == "null" ]] && continue
    printf "    - %s\n" "$line"
  done
}

cmd_version() {
  local detailed=0
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --detailed) detailed=1 ;;
      -h|--help)
        cat <<EOF
Uso:
  easyenv version           Mostra versão e build atuais (dev-log tasks[0])
  easyenv version --detailed
                            Mostra detalhes completos desta build (commit, date, scope, author, summary, notes, next_steps)
EOF
        return 0
        ;;
      *)
        # ignore positional
        ;;
    esac
    shift || true
  done

  local devlog; devlog="$(__find_devlog_file)"
  if [[ -z "$devlog" ]]; then
    echo "easyenv v0.0.0 (build 00)"
    return 0
  fi

  # Caminho rápido p/ versão+build
  local vb ver build
  vb="$(__read_quick_version_build "$devlog" 2>/dev/null || true)"
  IFS=$'\t' read -r ver build <<<"$vb"
  [[ -z "${ver:-}"   || "$ver" == "null"   ]] && ver="0.0.0"
  [[ -z "${build:-}" || "$build" == "null" ]] && build="00"

  if (( detailed==0 )); then
    echo "easyenv v$ver (build $build)"
    return 0
  fi

  # Detalhado: lê mais campos da PRIMEIRA entrada (tasks[0])
  local date author scope commit
  date="$(yq -r '.tasks[0].date // ""' "$devlog" 2>/dev/null || true)"
  author="$(yq -r '.tasks[0].author // ""' "$devlog" 2>/dev/null || true)"
  scope="$(yq -r '.tasks[0].version_scope // ""' "$devlog" 2>/dev/null || true)"
  commit="$(yq -r '.tasks[0].commit // ""' "$devlog" 2>/dev/null || true)"

  echo "EasyEnv — versão atual"
  echo "  version: $ver"
  echo "  build  : $build"
  [[ -n "$commit" && "$commit" != "null" ]] && echo "  commit : $commit"
  [[ -n "$date"   && "$date"   != "null" ]] && echo "  date   : $date"
  [[ -n "$scope"  && "$scope"  != "null" ]] && echo "  scope  : $scope"
  [[ -n "$author" && "$author" != "null" ]] && echo "  author : $author"
  echo

  __print_array_section "summary"   "$devlog" '.tasks[0].summary[]?'
  __print_array_section "notes"     "$devlog" '.tasks[0].notes[]?'
  __print_array_section "next_steps"$devlog" '.tasks[0].next_steps[]?'
}