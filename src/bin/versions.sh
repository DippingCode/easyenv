cmd_versions(){
  local tool="${1:-}"
  if [[ -z "$tool" ]]; then
    err "Uso: easyenv versions <tool>"
    echo "Ex.: easyenv versions node | deno | flutter | dotnet | python | java | kotlin | angular"
    return 1
  fi
  if ! plugin_load "$tool"; then
    err "Plugin não encontrado para '$tool' em $EASYENV_HOME/src/plugins/$tool/plugin.sh"
    echo "Dica: crie um plugin: src/plugins/$tool/plugin.sh com a função tool_versions"
    return 1
  fi
  if plugin_call tool_versions; then
    return 0
  fi
  err "Plugin '$tool' não implementa tool_versions"
  return 1
}