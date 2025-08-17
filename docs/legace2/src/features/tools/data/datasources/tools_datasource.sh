# -------------------------------------------------------------------
# tools_ds_get_tools
# Lê o catálogo em config/tools.yml e retorna TODAS as ferramentas
# no formato JSON (array de objetos). Esse JSON representa a
# "tool_entity" para as camadas superiores consumirem.
#
# Saída: JSON (ex.: [{"name":"jq","type":"cli",...}, ...])
# Requisitos: yq
# Obs.: Não altera arquivo; é somente leitura.
# -------------------------------------------------------------------
tools_ds_get_tools() {
  local catalog

  # Resolver caminho do catálogo:
  # 1) EASYENV_TOOLS_YML (se definido e existir)
  if [[ -n "${EASYENV_TOOLS_YML:-}" && -f "${EASYENV_TOOLS_YML}" ]]; then
    catalog="${EASYENV_TOOLS_YML}"
  else
    # 2) EASYENV_HOME/config/tools.yml
    local base="${EASYENV_HOME:-}"
    if [[ -z "$base" ]]; then
      # inferir a partir deste arquivo: ../../.. (raiz do projeto)
      base="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
      export EASYENV_HOME="$base"
    fi
    if [[ -f "$base/config/tools.yml" ]]; then
      catalog="$base/config/tools.yml"
    else
      # 3) fallback: tentar relativo ao CWD
      catalog="config/tools.yml"
    fi
  fi

  # Se não existir, devolve JSON vazio (não quebra o fluxo)
  if [[ ! -f "$catalog" ]]; then
    echo "[]"
    return 0
  fi

  # Garantir dependência
  if ! command -v yq >/dev/null 2>&1; then
    # Sem yq, retornamos vazio para não quebrar UX; camada superior pode avisar.
    echo "[]"
    return 0
  fi

  # Emitir JSON das tools (ou [] se campo inexistente)
  yq -o=json -r '.tools // []' "$catalog"
}

# -------------------------------------------------------------------
# tools_ds_get_tool_by_name
# Busca uma ferramenta por nome em config/tools.yml e retorna um
# único objeto JSON (a "tool_entity"). Caso não encontre, retorna {}.
#
# Uso:
#   tools_ds_get_tool_by_name "jq"
#
# Saída:
#   { "name":"jq", "type":"cli", ... }  # ou {}
# -------------------------------------------------------------------
tools_ds_get_tool_by_name() {
  local query_name="${1:-}"
  if [[ -z "$query_name" ]]; then
    echo "{}"
    return 0
  fi

  # Resolver caminho do catálogo (igual ao get_tools, mas local aqui)
  local catalog
  if [[ -n "${EASYENV_TOOLS_YML:-}" && -f "${EASYENV_TOOLS_YML}" ]]; then
    catalog="${EASYENV_TOOLS_YML}"
  else
    local base="${EASYENV_HOME:-}"
    if [[ -z "$base" ]]; then
      base="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
      export EASYENV_HOME="$base"
    fi
    if [[ -f "$base/config/tools.yml" ]]; then
      catalog="$base/config/tools.yml"
    else
      catalog="config/tools.yml"
    fi
  fi

  # Sem arquivo ou sem yq → {}
  if [[ ! -f "$catalog" ]] || ! command -v yq >/dev/null 2>&1; then
    echo "{}"
    return 0
  fi

  yq -o=json -r --arg n "$query_name" \
     '(.tools // []) | map(select(.name == $n)) | .[0] // {}' \
     "$catalog"
}

# -------------------------------------------------------------------
# tools_ds_get_tool_by_name
# Lê uma ferramenta específica do catálogo por nome.
# Saída: JSON do objeto da tool (linha única) ou nada se não encontrada.
# Retorna: 0 se encontrada, 1 se não encontrada ou erro.
# Uso:
#   tjson="$(tools_ds_get_tool_by_name "jq")" || echo "não achou"
# -------------------------------------------------------------------
tools_ds_get_tool_by_name() {
  local qname="${1:-}"
  if [[ -z "$qname" ]]; then
    echo "tools_ds_get_tool_by_name: nome não informado" >&2
    return 1
  fi

  # Resolve caminho do catálogo
  local catalog
  if [[ -n "${EASYENV_TOOLS_YML:-}" && -f "${EASYENV_TOOLS_YML}" ]]; then
    catalog="${EASYENV_TOOLS_YML}"
  else
    local base="${EASYENV_HOME:-}"
    if [[ -z "$base" ]]; then
      base="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
      export EASYENV_HOME="$base"
    fi
    if [[ -f "$base/config/tools.yml" ]]; then
      catalog="$base/config/tools.yml"
    else
      catalog="config/tools.yml"
    fi
  fi

  # Dependências básicas
  if ! command -v yq >/dev/null 2>&1; then
    echo "tools_ds_get_tool_by_name: 'yq' não encontrado" >&2
    return 1
  fi
  if [[ ! -f "$catalog" ]]; then
    echo "tools_ds_get_tool_by_name: catálogo não encontrado em: $catalog" >&2
    return 1
  fi

  # Busca por nome exato (case-sensitive). Ajuste para == ascii_downcase(strenv(NAME)) se quiser case-insensitive.
  NAME="$qname" yq -o=json '.tools[] | select(.name == strenv(NAME))' "$catalog" 2>/dev/null | jq -c . | {
    read -r line || true
    if [[ -n "$line" ]]; then
      echo "$line"
      exit 0
    else
      exit 1
    fi
  }
}

# -------------------------------------------------------------------
# tools_ds_update_tool
# Atualiza uma tool existente no catálogo (match por .name).
# Entrada: JSON da tool (via argumento único OU via STDIN). Campo "name" é obrigatório.
# Efeito: sobrescreve os campos da tool no config/tools.yml com os do JSON.
# Saída: JSON da tool atualizada (linha única).
# Retornos:
#   0 -> sucesso (tool encontrada e atualizada)
#   1 -> erro de uso/dependências/catálogo ausente
#   2 -> tool não encontrada
#
# Exemplos:
#   tools_ds_update_tool '{"name":"jq","description":"processador JSON rápido"}'
#   echo '{"name":"jq","deprecated":false}' | tools_ds_update_tool
# -------------------------------------------------------------------
tools_ds_update_tool() {
  local input_json="${1:-}"
  local payload

  # Carregar JSON do arg ou STDIN
  if [[ -n "$input_json" ]]; then
    payload="$input_json"
  else
    if ! IFS= read -r -t 0.1 payload; then
      echo "tools_ds_update_tool: forneça JSON via argumento ou STDIN" >&2
      return 1
    fi
    # ler restante do stdin (se houver)
    local rest
    while IFS= read -r rest; do
      payload+=$'\n'"$rest"
    done
  fi

  # Dependências
  if ! command -v yq >/dev/null 2>&1; then
    echo "tools_ds_update_tool: 'yq' não encontrado" >&2
    return 1
  fi
  if ! command -v jq >/dev/null 2>&1; then
    echo "tools_ds_update_tool: 'jq' não encontrado" >&2
    return 1
  fi

  # Validar JSON e extrair nome
  if ! echo "$payload" | jq -e . >/dev/null 2>&1; then
    echo "tools_ds_update_tool: JSON inválido" >&2
    return 1
  fi
  local name
  name="$(echo "$payload" | jq -r '.name // empty')"
  if [[ -z "$name" || "$name" == "null" ]]; then
    echo "tools_ds_update_tool: campo obrigatório 'name' ausente" >&2
    return 1
  fi

  # Resolver caminho do catálogo
  local catalog base
  if [[ -n "${EASYENV_TOOLS_YML:-}" && -f "${EASYENV_TOOLS_YML}" ]]; then
    catalog="${EASYENV_TOOLS_YML}"
  else
    base="${EASYENV_HOME:-}"
    if [[ -z "$base" ]]; then
      base="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
      export EASYENV_HOME="$base"
    fi
    if [[ -f "$base/config/tools.yml" ]]; then
      catalog="$base/config/tools.yml"
    else
      catalog="config/tools.yml"
    fi
  fi
  if [[ ! -f "$catalog" ]]; then
    echo "tools_ds_update_tool: catálogo não encontrado em: $catalog" >&2
    return 1
  fi

  # Verificar existência prévia
  if ! NAME="$name" yq -e '.tools[] | select(.name == strenv(NAME))' "$catalog" >/dev/null 2>&1; then
    echo "tools_ds_update_tool: tool '$name' não encontrada" >&2
    return 2
  fi

  # Backup simples antes de escrever
  local ts backup_path
  ts="$(date -u +%Y%m%dT%H%M%SZ)"
  backup_path="${catalog}.bak.${ts}"
  cp -f "$catalog" "$backup_path" 2>/dev/null || true

  # Converter JSON de entrada em YAML temporário (para merge limpo)
  local tmp_yaml
  tmp_yaml="$(mktemp -t easyenv_tool_update.XXXXXX.yaml)"
  echo "$payload" | yq -P -o=yaml > "$tmp_yaml"

  # Atualizar entrada no array .tools por nome (merge profundo)
  # Estratégia: mapeia .tools e, quando .name == NAME, aplica "with_entries" overwrite pelos campos do payload
  # Usamos "*+" para merge deep preferindo valores do payload.
  NAME="$name" yq -i '
    .tools = (.tools | map(
      if .name == strenv(NAME) then
        (. *+ load("'"$tmp_yaml"'"))
      else .
      end
    ))
  ' "$catalog"

  rm -f "$tmp_yaml" >/dev/null 2>&1 || true

  # Emitir a versão atualizada como JSON compacto
  NAME="$name" yq -o=json '.tools[] | select(.name == strenv(NAME))' "$catalog" | jq -c .

  return 0
}