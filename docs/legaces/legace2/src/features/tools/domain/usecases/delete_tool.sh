# uc_delete_tool
# Entrada: nome da tool
# Saída: nada (sucesso) | mensagem de erro no stderr
# Retornos: 0 sucesso | 1 erro infra/uso | 2 não encontrada
uc_delete_tool() {
  local name="${1:-}"
  if [[ -z "$name" ]]; then
    echo "uc_delete_tool: informe o nome da ferramenta" >&2
    return 1
  fi

  # garantir datasource
  if ! declare -F tools_ds_delete_tool >/dev/null 2>&1; then
    local base="${EASYENV_HOME:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)}"
    # shellcheck disable=SC1091
    source "$base/src/data/datasources/tools_datasource.sh" || {
      echo "uc_delete_tool: não foi possível carregar tools_datasource.sh" >&2
      return 1
    }
  fi

  if ! tools_ds_delete_tool "$name"; then
    local rc=$?
    [[ $rc -eq 2 ]] && return 2
    return 1
  fi

  return 0
}