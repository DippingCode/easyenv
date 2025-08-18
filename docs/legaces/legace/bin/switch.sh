#!/usr/bin/env bash
# easyenv: switch de versões por ferramenta (plugins only)

cmd_switch(){
  ensure_workspace_dirs

  local tool="${1:-}"
  shift || true

  case "$tool" in
    ""|-h|--help|help)
      cmd_switch_help
      return 0
      ;;
  esac

  if plugin_load "$tool"; then
    if declare -F tool_switch >/dev/null 2>&1; then
      plugin_call tool_switch "$@"
      return $?
    else
      err "Plugin '$tool' não implementa tool_switch."
      return 1
    fi
  fi

  err "Ferramenta não suportada ou plugin ausente: $tool"
  echo "Sugestão: crie src/plugins/$tool/plugin.sh com a função tool_switch"
  return 1
}

cmd_switch_help(){
  cat <<'EOF'
Uso: easyenv switch <tool> <versão|canal> [opções]

Este comando delega para o plugin da ferramenta:
  Cada plugin pode implementar: tool_switch <versão> [opções]

Exemplos:
  easyenv switch node lts
  easyenv switch flutter 3.13.9
  easyenv switch dotnet 8.0.406 --scope here
  easyenv switch rust stable
EOF
}