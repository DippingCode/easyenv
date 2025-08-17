#!/usr/bin/env bash
# ============================================
# EasyEnv - doctor (checagens de ambiente)
# Comando: easyenv doctor [<tool> ...]
# Plugins: cada plugin deve expor a função `doctor_tool`
# ============================================

set -euo pipefail

# Requer:
# - utils.sh (ok/warn/err/_bld/info)
# - tools.sh (list_all_tools)
# - variáveis: EASYENV_HOME, CORE_DIR

# Caminho do plugin: src/plugins/<tool>/plugin.sh
_doctor_plugin_path(){
  local tool="$1"
  echo "$EASYENV_HOME/src/plugins/$tool/plugin.sh"
}

# Executa doctor de 1 ferramenta num subshell para evitar colisão de função
_doctor_run_for_tool(){
  local tool="$1"
  local plugin; plugin="$(_doctor_plugin_path "$tool")"

  if [[ ! -f "$plugin" ]]; then
    warn "Plugin não encontrado para '$tool': $plugin"
    return 2
  fi

  # roda em subshell com o core disponível
  (
    set -euo pipefail
    # expõe variáveis necessárias ao subshell
    export EASYENV_HOME CORE_DIR
    # carrega utilitários para o plugin usar ok/warn/err
    [[ -f "$CORE_DIR/utils.sh" ]] && source "$CORE_DIR/utils.sh"
    # carrega helpers comuns, se plugin precisar
    [[ -f "$CORE_DIR/workspace.sh" ]] && source "$CORE_DIR/workspace.sh"
    [[ -f "$CORE_DIR/tools.sh"     ]] && source "$CORE_DIR/tools.sh"

    # carrega o plugin da ferramenta
    source "$plugin"

    # verifica a função esperada
    if ! type doctor_tool >/dev/null 2>&1; then
      echo "⚠️  Plugin '$tool' não implementa 'doctor_tool'." >&2
      exit 3
    fi

    # executa o doctor do plugin
    doctor_tool
  )
}

cmd_doctor(){
  ensure_workspace_dirs
  prime_brew_shellenv

  local targets=()

  if [[ $# -gt 0 ]]; then
    # usa os nomes recebidos
    mapfile -t targets < <(printf "%s\n" "$@")
  else
    # sem args → todas as ferramentas do catálogo
    mapfile -t targets < <(list_all_tools)
  fi

  if (( ${#targets[@]} == 0 )); then
    warn "Nenhuma ferramenta encontrada para doctor."
    return 0
  fi

  echo
  _bld "Executando doctor…"

  local ok_count=0 warn_count=0 err_count=0
  for t in "${targets[@]}"; do
    echo
    _bld "▶ $t"
    if _doctor_run_for_tool "$t"; then
      ok_count=$((ok_count+1))
    else
      case $? in
        2|3) warn_count=$((warn_count+1)) ;;  # plugin ausente ou sem doctor_tool
        *)   err_count=$((err_count+1))  ;;
      esac
    fi
  done

  echo
  _bld "Resumo:"
  echo "  ✅ OK:    $ok_count"
  echo "  ⚠️  Avisos: $warn_count"
  echo "  ❌ Erros: $err_count"

  if (( err_count > 0 )); then
    return 1
  fi
  return 0
}

cmd_doctor_help(){
  cat <<'EOF'
Uso:
  easyenv doctor                # roda checagens para todas as ferramentas do catálogo
  easyenv doctor <tool> [...]   # roda checagens apenas para as ferramentas listadas

Requisitos dos plugins:
  - Cada plugin deve definir a função: doctor_tool
  - Caminho esperado: src/plugins/<tool>/plugin.sh

Exemplos:
  easyenv doctor
  easyenv doctor flutter
  easyenv doctor android java node
EOF
}