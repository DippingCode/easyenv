# help.sh — comando de ajuda do EasyEnv
# Este arquivo é "sourced" pelo router; não usar `set -euo pipefail` aqui.

cmd_help() {
  local cli_dir="${EASYENV_HOME:-$PWD}/src/presenter/cli"

  # Cabeçalho simples
  cat <<'HDR'
  
┌─────────────────────────────────────────────────────┐
│                    EasyEnv - Help                  │
└─────────────────────────────────────────────────────┘
HDR

  # Versão (melhor esforço: lê a primeira entrada do dev_log)
  if [[ -f "${EASYENV_HOME}/docs/dev_log.yml" ]]; then
    # pega primeira ocorrência de 'version:' e 'build:' nas primeiras linhas
    local ver build
    ver="$(head -n 50 "${EASYENV_HOME}/docs/dev_log.yml" | awk -F\" '/^[[:space:]]*version:[[:space:]]/ {gsub(/"/,"",$2); print $2; exit}')" || true
    build="$(head -n 50 "${EASYENV_HOME}/docs/dev_log.yml" | awk -F\" '/^[[:space:]]*build:[[:space:]]/ {gsub(/"/,"",$2); print $2; exit}')" || true
    if [[ -n "$ver" ]]; then
      echo "Versão atual: ${ver}${build:+ (build ${build})}"
      echo
    fi
  fi

  cat <<'USAGE'
Uso:
  easyenv <comando> [opções]

Atalhos:
  -h, --help      → help
  -v, --version   → version
  upgrade         → update
  diag            → doctor

Exemplos:
  easyenv --version
  easyenv status --detailed
  easyenv init
  easyenv backup -list
  easyenv update --outdated
USAGE
  echo

  # Lista dinâmica de comandos disponíveis
  echo "Comandos disponíveis:"
  if [[ -d "$cli_dir" ]]; then
    # coleta *.sh e formata nome + breve descrição conhecida
    local f base desc
    # ordena alfabeticamente
    while IFS= read -r f; do
      base="$(basename "$f" .sh)"
      desc="$(__help_desc_for "$base")"
      printf "  - %-12s %s\n" "$base" "$desc"
    done < <(find "$cli_dir" -maxdepth 1 -type f -name '*.sh' | sort)
  else
    echo "  (diretório de comandos não encontrado: $cli_dir)"
  fi

  echo
  echo "Dica: use 'easyenv <comando> --help' quando disponível."
}

# Descrições curtas conhecidas (opcional)
__help_desc_for() {
  local k="$1"
  case "$k" in
    help)       echo "Mostra esta ajuda" ;;
    version)    echo "Exibe a versão atual (lê docs/dev_log.yml)" ;;
    status)     echo "Resumo do ambiente; --detailed mostra versões e checks" ;;
    init)       echo "Instala/Configura por seções ou stacks" ;;
    clean)      echo "Remove ferramentas e/ou faz limpeza de caches" ;;
    update)     echo "Atualiza ferramentas (brew/npm/etc)" ;;
    restore)    echo "Restaura ferramentas ou arquivos a partir de backup" ;;
    backup)     echo "Gera e gerencia backups (list/restore/delete/purge)" ;;
    add)        echo "Adiciona ferramenta ao catálogo e instala" ;;
    theme)      echo "Gerencia temas do Oh My Zsh (p10k, spaceship…)" ;;
    versions)   echo "Lista versões instaladas por ferramenta (plugins)" ;;
    switch)     echo "Alterna versão da ferramenta (node, flutter, dotnet…)" ;;
    doctor)     echo "Diagnóstico geral ou por ferramenta (plugins)" ;;
    push)       echo "QoL: usa última entrada do dev_log para commit/tag/push" ;;
    *)          echo "" ;;
  esac
}