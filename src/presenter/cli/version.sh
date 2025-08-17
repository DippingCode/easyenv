#!/usr/bin/env bash
# presenter/cli/version.sh — imprime versão a partir do dev_log.yml

cmd_version(){
  local detailed=0
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --detailed|-d) detailed=1 ;;
      -h|--help) _version_help; return 0 ;;
      *) ;; # ignora flags desconhecidas aqui
    esac
    shift || true
  done

  local devlog
  if [[ -f "$EASYENV_HOME/dev_log.yml" ]]; then
    devlog="$EASYENV_HOME/dev_log.yml"
  elif [[ -f "$EASYENV_HOME/docs/dev_log.yml" ]]; then
    devlog="$EASYENV_HOME/docs/dev_log.yml"
  else
    echo "easyenv v0.0.0"
    return 0
  fi

  local ver build
  ver="$(_devlog_first_field "$devlog" "version")"
  build="$(_devlog_first_field "$devlog" "build")"

  ver="${ver:-0.0.0}"
  if [[ -n "$build" ]]; then
    echo "easyenv v${ver} (build ${build})"
  else
    echo "easyenv v${ver}"
  fi

  if (( detailed==1 )); then
    echo
    _print_detailed_from_devlog "$devlog"
  fi
}

_version_help(){
  cat <<EOF
Uso:
  easyenv version [--detailed]

Descrição:
  Exibe a versão atual.

Opções:
  --detailed, -d   Mostra detalhes desta build (summary, notes, next_steps).
EOF
}

# Retorna o primeiro valor encontrado de uma chave simples (ex.: version, build)
# Considera que a entrada mais recente foi adicionada logo após "tasks:".
_devlog_first_field(){
  local file="$1" key="$2"
  # Procura a primeira ocorrência do campo imediatamente após "tasks:"
  awk -v k="$key" '
    BEGIN{in_tasks=0}
    /^tasks:/ {in_tasks=1; next}
    in_tasks==1 {
      # captura a primeira ocorrência do campo desejado
      if ($0 ~ "^[[:space:]]*" k "[[:space:]]*:") {
        # remove até ":" e espaços; remove aspas
        sub(/^[[:space:]]*[^:]+:[[:space:]]*/, "", $0)
        gsub(/^"[ ]*|"[ ]*$/,"",$0)
        gsub(/^'\''[ ]*|'\''[ ]*$/,"",$0)
        print $0
        exit
      }
      # se achar um novo item de tarefa "- name:", continua, mas ainda só quer o primeiro
      if ($0 ~ "^[[:space:]]*- name:[[:space:]]*") { if (found==1) exit }
    }
  ' "$file" 2>/dev/null
}

# Extrai blocos de listas YAML sob summary/notes/next_steps do primeiro item em tasks:
# Imprime em formato de bullets simples.
_print_detailed_from_devlog(){
  local file="$1"

  echo "Detalhes desta build:"
  echo

  # Versão e build novamente (em cabeçalho)
  local ver build
  ver="$(_devlog_first_field "$file" "version")"
  build="$(_devlog_first_field "$file" "build")"
  [[ -n "$ver"  ]] && echo "  • version: $ver"
  [[ -n "$build" ]] && echo "  • build  : $build"
  echo

  _print_yaml_list "$file" "summary"    "O que há de novo"
  _print_yaml_list "$file" "notes"      "Notas"
  _print_yaml_list "$file" "next_steps" "Próximos passos"
}

# Imprime a lista YAML do primeiro bloco de tasks: para uma dada chave (ex.: summary)
_print_yaml_list(){
  local file="$1" key="$2" title="$3"

  # Extrai apenas o primeiro item dentro de tasks:, coletando linhas da lista '- ' sob a chave
  local content
  content="$(awk -v key="$key" '
    BEGIN{in_tasks=0; in_first_item=0; grab=0}
    /^tasks:/ {in_tasks=1; next}
    in_tasks==1 {
      # Detecta início do primeiro item de task
      if ($0 ~ "^[[:space:]]*- name:[[:space:]]*") { 
        if (in_first_item==0) { in_first_item=1 }
        else { 
          # chegamos ao próximo item: se já coletamos algo, parar
          if (grab==1) exit
        }
      }

      # Quando achar a chave, liga a captura
      if (in_first_item==1 && $0 ~ "^[[:space:]]*" key ":[[:space:]]*$") { grab=1; next }

      # Enquanto grab==1, coletar linhas com "- " (lista) mantendo o texto após "- "
      if (grab==1) {
        if ($0 ~ "^[[:space:]]*-[[:space:]]") {
          # remove prefixos até o "- "
          sub(/^[[:space:]]*-[[:space:]]*/, "", $0)
          print $0
          next
        } else {
          # terminou a lista (encontrou linha que não começa com "- ")
          exit
        }
      }
    }
  ' "$file" 2>/dev/null)"

  if [[ -n "$content" ]]; then
    echo "$title:"
    echo "$content" | sed 's/^/  - /'
    echo
  fi
}