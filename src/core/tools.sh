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
  easyenv tools install

Descrição:
  Instala os pré-requisitos e utilitários definidos em config/tools.yml:
  - Homebrew, yq
  - Oh My Zsh
  - Tema Spaceship
  - Utilitários de produtividade (fzf, zoxide, eza, bat, ripgrep, fd, direnv, thefuck, httpie, jq, gh, ghq, etc.)

Exemplos:
  easyenv tools install
EOF
}

_tools_install() {
  local svc="$EASYENV_HOME/src/data/services/tools.sh"
  if [[ ! -f "$svc" ]]; then
    err "Serviço não encontrado: $svc"
    return 1
  fi

  info "Iniciando instalação das ferramentas (config/tools.yml)…"
  # delega a instalação ao serviço (ele garante brew + yq)
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