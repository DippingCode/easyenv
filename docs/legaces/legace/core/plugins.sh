# src/core/plugins.sh
# Loader e contrato de plugins

EASYENV_PLUGINS_DIR="${EASYENV_PLUGINS_DIR:-$EASYENV_HOME/src/plugins}"

plugin_path_for(){
  local tool="$1"
  echo "$EASYENV_PLUGINS_DIR/$tool/plugin.sh"
}

plugin_load(){
  local tool="$1"
  local f; f="$(plugin_path_for "$tool")"
  if [[ -s "$f" ]]; then
    # shellcheck source=/dev/null
    source "$f"
    return 0
  fi
  return 1
}

# Helpers para invocar função se existir no plugin
plugin_call(){
  local fn="$1"; shift
  if declare -F "$fn" >/dev/null 2>&1; then
    "$fn" "$@"
  else
    return 127
  fi
}

# Convenção de nomes:
#   tool_name            → imprime o nome do plugin (ex.: "node")
#   tool_provides        → lista capacidades ("versions switch install uninstall check update env")
#   tool_versions        → lista versões (destaca ativa)
#   tool_switch <ver>    → muda versão
#   tool_install         → instala gerenciador runtime
#   tool_uninstall       → desinstala
#   tool_update          → atualiza
#   tool_check           → retorna 0 se ok, 1 se ausente
#   tool_env             → echo de exports a injetar no .zshrc (se precisar)