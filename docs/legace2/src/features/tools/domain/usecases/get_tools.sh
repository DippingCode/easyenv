# uc_get_tools
# Saída: JSON array com todas as tools ([] se vazio)
# Retornos: 0 sucesso | 1 erro
uc_get_tools() {
  # garantir datasource
  if ! declare -F tools_ds_get_tools >/dev/null 2>&1; then
    local base="${EASYENV_HOME:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)}"
    # shellcheck disable=SC1091
    source "$base/src/data/datasources/tools_datasource.sh" || {
      echo "uc_get_tools: não foi possível carregar tools_datasource.sh" >&2
      return 1
    }
  fi

  local lines
  if ! lines="$(tools_ds_get_tools)"; then
    return 1
  fi

  # Converte “JSON por linha” → array JSON
  if [[ -z "$lines" ]]; then
    echo '[]'
  else
    echo "$lines" | jq -cs .
  fi
  return 0
}