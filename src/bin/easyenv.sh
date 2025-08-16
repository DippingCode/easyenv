#!/usr/bin/env bash
# EasyEnv - CLI
# Núcleo: roteador, help, status, init -steps e logging

EASYENV_VERSION="0.1.0"

set -euo pipefail

# Caminhos do projeto
EASYENV_HOME="${EASYENV_HOME:-$HOME/easyenv}"
CORE_DIR="$EASYENV_HOME/src/core"
CFG_DIR="$EASYENV_HOME/src/config"
LOG_DIR="$EASYENV_HOME/src/logs"

# Fonte dos módulos core
source "$CORE_DIR/utils.sh"
source "$CORE_DIR/workspace.sh"
source "$CORE_DIR/tools.sh"    # << novo: instaladores/operadores de ferramentas

# --------------- Subcomandos ---------------

cmd_version(){
  echo "easyenv v$EASYENV_VERSION"
}

cmd_help(){
  cat <<EOF
EasyEnv v$EASYENV_VERSION — gerencie seu ambiente de desenvolvimento.

Uso:
  easyenv <comando> [opções]

Comandos:
  help             Mostra esta ajuda
  status           Mostra o status atual do workspace (YAMLs carregados, seções)
                   Opções:
                     --detailed    Mostra origem/versão por ferramenta e backups
                     --json        Imprime status em JSON
  init             Instala ferramentas por seções (dirigido por YAML)
                   Opções:
                     -steps        Modo interativo: pergunta por seção
                     -no-steps     Força modo não interativo (ignora snapshot)
                     -y, --yes     Auto-confirmar "sim" nas perguntas do -steps
                     -reload       Reinicia o shell ao final (exec zsh -l)
  clean            Remove ferramentas e/ou caches
                   Uso:
                     easyenv clean [-all|-soft] [-steps] [-section <nome>] [<tool> ...]
                   Exemplos:
                     easyenv clean -all
                     easyenv clean -soft
                     easyenv clean -steps -section "CLI Tools"
                     easyenv clean git fzf
  backup          Gerencia backups do EasyEnv
                   Uso:
                     easyenv backup                      # cria backup
                     easyenv backup -list                # lista backups
                     easyenv backup -delete [arquivo]    # apaga backup (interativo se omitir)
                     easyenv backup -restore             # restaura (interativo)
                     easyenv backup restore -latest      # restaura o mais recente
                     easyenv backup restore <arquivo>    # restaura por nome/caminho
                     easyenv backup -purge <N>           # mantém apenas os N mais recentes
  update          Atualiza ferramentas via Homebrew
                   Uso:
                     easyenv update [-all | -section <nome> | <tool> ...] [-steps] [-y] [--outdated]
                   Opções:
                     --outdated   Mostra itens desatualizados e sai
                   Exemplos:
                     easyenv update --outdated
                     easyenv update -all -steps
                     easyenv update -section "CLI Tools" -y

  backup          Cria um backup zip do ambiente (~/.zshrc, ~/.zprofile, YAMLs)
                   Uso:
                     easyenv backup
                   Exemplo:
                     easyenv backup
  add              (em breve) Adicionar ferramenta por nome
  theme            (em breve) Gerenciar temas do Oh My Zsh

Exemplos:
  easyenv status
  easyenv init -steps -y
  easyenv init -no-steps -reload
  easyenv clean -all
EOF
}

cmd_status(){
  require_cmd "yq" "Por favor instale yq (brew install yq)."

  local detailed=0 as_json=0
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --detailed) detailed=1 ;;
      --json)     as_json=1 ;;
      *) warn "Opção desconhecida: $1" ;;
    esac
    shift
  done

  if (( as_json==1 )); then
    # ---- Saída JSON minimalista e estável ----
    # Prelúdios
    local prel_zprofile="false" prel_zshrc="false"
    has_zprofile_brew_prelude && prel_zprofile="true"
    has_zshrc_dedup_prelude  && prel_zshrc="true"

    # Seções
    local sections_json="[]"
    if [[ -f "$CFG_FILE" ]]; then
      sections_json="$(yq -r '[.tools[].section] | unique' "$CFG_FILE" 2>/dev/null || echo '[]')"
    fi

    # Ferramentas (nome, origem, versão)
    local tools_json="[]"
    if [[ -f "$CFG_FILE" ]]; then
      # Construímos manualmente um array JSON
      local names; mapfile -t names < <(yq -r '.tools[].name' "$CFG_FILE" 2>/dev/null)
      local items=() n o v
      for n in "${names[@]}"; do
        [[ -z "$n" || "$n" == "null" ]] && continue
        o="$(tool_origin "$n")"
        v="$(tool_version "$n")"
        # escape de aspas simples e barras
        v="${v//\\/\\\\}"; v="${v//\"/\\\"}"
        items+=("{\"name\":\"$n\",\"origin\":\"$o\",\"version\":\"$v\"}")
      done
      tools_json="[$(IFS=,; echo "${items[*]}")]"
    fi

    # Backups (máx. 10)
    local backs_json="[]"
    if compgen -G "$BACKUP_DIR/.easyenv-backup-*.zip" >/dev/null; then
      local lines; mapfile -t lines < <(list_backups_struct | head -n 10)
      local items=()
      local f m s
      for ln in "${lines[@]}"; do
        f="${ln%%|*}"; ln="${ln#*|}"
        m="${ln%%|*}"; s="${ln#*|}"
        items+=("{\"file\":\"$f\",\"mtime\":\"$m\",\"size_bytes\":$s}")
      done
      backs_json="[$(IFS=,; echo "${items[*]}")]"
    fi

    cat <<JSON
{
  "easyenv_version": "${EASYENV_VERSION}",
  "home": "${EASYENV_HOME}",
  "cfg_file": "${CFG_FILE}",
  "snapshot_file": "${SNAP_FILE}",
  "preludes": {
    "zprofile_homebrew": ${prel_zprofile},
    "zshrc_path_dedup": ${prel_zshrc}
  },
  "sections": ${sections_json},
  "tools": ${tools_json},
  "backups": ${backs_json}
}
JSON
    return 0
  fi

  # ---- Saída humana (como você já tinha) ----
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
    echo "Ferramentas (origem e versão):"
    while IFS= read -r t; do
      [[ -z "$t" || "$t" == "null" ]] && continue
      local origin ver
      origin="$(tool_origin "$t")"
      ver="$(tool_version "$t")"
      printf "  - %-16s %-30s  %s\n" "$t" "$origin" "${ver:-""}"
    done < <(yq -r '.tools[].name' "$CFG_FILE")

    echo
    echo "Backups recentes em $BACKUP_DIR:"
    shopt -s nullglob
    local backs=("$BACKUP_DIR"/.easyenv-backup-*.zip)
    if (( ${#backs[@]} == 0 )); then
      echo "  (nenhum backup encontrado)"
    else
      IFS=$'\n' backs=($(ls -1t "$BACKUP_DIR"/.easyenv-backup-*.zip 2>/dev/null))
      unset IFS
      local shown=0
      for f in "${backs[@]}"; do
        (( shown++ >= 3 )) && break
        local mtime size size_h
        mtime="$(stat -f '%Sm' -t '%Y-%m-%d %H:%M' "$f" 2>/dev/null || echo '')"
        size="$(stat -f '%z' "$f" 2>/dev/null || echo '0')"
        size_h=$(numfmt --to=iec --suffix=B "$size" 2>/dev/null || echo "${size}B")
        printf "  - %s  (%s, %s)\n" "$f" "$mtime" "$size_h"
      done
    fi
    shopt -u nullglob
  fi
}

cmd_init(){
  require_cmd "yq" "Instale com: brew install yq."
  ensure_workspace_dirs
  prime_brew_shellenv
  ensure_zprofile_prelude   # Homebrew em ~/.zprofile
  ensure_zshrc_prelude      # deduplicação PATH em ~/.zshrc

  local steps=0
  local reload=0

  # se no snapshot preferências dizem para usar steps por default, ativa
  if [[ -f "$SNAP_FILE" ]]; then
    local def_steps
    def_steps="$(yq -r '.preferences.init.steps_mode_default // false' "$SNAP_FILE" || echo false)"
    [[ "$def_steps" == "true" ]] && steps=1
  fi

  # parametros CLI
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -steps) steps=1 ;;
      -reload) reload=1 ;;
      *) warn "Opção desconhecida: $1" ;;
    esac
    shift
  done

  local skip="$(yq -r '(.preferences.init.skip_sections // [])[]' "$SNAP_FILE" 2>/dev/null | tr '\n' ' ')"
  brew_update_quick || true

  echo
  _bld "Instalação por seções"
  if (( steps==1 )); then
    echo "Modo interativo (-steps) habilitado."
  fi
  echo

  local sections; mapfile -t sections < <(list_sections)
  if (( ${#sections[@]} == 0 )); then
    err "Nenhuma seção encontrada em $CFG_FILE (.tools[].section)."
    exit 1
  fi

  for sec in "${sections[@]}"; do
    if [[ " $skip " == *" $sec "* ]]; then
      info "Pulando seção '$sec' (skip_sections do snapshot)."
      continue
    fi

    if (( steps==1 )); then
      if ! confirm "Deseja instalar a seção '$sec'? "; then
        info "Seção '$sec' ignorada."
        continue
      fi
    fi

    do_section_install "$sec"
  done

  if (( reload==1 )); then
    ok "Init concluído. Recarregando ~/.zshrc ..."
    exec zsh -l
  else
    ok "Init concluído. Rode: source ~/.zshrc"
  fi
}

cmd_clean(){
  ensure_workspace_dirs
  prime_brew_shellenv

  local mode="all"   # all | soft
  local steps=0
  local section=""
  local args_tools=()

  # parse flags
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -all)   mode="all" ;;
      -soft)  mode="soft" ;;
      -steps) steps=1 ;;
      -section)
        shift
        section="${1:-}"
        [[ -z "$section" ]] && { err "Faltou o nome da seção após -section"; exit 1; }
        ;;
      -*)
        warn "Opção desconhecida: $1"
        ;;
      *) # nomes de ferramentas
        args_tools+=("$1")
        ;;
    esac
    shift || true
  done

  # ---------- SOFT: limpa logs/cache/markers e restaura PRELÚDIOS ----------
  if [[ "$mode" == "soft" ]]; then
    info "Limpeza (soft): logs, cache do Homebrew, marcadores do EasyEnv no .zshrc."
    zshrc_backup
    zshrc_remove_easyenv_markers
    rm -rf "$LOG_DIR"/* || true
    brew_cleanup_safe
    cleanup_zsh_aux_files
    ensure_zprofile_prelude
    ensure_zshrc_prelude

    ok "Limpeza soft concluída."
    return 0
  fi

  # ---------- ALL: desinstala + limpa + restaura PRELÚDIOS ----------
  local targets=()
  if (( ${#args_tools[@]} )); then
    mapfile -t targets < <(printf "%s\n" "${args_tools[@]}")
  elif [[ -n "$section" ]]; then
    mapfile -t targets < <(list_tools_by_section "$section")
    if (( ${#targets[@]} == 0 )); then
      warn "Seção '$section' não encontrada ou sem ferramentas."
      return 0
    fi
  else
    mapfile -t targets < <(list_all_tools)
  fi

  if (( ${#targets[@]} == 0 )); then
    warn "Nenhuma ferramenta alvo para remover."
    return 0
  fi

  echo
  _bld "Plano de remoção:"
  printf ' - %s\n' "${targets[@]}"

  if (( steps==1 )); then
    if ! confirm "Deseja prosseguir com a remoção destas ferramentas?"; then
      info "Operação cancelada."
      return 1
    fi
  fi

  # remove ferramentas
  for t in "${targets[@]}"; do
    uninstall_tool "$t" || warn "Falha ao desinstalar $t (continuando)."
  done

  # limpeza pós-remoção
  zshrc_backup
  zshrc_remove_easyenv_markers
  rm -rf "$LOG_DIR"/* || true
  brew_cleanup_safe
  cleanup_zsh_aux_files
  ensure_zprofile_prelude
  ensure_zshrc_prelude

  ok "Clean concluído."
}

cmd_restore(){
  require_cmd "yq" "Instale com: brew install yq."
  ensure_workspace_dirs
  prime_brew_shellenv

  local steps=0 reload=0 autoy=0
  local mode=""      # all | section | backup | latest | tools
  local section=""
  local args_tools=()

  # --------- parse flags ----------
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -steps)   steps=1 ;;
      -y|--yes) autoy=1 ;;
      -reload)  reload=1 ;;
      -all)     mode="all" ;;
      -section)
        mode="section"
        shift
        section="${1:-}"
        [[ -z "$section" ]] && { err "Faltou o nome da seção após -section"; exit 1; }
        ;;
      -backup)  mode="backup" ;;
      --latest) mode="latest" ;;
      -*)
        warn "Opção desconhecida: $1"
        ;;
      *)
        mode="tools"
        args_tools+=("$1")
        ;;
    esac
    shift || true
  done

  # Prelúdios sempre garantidos
  ensure_zprofile_prelude
  ensure_zshrc_prelude

  # Se nada especificado, assume -all
  [[ -z "$mode" ]] && mode="all"

  case "$mode" in
    latest)
      # Restaura o backup mais recente automaticamente
      local lb
      lb="$(latest_backup)"
      if [[ -z "$lb" ]]; then
        warn "Nenhum backup encontrado em $BACKUP_DIR."
        return 1
      fi
      info "Restaurando backup mais recente:"
      echo "  $(basename "$lb")"
      extract_backup_zip "$lb" || { err "Falha ao restaurar $lb"; return 1; }
      ;;

    backup)
      # Seleção interativa (fzf se disponível, fallback numérico)
      local chosen
      chosen="$(choose_backup_interactive)"
      if [[ -z "$chosen" ]]; then
        warn "Nenhum backup selecionado/encontrado."
        if (( steps==1 )); then
          if confirm "Deseja restaurar do zero (tools.yml)?"; then
            mode="all"
          else
            info "Operação cancelada."
            return 1
          fi
        else
          mode="all"
        fi
      fi
      if [[ "$mode" == "backup" ]]; then
        extract_backup_zip "$chosen" || { err "Falha ao restaurar $chosen"; return 1; }
        ok "Backup restaurado."
      fi
      ;;

    tools)
      if (( ${#args_tools[@]} == 0 )); then
        warn "Nenhuma ferramenta especificada para restore."
        return 0
      fi

      echo
      _bld "Plano de restauração (tools):"
      printf ' - %s\n' "${args_tools[@]}"

      if (( steps==1 && autoy==0 )); then
        if ! confirm "Prosseguir com restauração destas ferramentas?"; then
          info "Operação cancelada."
          return 1
        fi
      fi

      for t in "${args_tools[@]}"; do
        reinstall_tool "$t" || warn "Falha ao restaurar $t (continuando)."
      done
      ;;

    section)
      echo
      _bld "Plano de restauração (seção): $section"

      if (( steps==1 && autoy==0 )); then
        if ! confirm "Prosseguir com restauração da seção '$section'?"; then
          info "Operação cancelada."
          return 1
        fi
      fi

      restore_section "$section" || { err "Falha ao restaurar seção '$section'"; return 1; }
      ;;

    all)
      echo
      _bld "Plano de restauração (completo): todas as seções"
      if (( steps==1 && autoy==0 )); then
        if ! confirm "Prosseguir com restauração completa?"; then
          info "Operação cancelada."
          return 1
        fi
      fi

      local sections; mapfile -t sections < <(list_sections)
      if (( ${#sections[@]} == 0 )); then
        err "Nenhuma seção encontrada em $CFG_FILE (.tools[].section)."
        exit 1
      fi
      for sec in "${sections[@]}"; do
        restore_section "$sec" || warn "Falha ao restaurar seção '$sec' (continuando)."
      done
      ;;
  esac

  if (( reload==1 )); then
    ok "Restore concluído. Recarregando shell..."
    exec zsh -l
  else
    ok "Restore concluído. Rode: source ~/.zshrc"
  fi
}

cmd_update(){
  ensure_workspace_dirs
  prime_brew_shellenv

  local steps=0 autoy=0
  local mode=""      # all | section | tools
  local section=""
  local args_tools=()
  local show_outdated=0

  # parse flags
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -steps) steps=1 ;;
      -y|--yes) autoy=1 ;;
      -all) mode="all" ;;
      -section)
        mode="section"
        shift; section="${1:-}"
        [[ -z "$section" ]] && { err "Faltou o nome da seção após -section"; exit 1; }
        ;;
      --outdated) show_outdated=1 ;;
      -*)
        warn "Opção desconhecida: $1"
        ;;
      *)
        mode="tools"
        args_tools+=("$1")
        ;;
    esac
    shift || true
  done

  # somente listar desatualizados
  if (( show_outdated==1 )); then
    brew_update_quick || true
    echo
    brew_list_outdated
    return 0
  fi

  # Se nada especificado, assume -all
  [[ -z "$mode" ]] && mode="all"

  brew_update_quick || true

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
  printf ' - %s\n' "${targets[@]}"

  if (( steps==1 && autoy==0 )); then
    if ! confirm "Deseja prosseguir e atualizar estas ferramentas?"; then
      info "Operação cancelada."
      return 1
    fi
  fi

  for t in "${targets[@]}"; do
    if (( steps==1 && autoy==0 )); then
      if ! confirm "Atualizar '$t'?"; then
        info "Pulando $t."
        continue
      fi
    fi
    upgrade_tool "$t"
  done

  ok "Update concluído."
}

cmd_backup(){
  ensure_workspace_dirs
  prime_brew_shellenv

  # Subcomandos: list | -list | delete | -delete | restore | -restore | restore latest | restore -latest
  local sub="${1:-}"
  case "$sub" in
    "" )
      # comportamento padrão: criar backup
      shift || true
      info "Criando backup do ambiente..."
      local ts zipfile
      ts="$(date +"%Y%m%d-%H%M%S")"
      mkdir -p "$BACKUP_DIR"
      zipfile="$BACKUP_DIR/.easyenv-backup-$ts.zip"

      (
        cd "$HOME" || exit 1
        # inclua seus artefatos; mantenha o que você já tem
        zip -r "$zipfile" \
          .zshrc .zprofile \
          .easyenv/themes/active \
          2>/dev/null
      ) || { err "Falha ao gerar backup"; return 1; }

      ok "Backup criado em: $zipfile"
      echo "$zipfile"
      ;;

    -list|list )
      shift || true
      echo "Backups em: $BACKUP_DIR"
      list_backups_human
      ;;

    -delete|delete )
      shift || true
      # aceita opcionalmente um nome/caminho
      local target="${1:-}"
      delete_backup "$target"
      ;;
    
    -purge|purge )
      shift || true
      local keep="${1:-}"
      if [[ -z "$keep" ]]; then
        err "Deve informar quantos backups você deseja manter. Uso: easyenv backup -purge <N>"
        return 1
      fi
      purge_backups "$keep"
      ;;

    -restore|restore )
      shift || true
      local mode="${1:-}" ; shift || true
      case "$mode" in
        -latest|latest )
          local lb
          lb="$(latest_backup)"
          if [[ -z "$lb" ]]; then
            warn "Nenhum backup encontrado em $BACKUP_DIR."
            return 1
          fi
          info "Restaurando backup mais recente: $(basename "$lb")"
          extract_backup_zip "$lb" || { err "Falha ao restaurar $lb"; return 1; }
          ok "Backup restaurado."
          ;;
        "" )
          # interativo
          local chosen
          chosen="$(choose_backup_interactive)"
          [[ -z "$chosen" ]] && { warn "Nenhum backup selecionado."; return 1; }
          extract_backup_zip "$chosen" || { err "Falha ao restaurar $chosen"; return 1; }
          ok "Backup restaurado."
          ;;
        * )
          # nome ou caminho
          local file="$mode"
          [[ "$file" != /* ]] && file="$BACKUP_DIR/$file"
          if [[ ! -f "$file" ]]; then
            err "Backup não encontrado: $file"
            return 1
          fi
          info "Restaurando: $(basename "$file")"
          extract_backup_zip "$file" || { err "Falha ao restaurar $file"; return 1; }
          ok "Backup restaurado."
          ;;
      esac
      ;;

    * )
      warn "Opção desconhecida para 'backup': $sub"
      echo "Uso:"
      echo "  easyenv backup                      # cria backup"
      echo "  easyenv backup -list                # lista backups"
      echo "  easyenv backup -delete [arquivo]    # apaga (interativo se omitir arquivo)"
      echo "  easyenv backup -restore             # restaura (interativo)"
      echo "  easyenv backup restore -latest      # restaura o mais recente"
      echo "  easyenv backup restore <arquivo>    # restaura pelo nome/caminho"
      return 1
      ;;
  esac
}

# --------------- Dispatcher ---------------

main(){
  ensure_workspace_dirs

  case "${1:-}" in
    -v|--version)
      log_line "version" "start" "-"
      cmd_version
      log_line "version" "success" "ok"
      exit 0
      ;;
  esac

  local cmd="${1:-help}"; shift || true

  case "$cmd" in
    help|-h|--help)      log_line "help" "start" "-";  cmd_help;   log_line "help" "success" "ok" ;;
    init)                log_line "init" "start" "-";   cmd_init "$@"; log_line "init" "success" "ok" ;;
    clean)               log_line "clean" "start" "-";   cmd_clean "$@"; log_line "clean" "success" "ok" ;;
    status)              log_line "status" "start" "-"; cmd_status "$@"; log_line "status" "success" "ok" ;;
    restore)             log_line "restore" "start" "-"; cmd_restore "$@"; log_line "restore" "success" "ok" ;;
    update)              log_line "update" "start" "-";  cmd_update "$@"; log_line "update" "success" "ok" ;;
    backup)              log_line "backup" "start" "-";  cmd_backup "$@"; log_line "backup" "success" "ok" ;;
    add|theme)
      err "O subcomando '$cmd' será implementado no próximo passo do backlog."
      log_line "$cmd" "todo" "not-implemented"
      exit 2
      ;;
    *)
      err "Comando desconhecido: $cmd"
      echo "Use: easyenv help"
      log_line "$cmd" "error" "unknown-command"
      exit 1
      ;;
  esac
}

main "$@"