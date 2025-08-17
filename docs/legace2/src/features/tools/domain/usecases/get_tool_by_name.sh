# uc_get_tool_by_name
# Entrada: nome da tool (case-insensitive); Saída: JSON da tool (linha única)
# Retornos: 0 sucesso | 1 erro infra/uso | 2 não encontrada
uc_get_tool_by_name() {
  local name="${1:-}"
  if [[ -z "$name" ]]; then
    echo "uc_get_tool_by_name: informe o nome da ferramenta" >&2
    return 1
  fi

  # garantir datasource
  if ! declare -F tools_ds_get_tool_by_name >/dev/null 2>&1; then
    local base="${EASYENV_HOME:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)}"
    # shellcheck disable=SC1091
    source "$base/src/data/datasources/tools_datasource.sh" || {
      echo "uc_get_tool_by_name: não foi possível carregar tools_datasource.sh" >&2
      return 1
    }
  fi

  local found
  if ! found="$(tools_ds_get_tool_by_name "$name")"; then
    # Se o datasource retornou 2, propaga como 2 (não encontrada)
    local rc=$?
    [[ $rc -eq 2 ]] && return 2
    return 1
  fi

  # Normalização leve (garante JSON compacto)
  echo "$found" | jq -c .
  return 0
}