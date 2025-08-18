#!/usr/bin/env bash
# doctor.sh — diagnóstico do ambiente por ferramenta/seção

# Requisitos do core:
#  - utils.sh: ok, warn, err, info, _bld
#  - tools.sh: list_sections, list_all_tools, list_tools_by_section, _tool_field, tool_check_report
#  - plugins: call_plugin_func_if_exists "<tool>" doctor_tool

# -------- Help --------
cmd_doctor_help(){
  cat <<'EOF'
Uso:
  easyenv doctor                 # Diagnosticar todas as ferramentas do catálogo
  easyenv doctor <tool>          # Diagnosticar apenas uma ferramenta
  easyenv doctor -section "<S>"  # Diagnosticar uma seção específica

Comportamento:
  - Prioridade: plugin (doctor_tool) → checks do catálogo (tools.yml: .tools[].check[]) → fallback (which/version).
  - Mostra status (OK/FAIL) e sugestões básicas.

Exemplos:
  easyenv doctor
  easyenv doctor git
  easyenv doctor -section "CLI Tools"
EOF
}

# -------- Execução de "checks" definidos no catálogo --------
# Usa o mesmo campo .tools[].check (lista de comandos) já suportado no status --detailed.
# Aqui mostramos (1) comando que passou e (2) comandos que falharam, quando possível.
run_catalog_checks_for(){
  local tool="$1"
  local count
  count="$(yq -r --arg n "$tool" '.tools[] | select(.name==$n) | .check | length // 0' "$CFG_FILE" 2>/dev/null || echo 0)"
  (( count==0 )) && return 2  # sem checks definidos

  local any_ok=0
  local first_ok_line=""
  local failed_list=()

  while IFS= read -r cmd; do
    [[ -z "$cmd" || "$cmd" == "null" ]] && continue
    # roda o check capturando saída e RC
    local out rc
    out="$(bash -lc "$cmd" 2>&1)"; rc=$?
    if (( rc==0 )); then
      any_ok=1
      # primeira linha da saída para exibir
      first_ok_line="$(printf "%s\n" "$out" | head -n1)"
      break
    else
      failed_list+=("$cmd")
    fi
  done < <(yq -r --arg n "$tool" '.tools[] | select(.name==$n) | .check[]' "$CFG_FILE")

  if (( any_ok==1 )); then
    ok "Checks do catálogo: OK${first_ok_line:+ — $first_ok_line}"
    return 0
  else
    warn "Checks do catálogo: FAIL"
    if ((${#failed_list[@]})); then
      printf "  • Falharam:\n"
      for c in "${failed_list[@]}"; do
        printf "    - %s\n" "$c"
      done
    fi
    return 1
  fi
}

# -------- Fallback simples (sem plugin/sem checks) --------
fallback_probe_for(){
  local tool="$1"
  local where ver=""
  where="$(command -v "$tool" 2>/dev/null || true)"
  if [[ -z "$where" ]]; then
    err "Não encontrado no PATH: $tool"
    return 1
  fi
  # tenta flags comuns de versão
  for flag in "--version" "-v" "version"; do
    if ver="$(bash -lc "$tool $flag" 2>/dev/null | head -n1)"; then
      break
    fi
  done
  ok "Encontrado: $where${ver:+ — $ver}"
  return 0
}

# -------- Diagnóstico de UMA ferramenta (orquestração) --------
doctor_one_tool(){
  local tool="$1"
  [[ -z "$tool" ]] && { err "Uso: doctor_one_tool <tool>"; return 1; }

  _bld "▶ $tool"
  local passed=0

  # 1) plugin (se existir): doctor_tool
  if call_plugin_func_if_exists "$tool" doctor_tool; then
    # plugin decide sua própria saída e RC — aqui consideramos sucesso se RC==0
    passed=1
  else
    # 2) checks do catálogo (tools.yml: .tools[].check)
    if run_catalog_checks_for "$tool"; then
      passed=1
    else
      # 3) fallback básico (which/version)
      if fallback_probe_for "$tool"; then
        passed=1
      fi
    fi
  fi

  if (( passed==1 )); then
    echo
    return 0
  else
    # dica de correção mínima a partir do catálogo (se houver formula/cask/npm_global)
    local manager formula cask npm_global
    manager="$(_tool_field "$tool" ".manager")"
    formula="$(_tool_field "$tool" ".formula")"
    cask="$(_tool_field "$tool" ".cask")"
    npm_global="$(_tool_field "$tool" ".npm_global")"
    [[ "$manager" == "null" || -z "$manager" ]] && manager=""
    [[ "$formula" == "null" ]] && formula=""
    [[ "$cask" == "null" ]] && cask=""
    [[ "$npm_global" == "null" ]] && npm_global=""

    if [[ "$manager" == "npm_global" || -n "$npm_global" ]]; then
      warn "Sugestão: npm i -g ${npm_global:-$tool}"
    elif [[ -n "$cask" ]]; then
      warn "Sugestão: brew install --cask $cask"
    else
      warn "Sugestão: brew install ${formula:-$tool}"
    fi
    echo
    return 1
  fi
}

# -------- Comando principal --------
cmd_doctor(){
  require_cmd "yq" "Instale yq com: brew install yq."
  ensure_workspace_dirs
  prime_brew_shellenv

  local section=""
  local target_tool=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help) cmd_doctor_help; return 0 ;;
      -section)  shift; section="${1:-}";;
      *)
        if [[ -z "$target_tool" ]]; then
          target_tool="$1"
        else
          warn "Argumento ignorado: $1"
        fi
        ;;
    esac
    shift || true
  done

  local tools=()
  if [[ -n "$target_tool" ]]; then
    tools=("$target_tool")
  elif [[ -n "$section" ]]; then
    mapfile -t tools < <(list_tools_by_section "$section")
    if (( ${#tools[@]} == 0 )); then
      err "Seção '$section' não encontrada ou sem ferramentas no catálogo."
      return 1
    fi
  else
    mapfile -t tools < <(list_all_tools)
  fi

  if (( ${#tools[@]} == 0 )); then
    err "Nenhuma ferramenta para diagnosticar."
    return 1
  fi

  echo
  _bld "EasyEnv Doctor"
  [[ -n "$section" ]]    && echo "Seção: $section"
  [[ -n "$target_tool" ]]&& echo "Ferramenta: $target_tool"
  echo

  local okc=0 failc=0
  local t
  for t in "${tools[@]}"; do
    if doctor_one_tool "$t"; then
      ((okc++))
    else
      ((failc++))
    fi
  done

  _bld "Resumo"
  echo "  ✅ OK:   $okc"
  echo "  ❌ FAIL: $failc"
  if (( failc>0 )); then
    return 2
  fi
  return 0
}