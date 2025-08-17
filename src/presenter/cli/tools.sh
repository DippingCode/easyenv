#!/usr/bin/env bash
# presenter/cli/tools.sh — comandos para gerenciar o catálogo de ferramentas

# NOTA: este comando é carregado pelo router e executa a função cmd_tools

cmd_tools() {
  local sub="${1:-install}"
  shift || true

  case "$sub" in
    ""|-h|--help|help)
      cmd_tools_help
      ;;
    install)
      _tools_install "$@"
      ;;
    list)
      _tools_list "$@"
      ;;
    update)
      _tools_update "$@"
      ;;
    uninstall|remove)
      _tools_uninstall "$@"
      ;;
    *)
      err "Subcomando desconhecido: $sub"
      echo
      cmd_tools_help
      return 1
      ;;
  esac
}

cmd_tools_help() {
  cat <<'EOF'
Uso:
  easyenv tools <subcomando>

Subcomandos:
  install                    Instala os pré-requisitos e utilitários definidos em config/tools.yml
  list [--detailed|--json]   Lista o catálogo de ferramentas
  update                     Atualiza todas as ferramentas do catálogo
  uninstall                  Desinstala todas as ferramentas do catálogo (confirmação interativa)

Exemplos:
  easyenv tools install
  easyenv tools list
  easyenv tools list --detailed
  easyenv tools update
  easyenv tools uninstall
EOF
}

# --------------------------
# tools install
# --------------------------
_tools_install() {
  local svc="$EASYENV_HOME/src/data/services/tools.sh"
  if [[ ! -f "$svc" ]]; then
    err "Serviço não encontrado: $svc"
    return 1
  fi

  info "Iniciando instalação das ferramentas (config/tools.yml)…"
  /usr/bin/env bash "$svc" bootstrap
  local ec=$?

  if (( ec == 0 )); then
    ok "Ferramentas instaladas com sucesso."
    echo
    echo "Dica: recarregue seu shell para aplicar as mudanças:"
    echo "  source ~/.zprofile && source ~/.zshrc"
  else
    err "Falha ao instalar ferramentas. Veja os logs para detalhes."
  fi
  return $ec
}

# --------------------------
# tools list
# --------------------------
cmd_tools_help_list() {
  cat <<'EOF'
Uso:
  easyenv tools list [--detailed] [--json]

Opções:
  --detailed   Tenta detectar instalação/versão (usa check_version_cmd/brew/command -v)
  --json       Imprime o array .tools em JSON (dump do config/tools.yml)

Exemplos:
  easyenv tools list
  easyenv tools list --detailed
  easyenv tools list --json
EOF
}

_tools_list() {
  local cfg="$EASYENV_HOME/config/tools.yml"
  require_cmd "yq" "Instale o yq: brew install yq."

  if [[ ! -f "$cfg" ]]; then
    err "Catálogo não encontrado: $cfg"
    return 1
  fi

  local detailed=0 json=0
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --detailed) detailed=1 ;;
      --json)     json=1 ;;
      -h|--help)  cmd_tools_help_list; return 0 ;;
      *)
        warn "Opção desconhecida: $1"
        ;;
    esac
    shift || true
  done

  if (( json==1 )); then
    yq -o=json '.tools' "$cfg"
    return 0
  fi

  # Cabeçalho
  echo "Catálogo de ferramentas: $cfg"
  printf "%-14s  %-20s  %-10s  %-10s  %s\n" "Seção" "Nome" "Tipo" "Status" "Versão/Origem"
  printf "%0.s-" {1..88}; echo

  # Itera ferramentas
  while IFS=$'\t' read -r section name type formula cask checkcmd; do
    [[ -z "$name" || "$name" == "null" ]] && continue

    local status="—" ver="—"

    if (( detailed==1 )); then
      if [[ -n "${checkcmd:-}" && "$checkcmd" != "null" ]]; then
        if out="$(bash -lc "$checkcmd" 2>/dev/null | head -n1)"; then
          if [[ -n "$out" ]]; then status="OK"; ver="$out"; else status="faltando"; fi
        else
          status="faltando"
        fi
      elif [[ -n "${formula:-}" && "$formula" != "null" ]]; then
        if brew list "$formula" >/dev/null 2>&1; then status="OK"; ver="brew:$formula"; else status="faltando"; fi
      elif [[ -n "${cask:-}" && "$cask" != "null" ]]; then
        if brew list --cask "$cask" >/dev/null 2>&1; then status="OK"; ver="cask:$cask"; else status="faltando"; fi
      else
        if command -v "$name" >/dev/null 2>&1; then status="OK"; ver="$(command -v "$name")"; else status="faltando"; fi
      fi
    fi

    printf "%-14s  %-20s  %-10s  %-10s  %s\n" \
      "${section:--}" "$name" "${type:--}" "$status" "$ver"
  done < <(yq -r '.tools[] | [.section // "-", .name, .type // "-", (.brew.formula // ""), (.brew.cask // ""), (.check_version_cmd // "")] | @tsv' "$cfg")
}

# --------------------------
# tools update
# --------------------------
_tools_update() {
  local svc="$EASYENV_HOME/src/data/services/tools.sh"
  if [[ ! -f "$svc" ]]; then
    err "Serviço não encontrado: $svc"
    return 1
  fi

  info "Atualizando todas as ferramentas do catálogo…"
  /usr/bin/env bash "$svc" update-all
  local ec=$?
  (( ec==0 )) && ok "Atualização concluída."
  return $ec
}

# --------------------------
# tools uninstall
# --------------------------
_tools_uninstall() {
  local svc="$EASYENV_HOME/src/data/services/tools.sh"
  if [[ ! -f "$svc" ]]; then
    err "Serviço não encontrado: $svc"
    return 1
  fi

  echo
  warn "Isto irá desinstalar TODAS as ferramentas definidas no catálogo."
  if ! confirm "Deseja continuar?"; then
    info "Operação cancelada."
    return 1
  fi

  /usr/bin/env bash "$svc" uninstall-all
  local ec=$?
  (( ec==0 )) && ok "Desinstalação concluída."
  return $ec
}