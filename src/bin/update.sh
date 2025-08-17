#!/usr/bin/env bash
# UPDATE: atualiza ferramentas (prioriza plugins; fallback: Homebrew)

cmd_update(){
  ensure_workspace_dirs
  prime_brew_shellenv

  local steps=0 autoy=0
  local mode=""      # all | section | tools
  local section=""
  local show_outdated=0
  local dryrun=0

  # alvos explícitos (tools) e argumentos opcionais na forma tool=valor
  local -a args_tools=()
  declare -A tool_args=()   # ex.: tool_args["node"]="lts"

  # --- parse flags/args ---
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -steps)     steps=1 ;;
      -y|--yes)   autoy=1 ;;
      -all)       mode="all" ;;
      -section)   mode="section"; shift; section="${1:-}"; [[ -z "$section" ]] && { err "Faltou o nome da seção após -section"; exit 1; } ;;
      --outdated) show_outdated=1 ;;
      --dry-run)  dryrun=1 ;;
      -h|--help)  cmd_update_help; return 0 ;;
      -*)
        warn "Opção desconhecida: $1"
        ;;
      *)
        mode="tools"
        # suporta sintaxe: tool=valor (ex.: node=lts, python=3.12.5)
        if [[ "$1" == *"="* ]]; then
          local k="${1%%=*}"; local v="${1#*=}"
          args_tools+=("$k")
          tool_args["$k"]="$v"
        else
          args_tools+=("$1")
        fi
        ;;
    esac
    shift || true
  done

  # --- somente listar desatualizados ---
  if (( show_outdated==1 )); then
    brew_update_quick || true
    echo
    brew_list_outdated
    return 0
  fi

  # default → -all
  [[ -z "$mode" ]] && mode="all"

  brew_update_quick || true

  # --- resolver alvos ---
  local targets=()
  case "$mode" in
    tools)
      if (( ${#args_tools[@]} == 0 )); then
        warn "Nenhuma ferramenta especificada para update."
        return 0
      fi
      mapfile -t targets < <(printf "%s\n" "${args_tools[@]}")
      ;;
    section)
      mapfile -t targets < <(list_tools_by_section "$section")
      if (( ${#targets[@]} == 0 )); then
        warn "Seção '$section' não encontrada ou sem ferramentas."
        return 0
      fi
      ;;
    all)
      mapfile -t targets < <(list_all_tools)
      ;;
  esac

  if (( ${#targets[@]} == 0 )); then
    warn "Nenhuma ferramenta alvo para atualizar."
    return 0
  fi

  echo
  _bld "Plano de atualização:"
  for t in "${targets[@]}"; do
    if [[ -n "${tool_args[$t]:-}" ]]; then
      printf ' - %s (arg: %s)\n' "$t" "${tool_args[$t]}"
    else
      printf ' - %s\n' "$t"
    fi
  done

  if (( dryrun==1 )); then
    info "(dry-run) Nenhuma alteração será feita."
    return 0
  fi

  if (( steps==1 && autoy==0 )); then
    if ! confirm "Deseja prosseguir e atualizar estas ferramentas?"; then
      info "Operação cancelada."
      return 1
    fi
  fi

  # --- aplicar updates ---
  local any_fail=0
  for t in "${targets[@]}"; do
    # confirmação por item quando -steps (sem --yes)
    if (( steps==1 && autoy==0 )); then
      if ! confirm "Atualizar '$t'?"; then
        info "Pulando $t."
        continue
      fi
    fi

    # tenta plugin primeiro
    if plugin_load "$t" && declare -F tool_update >/dev/null 2>&1; then
      local arg="${tool_args[$t]:-}"
      if [[ -n "$arg" ]]; then
        info "Atualizando '$t' via plugin (arg='$arg')…"
        if ! plugin_call tool_update "$arg"; then
          warn "Falha ao atualizar '$t' via plugin. Tentando fallback (Homebrew)…"
          if ! __update_via_brew "$t"; then
            err "Falha ao atualizar '$t'."
            any_fail=1
          else
            ok "'$t' atualizado via Homebrew (fallback)."
          fi
        else
          ok "'$t' atualizado via plugin."
        fi
      else
        info "Atualizando '$t' via plugin…"
        if ! plugin_call tool_update; then
          warn "Falha ao atualizar '$t' via plugin. Tentando fallback (Homebrew)…"
          if ! __update_via_brew "$t"; then
            err "Falha ao atualizar '$t'."
            any_fail=1
          else
            ok "'$t' atualizado via Homebrew (fallback)."
          fi
        else
          ok "'$t' atualizado via plugin."
        fi
      fi
      continue
    fi

    # sem plugin/tool_update → brew direto
    info "Plugin de '$t' ausente/sem tool_update. Tentando Homebrew…"
    if ! __update_via_brew "$t"; then
      warn "Homebrew não conseguiu atualizar '$t'."
      any_fail=1
    else
      ok "'$t' atualizado."
    fi
  done

  if (( any_fail==0 )); then
    ok "Update concluído."
  else
    warn "Update concluído com falhas. Veja mensagens acima."
    return 1
  fi
}

# helper interno: tenta formula, se falhar tenta cask
__update_via_brew(){
  local name="$1"
  if brew upgrade "$name"; then
    return 0
  fi
  # alguns itens são casks
  if brew upgrade --cask "$name"; then
    return 0
  fi
  return 1
}

cmd_update_help(){
  cat <<'EOF'
Uso:
  easyenv update [-all | -section <nome> | <tool> [<tool> ...] | tool=valor ...]
                 [--outdated] [--dry-run] [-steps] [-y]

Descrição:
  Atualiza ferramentas priorizando plugins (tool_update). Se não existir plugin
  ou tool_update falhar, cai no fallback do Homebrew (brew upgrade / --cask).

Opções:
  -all                  Atualiza todas as ferramentas do catálogo (tools.yml)
  -section <nome>       Atualiza todas as tools de uma seção
  <tool> [...]          Atualiza apenas as ferramentas listadas
  tool=valor            Passa argumento específico para o plugin da tool
                        Ex.: node=lts, python=3.12.5, go=1.22.6, flutter=3.13.9
  --outdated            Lista fórmulas/casks desatualizados (Homebrew) e sai
  --dry-run             Mostra o plano e não executa atualizações
  -steps                Modo interativo (confirmação por item)
  -y, --yes             Auto-confirmar no modo -steps

Exemplos:
  easyenv update --outdated
  easyenv update -all --dry-run
  easyenv update -section "Web" -steps
  easyenv update node=lts python=3.12.5
  easyenv update flutter=3.13.9
EOF
}