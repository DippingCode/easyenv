#!/usr/bin/env bash
# discovery.sh — varredura do ambiente real e sincronização com snapshot

set -euo pipefail

# Reuso de helpers do core
# Espera-se que utils.sh, workspace.sh e tools.sh já estejam "sourceados" por easyenv.sh

# --- Detecta se a TOOL tem bloco EASYENV ativo no ~/.zshrc ---
is_tool_enabled_in_zshrc(){
  local tool="$1"
  [[ -f "$HOME/.zshrc" ]] || { echo "false"; return 0; }
  local TU; TU="$(echo "$tool" | tr '[:lower:]' '[:upper:]')"
  if grep -qE "^# >>> EASYENV:${TU}(:[A-Za-z0-9]+)? >>>$" "$HOME/.zshrc"; then
    echo "true"
  else
    echo "false"
  fi
}

# --- Heurística padrão: origem do binário (system/homebrew/other/not-found) ---
detect_origin_generic(){
  local bin="$1"
  local p
  p="$(command -v "$bin" 2>/dev/null || true)"
  if [[ -z "$p" ]]; then
    echo "not-found"
    return 0
  fi
  # Homebrew?
  if [[ "$p" == /opt/homebrew/* || "$p" == $(brew --prefix 2>/dev/null || echo /opt/homebrew)/* ]]; then
    echo "homebrew:$p"
  else
    # Alguns gerenciadores
    if [[ "$p" == "$HOME/.nvm/"* || "$p" == "$HOME/.fvm/"* || "$p" == "$HOME/.deno/"* ]]; then
      echo "other:$p"
    else
      echo "system:$p"
    fi
  fi
}

# --- Heurística padrão: versão (tenta --version | -v | version) ---
detect_version_generic(){
  local bin="$1"
  for flag in "--version" "-v" "version"; do
    if out="$(bash -lc "$bin $flag" 2>/dev/null | head -n1)"; then
      [[ -n "$out" ]] && { echo "$out"; return 0; }
    fi
  done
  echo "-"
}

# --- Chama plugin tool_detect se existir; senão heurística genérica ---
discover_tool_state(){
  local name="$1"

  # tenta plugin
  if plugin_load "$name" && declare -F tool_detect >/dev/null 2>&1; then
    if out="$(plugin_call tool_detect)"; then
      # Espera JSON {"origin":"...","version":"...","enabled":"true|false"}
      echo "$out"
      return 0
    fi
  fi

  # genérico
  local enabled origin version
  enabled="$(is_tool_enabled_in_zshrc "$name")"
  origin="$(detect_origin_generic "$name")"
  if [[ "$origin" == "not-found" ]]; then
    version="-"
  else
    version="$(detect_version_generic "$name")"
  fi

  jq -n \
    --arg origin "$origin" \
    --arg version "$version" \
    --arg enabled "$enabled" \
    '{origin:$origin, version:$version, enabled: ($enabled=="true") }'
}

# --- Descobre todas as tools (união: catálogo + markers ativados) ---
discover_all_tools_json(){
  require_cmd "yq" "brew install yq"
  local -a names=()

  # do catálogo
  while IFS= read -r n; do
    [[ -n "$n" && "$n" != "null" ]] && names+=("$n")
  done < <(yq -r '.tools[].name' "$CFG_FILE" 2>/dev/null || true)

  # dos markers EASYENV no .zshrc (podem existir tools que não estão no catálogo)
  if [[ -f "$HOME/.zshrc" ]]; then
    while IFS= read -r line; do
      # linha do tipo: "# >>> EASYENV:TOOL(:id)? >>>"
      local t
      t="$(echo "$line" | sed -E 's/^# >>> EASYENV:([A-Z0-9_-]+)(:.*)? >>>$/\1/' | tr '[:upper:]' '[:lower:]')"
      [[ -n "$t" ]] && names+=("$t")
    done < <(grep -E '^# >>> EASYENV:[A-Z0-9_-]+' "$HOME/.zshrc" 2>/dev/null || true)
  fi

  # dedup
  if ((${#names[@]})); then
    printf "%s\n" "${names[@]}" | awk '!seen[$0]++'
  fi
}

# --- Gera um JSON de status: { tools: [ {name, origin, version, enabled} ] } ---
discovery_snapshot_json(){
  local arr="[]"
  while IFS= read -r n; do
    [[ -z "$n" ]] && continue
    local s; s="$(discover_tool_state "$n")"
    arr="$(jq -c --arg name "$n" --argjson s "$s" \
      '. + [{name:$name, origin:$s.origin, version:$s.version, enabled:$s.enabled}]' <<<"$arr")"
  done < <(discover_all_tools_json)
  jq -c --arg now "$(date -Iseconds)" \
    --arg host "$(hostname -s 2>/dev/null || echo host)" \
    --arg shell "zsh" \
    --arg user "$USER" \
    --arg home "$HOME" \
    --arg easyenv "$EASYENV_HOME" \
    --arg cfg "$CFG_FILE" \
    '{generated_at:$now, host:$host, shell:$shell, user:$user, home:$home, config:$cfg, easyenv:$easyenv, tools:.}'
    <<<"$arr"
}

# --- Grava ou atualiza o snapshot YAML com a última descoberta ---
write_snapshot_from_discovery(){
  ensure_workspace_dirs
  local tmpjson; tmpjson="$(discovery_snapshot_json)"

  # converte p/ YAML e escreve em .zshrc-tools.yml na seção .discovery
  local tmpy; tmpy="$(mktemp)"
  yq -P '.' <<<"$tmpjson" > "$tmpy"

  # mescla respeitando outras chaves existentes no snapshot
  if [[ -f "$SNAP_FILE" ]]; then
    yq -i '.discovery = load("'"$tmpy"'")' "$SNAP_FILE"
  else
    # cria snapshot novo com estrutura básica
    cat > "$SNAP_FILE" <<YAML
workspace: {}
preferences: {}
discovery: {}
YAML
    yq -i '.discovery = load("'"$tmpy"'")' "$SNAP_FILE"
  fi
  rm -f "$tmpy"
  ok "Snapshot atualizado com descoberta atual em: $SNAP_FILE (.discovery)"
}