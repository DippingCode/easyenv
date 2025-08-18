# uc_insert_tool
# Entrada: JSON da tool via argumento único OU STDIN (precisa de .name)
# Saída: JSON da tool inserida (linha única)
# Retornos: 0 sucesso | 1 erro (ex.: já existe, JSON inválido, infra)
uc_insert_tool() {
  local arg_json="${1:-}"
  local payload=""

  if [[ -n "$arg_json" ]]; then
    payload="$arg_json"
  else
    if ! IFS= read -r -t 0.1 payload; then
      echo "uc_insert_tool: informe o JSON via argumento ou STDIN" >&2
      return 1
    fi
    local rest
    while IFS= read -r rest; do payload+=$'\n'"$rest"; done
  fi

  if ! echo "$payload" | jq -e . >/dev/null 2>&1; then
    echo "uc_insert_tool: JSON inválido" >&2
    return 1
  fi
  local name
  name="$(echo "$payload" | jq -r '.name // empty')"
  if [[ -z "$name" || "$name" == "null" ]]; then
    echo "uc_insert_tool: campo obrigatório 'name' ausente" >&2
    return 1
  fi

  # garantir datasource
  if ! declare -F tools_ds_insert_tool >/dev/null 2>&1; then
    local base="${EASYENV_HOME:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)}"
    # shellcheck disable=SC1091
    source "$base/src/data/datasources/tools_datasource.sh" || {
      echo "uc_insert_tool: não foi possível carregar tools_datasource.sh" >&2
      return 1
    }
  fi

  local out
  if ! out="$(tools_ds_insert_tool "$payload")"; then
    return 1
  fi

  echo "$out" | jq -c .
  return 0
}