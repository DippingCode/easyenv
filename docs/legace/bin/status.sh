cmd_status(){
  require_cmd "yq" "Por favor instale yq (brew install yq)."

  local detailed=0 as_json=0 discover=0
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --detailed) detailed=1 ;;
      --json)     as_json=1  ;;
      --discover) discover=1 ;;
      -h|--help)  cmd_status_help; return 0 ;;
      *)          warn "Opção desconhecida: $1" ;;
    esac
    shift
  done

  # opcional: forçar uma varredura agora e gravar no snapshot
  if (( discover==1 )); then
    write_snapshot_from_discovery
  fi

  if (( as_json==1 )); then
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

  echo
  echo "EasyEnv status"
  echo
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
    echo "Ferramentas (origem / versão / enabled):"

    # Se temos descoberta no snapshot, usa ela; senão, descobre “on the fly”
    if [[ -f "$SNAP_FILE" ]] && yq -e '.discovery.tools' "$SNAP_FILE" >/dev/null 2>&1; then
      # usa a lista do snapshot pra refletir a realidade
      while IFS= read -r row; do
        # row: name|origin|version|enabled
        local name origin ver enabled
        name="$(cut -d'|' -f1 <<<"$row")"
        origin="$(cut -d'|' -f2 <<<"$row")"
        ver="$(cut -d'|' -f3 <<<"$row")"
        enabled="$(cut -d'|' -f4 <<<"$row")"
        local mark=""
        [[ "$enabled" == "true" ]] && mark="*"
        printf "  - %-16s %-32s | %-28s | %s\n" "${name}${mark}" "$origin" "$ver" "$enabled"
      done < <(yq -r '.discovery.tools[] | "\(.name)|\(.origin)|\(.version)|\(.enabled)"' "$SNAP_FILE")
    else
      # fallback: lista unida (catálogo + markers) e descobre agora (mais lento)
      while IFS= read -r t; do
        [[ -z "$t" || "$t" == "null" ]] && continue
        local j; j="$(discover_tool_state "$t")"
        local origin ver enabled
        origin="$(jq -r '.origin' <<<"$j")"
        ver="$(jq -r '.version' <<<"$j")"
        enabled="$(jq -r '.enabled' <<<"$j")"
        local mark=""; [[ "$enabled" == "true" ]] && mark="*"
        printf "  - %-16s %-32s | %-28s | %s\n" "${t}${mark}" "$origin" "$ver" "$enabled"
      done < <(discover_all_tools_json)
    fi

    echo
    echo "Backups recentes em $BACKUP_DIR:"
    list_backups | head -n 3 | sed 's/^/  - /' || true
  fi
}

cmd_status_help(){
  cat <<EOF

Uso: easyenv status [--detailed] [--json] [--discover]

Opções:
  --detailed   Mostra origem/versão por ferramenta e últimos backups
  --json       Saída em JSON minimalista
  --discover   Varre o ambiente agora e grava em .zshrc-tools.yml (.discovery)

Exemplos:
  easyenv status
  easyenv status --detailed
  easyenv status --detailed --discover   # força sincronização antes
EOF
}