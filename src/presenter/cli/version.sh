#!/usr/bin/env bash
# presenter/cli/version.sh
# Exibe a versão do easyenv baseada na última entrada do /dev_log.yml
# Suporte: -v/--version (router já redireciona), --detailed, -h/--help

set -euo pipefail

cmd_version_help() {
  cat <<'EOF'
Uso:
  easyenv version [--detailed]

Descrição:
  Lê a versão atual a partir do topo de /dev_log.yml (primeira entrada em tasks).

Opções:
  --detailed    Mostra detalhes da build (version, build, summary, notes, next_steps)
  -h, --help    Mostra esta ajuda

Exemplos:
  easyenv version
  easyenv version --detailed
EOF
}

# Lê o topo do dev_log.yml com yq.
# Retorna 0 se conseguir ler, 1 caso contrário.
_read_devlog_top() {
  local devlog="${EASYENV_HOME:-$HOME}/dev_log.yml"
  [[ -f "$devlog" ]] || return 1
  command -v yq >/dev/null 2>&1 || return 1

  # Exporta variáveis globais com os campos principais.
  DEVLOG_VERSION="$(yq -r '.tasks[0].version // ""' "$devlog" 2>/dev/null || echo "")"
  DEVLOG_BUILD="$(yq -r '.tasks[0].build // ""' "$devlog" 2>/dev/null || echo "")"

  # Arrays impressos depois (mantemos texto pronto em variáveis)
  DEVLOG_SUMMARY="$(yq -r '.tasks[0].summary // [] | @json' "$devlog" 2>/dev/null || echo "[]")"
  DEVLOG_NOTES="$(yq -r '.tasks[0].notes // [] | @json' "$devlog" 2>/dev/null || echo "[]")"
  DEVLOG_NEXT="$(yq -r '.tasks[0].next_steps // [] | @json' "$devlog" 2>/dev/null || echo "[]")"

  [[ -n "${DEVLOG_VERSION:-}" ]]
}

_print_list_from_json_array() {
  # recebe JSON array em $1 e um prefixo de bullet em $2 (ex.: " - ")
  local json="$1" bullet="${2:- - }"
  # Se tiver jq, usamos pra ficar robusto; senão, yq; senão, best-effort.
  if command -v jq >/dev/null 2>&1; then
    echo "$json" | jq -r ".[] | \"$bullet\" + tostring" 2>/dev/null || true
  elif command -v yq >/dev/null 2>&1; then
    # yq v4 consegue ler json também
    echo "$json" | yq -r '.[]' 2>/dev/null | sed "s/^/${bullet}/" || true
  else
    # fallback: tira colchetes e aspas simples
    echo "$json" | sed -E 's/^\[|\]$//g; s/^"|"$//g; s/","/\n/g; s/", "/\n/g' | sed "s/^/${bullet}/"
  fi
}

cmd_version() {
  local detailed=0

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --detailed) detailed=1 ;;
      -h|--help)  cmd_version_help; return 0 ;;
      *)          # ignora args extras silenciosamente
                  ;;
    esac
    shift || true
  done

  local version="0.0.0" build=""
  if _read_devlog_top; then
    version="$DEVLOG_VERSION"
    build="$DEVLOG_BUILD"
  fi

  # Linha única padrão (sem duplicar saída)
  if [[ -n "$build" && "$build" != "null" ]]; then
    echo "easyenv v${version} (build ${build})"
  else
    echo "easyenv v${version}"
  fi

  # Modo detalhado: imprime seções amigáveis
  if (( detailed==1 )); then
    echo
    echo "Detalhes:"
    printf "  • version: %s\n" "$version"
    printf "  • build  : %s\n" "${build:-"-"}"

    echo
    echo "O que há de novo:"
    _print_list_from_json_array "${DEVLOG_SUMMARY:-"[]"}" "   - "

    echo
    echo "Notas:"
    _print_list_from_json_array "${DEVLOG_NOTES:-"[]"}" "   - "

    echo
    echo "Próximos passos:"
    _print_list_from_json_array "${DEVLOG_NEXT:-"[]"}" "   - "
  fi
}