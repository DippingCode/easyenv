# cmd_theme: gerencia tema do Oh My Zsh (usa core/themes.sh)
cmd_theme(){
  ensure_workspace_dirs
  prime_brew_shellenv

  local sub="${1:-}"; shift || true
  case "${sub}" in
    ""|-h|--help|help)
      cmd_theme_help
      ;;
    list)
      themes_list
      ;;
    install)
      themes_install "${1:-}"
      ;;
    set)
      themes_set "${1:-}"
      ;;
    apply)
      # repassa flags como -reload
      themes_apply "$@"
      ;;
    wizard|configure)
      themes_wizard
      ;;
    *)
      err "Uso inválido. Veja: easyenv theme --help"
      return 1
      ;;
  esac
}

cmd_theme_help(){
  cat <<'EOF'
Uso: easyenv theme <subcomando>

Subcomandos:
  list                             Lista temas suportados
  install <tema>                   Instala um tema (powerlevel10k|spaceship|agnoster|robbyrussell)
  set <tema>                       Marca tema ativo (salva estado)
  apply [-reload]                  Aplica tema ativo no ~/.zshrc (opção -reload reinicia o shell)
  wizard | configure               Abre 'p10k configure' (se Powerlevel10k instalado/ativo)

Exemplos:
  easyenv theme list
  easyenv theme install powerlevel10k
  easyenv theme set powerlevel10k
  easyenv theme apply
  easyenv theme apply -reload
  easyenv theme wizard
EOF
}