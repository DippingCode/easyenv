# cmd_status: mostra estado do workspace
cmd_status(){
  require_cmd "yq" "Por favor instale yq (brew install yq)."

  local detailed=0 as_json=0
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --detailed) detailed=1 ;;
      --json)     as_json=1  ;;
      -h|--help)  cmd_status_help; return 0 ;;
      *)          warn "Opção desconhecida: $1" ;;
    esac
    shift
  done

  if (( as_json==1 )); then
    # saída JSON minimalista (útil p/ automações)
    jq -n \
      --arg home "$EASYENV_HOME" \
      --arg cfg "$CFG_FILE" \
      --arg snap "$SNAP_FILE" \
      --arg zprofile "$(prelude_status_zprofile)" \
      --arg zshrc   "$(prelude_status_zshrc)" \
      '{
        home: $home,
        config: $cfg,
        snapshot: $snap,
        preludes: { zprofile: $zprofile, zshrc: $zshrc }
      }'
    return 0
  fi

  echo "EasyEnv status"
  echo "  HOME: $EASYENV_HOME"
  echo "  CFG : $CFG_FILE"
  echo "  SNAP: $SNAP_FILE"
  echo

  if [[ -f "$SNAP_FILE" ]]; then
    echo "Workspace:"
    yq -r '.workspace // {}' "$SNAP_FILE" || true
    echo
    echo "Preferences:"
    yq -r '.preferences // {}' "$SNAP_FILE" || true
  else
    warn "Snapshot não encontrado em: $SNAP_FILE"
    echo "Crie um a partir de $CFG_FILE ou rode: easyenv init"
  fi

  echo
  if [[ -f "$CFG_FILE" ]]; then
    echo "Sections (tools.yml):"
    yq -r '.tools[].section' "$CFG_FILE" | sort -u || true
    local sec_count tool_count
    sec_count="$(yq -r '.tools[].section' "$CFG_FILE" | sort -u | wc -l | tr -d ' ')"
    tool_count="$(yq -r '.tools | length' "$CFG_FILE" 2>/dev/null || echo 0)"
    echo
    echo "Resumo do catálogo: ${sec_count:-0} seção(ões), ${tool_count:-0} ferramenta(s)."
  else
    warn "Catálogo não encontrado em: $CFG_FILE"
  fi

  echo
  report_preludes

    if (( detailed==1 )); then
    echo
    echo "Ferramentas (origem / versão / check):"
    while IFS= read -r t; do
      [[ -z "$t" || "$t" == "null" ]] && continue
      local origin ver chk
      origin="$(tool_origin "$t")"
      ver="$(tool_version "$t")"
      chk="$(tool_check_report "$t")"
      printf "  - %-16s %-32s | %-28s | %s\n" "$t" "$origin" "${ver:-"-"}" "${chk:-"-"}"
    done < <(yq -r '.tools[].name' "$CFG_FILE")

    echo
    echo "Backups recentes em $BACKUP_DIR:"
    list_backups | head -n 3 | sed 's/^/  - /' || true
  fi
}

cmd_status_help(){
  cat <<EOF
Uso: easyenv status [--detailed] [--json]

Opções:
  --detailed   Mostra origem/versão por ferramenta e últimos backups
  --json       Saída em JSON minimalista (para automações)

Exemplos:
  easyenv status
  easyenv status --detailed
  easyenv status --json
EOF
}