# cmd_backup: sub-CLI de backups (list/delete/restore/purge e criar)
cmd_backup(){
  ensure_workspace_dirs
  prime_brew_shellenv

  local sub="${1:-}"

  case "$sub" in
    "" )
      shift || true
      info "Criando backup do ambiente..."
      local ts zipfile
      ts="$(date +"%Y%m%d-%H%M%S")"
      mkdir -p "$BACKUP_DIR"
      zipfile="$BACKUP_DIR/.easyenv-backup-$ts.zip"
      (
        cd "$HOME" || exit 1
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
      local target="${1:-}"
      delete_backup "$target"
      ;;

    -restore|restore )
      shift || true
      local mode="${1:-}"; shift || true
      case "$mode" in
        -latest|latest )
          local lb; lb="$(latest_backup)"
          if [[ -z "$lb" ]]; then warn "Nenhum backup encontrado."; return 1; fi
          info "Restaurando mais recente: $(basename "$lb")"
          extract_backup_zip "$lb" || { err "Falha ao restaurar $lb"; return 1; }
          ok "Backup restaurado."
          ;;
        "" )
          local chosen; chosen="$(choose_backup_interactive)"
          [[ -z "$chosen" ]] && { warn "Nenhum backup selecionado."; return 1; }
          extract_backup_zip "$chosen" || { err "Falha ao restaurar $chosen"; return 1; }
          ok "Backup restaurado."
          ;;
        * )
          local file="$mode"
          [[ "$file" != /* ]] && file="$BACKUP_DIR/$file"
          [[ ! -f "$file" ]] && { err "Backup não encontrado: $file"; return 1; }
          info "Restaurando: $(basename "$file")"
          extract_backup_zip "$file" || { err "Falha ao restaurar $file"; return 1; }
          ok "Backup restaurado."
          ;;
      esac
      ;;

    -purge|purge )
      shift || true
      local keep="${1:-}"
      if [[ -z "$keep" ]]; then
        local total
        total="$(count_backups)"
        if [[ -z "$total" || "$total" == "0" ]]; then
          warn "Nenhum backup encontrado para purgar."
          return 0
        fi
        echo "Há $total backups em $BACKUP_DIR."
        read -r -p "Quantos deseja manter? (1-$total) [padrão: 3] " keep
        keep="${keep:-3}"
      fi
      if ! [[ "$keep" =~ ^[0-9]+$ ]] || (( keep <= 0 )); then
        err "Uso: easyenv backup -purge <N>"
        return 1
      fi
      purge_backups "$keep"
      ;;

    -h|--help|help )
      cmd_backup_help
      ;;

    * )
      warn "Opção desconhecida para 'backup': $sub"
      cmd_backup_help
      return 1
      ;;
  esac
}

cmd_backup_help(){
  cat <<EOF
Uso: easyenv backup [subcomando]

Subcomandos:
  (vazio)                 Cria um backup agora
  -list | list            Lista backups
  -delete | delete [arq]  Apaga backup (interativo se omitir arquivo)
  -restore | restore      Restaura (interativo)
  restore -latest         Restaura o mais recente
  restore <arquivo>       Restaura por nome/caminho
  -purge | purge <N>      Mantém apenas os N mais recentes (interativo se omitir N)

Exemplos:
  easyenv backup
  easyenv backup -list
  easyenv backup -restore
  easyenv backup restore -latest
  easyenv backup -delete
  easyenv backup -purge 3
EOF
}