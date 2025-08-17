#!/usr/bin/env bash
# presenter/cli/tools.sh — gestão do catálogo de ferramentas (tools.yml)

# -------------------------------------------------------------------
# HELP
# -------------------------------------------------------------------
_tools_help(){
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

# -------------------------------------------------------------------
# Caminho do catálogo
# -------------------------------------------------------------------
_tools_cfg_path(){
  # fonte da verdade do catálogo
  echo "${EASYENV_HOME}/config/tools.yml"
}

# -------------------------------------------------------------------
# Parser leve de YAML -> TSV
# Gera linhas: name|section|type|formula|cask|description
# Observações:
#   - assume estrutura nivelada conforme nosso tools.yml
#   - ignora itens sem "name"
# -------------------------------------------------------------------
_tools_parse_yaml_to_tsv(){
  local cfg="$1"
  awk '
    BEGIN{
      in_tools=0; in_item=0; name=""; section=""; type=""; formula=""; cask=""; desc=""; in_brew=0;
    }
    # Detecta início da lista
    /^tools:/ { in_tools=1; next }

    # Dentro da lista, cada item começa por "- name:"
    in_tools==1 && $0 ~ /^[[:space:]]*-[[:space:]]name:/ {
      # se já havia um item, imprime antes de iniciar o próximo
      if(name != ""){
        print name "|" section "|" type "|" formula "|" cask "|" desc;
      }
      # reseta para novo item
      name=""; section=""; type=""; formula=""; cask=""; desc=""; in_item=1; in_brew=0;

      # captura o name da mesma linha
      gsub(/^[[:space:]]*-[[:space:]]name:[[:space:]]*/, "", $0);
      gsub(/^"|"$/, "", $0); gsub(/^'\''|'\''$/, "", $0);
      name=$0;
      next;
    }

    # Se aparecer uma nova chave de item ("- name:") e tínhamos um em curso,
    # já tratamos no bloco acima. Agora capturamos campos do item corrente:
    in_item==1 {
      # sai do brew quando aparece nova chave do item em mesmo nível
      if($0 ~ /^[[:space:]]*brew:[[:space:]]*{[[:space:]]*}[[:space:]]*$/){ in_brew=0 } # brew: {}

      # bloco brew: começa quando vê "brew:" e não é objeto vazio
      if($0 ~ /^[[:space:]]*brew:[[:space:]]*$/){ in_brew=1; next }

      # campos simples
      if($0 ~ /^[[:space:]]*section:/){
        line=$0; sub(/^[[:space:]]*section:[[:space:]]*/, "", line);
        gsub(/^"|"$/, "", line); gsub(/^'\''|'\''$/, "", line);
        section=line;
        next;
      }
      if($0 ~ /^[[:space:]]*type:/){
        line=$0; sub(/^[[:space:]]*type:[[:space:]]*/, "", line);
        gsub(/^"|"$/, "", line); gsub(/^'\''|'\''$/, "", line);
        type=line;
        next;
      }
      if($0 ~ /^[[:space:]]*description:/){
        line=$0; sub(/^[[:space:]]*description:[[:space:]]*/, "", line);
        gsub(/^"|"$/, "", line); gsub(/^'\''|'\''$/, "", line);
        desc=line;
        next;
      }

      # dentro de brew:, captura formula/cask
      if(in_brew==1){
        if($0 ~ /^[[:space:]]*formula:/){
          line=$0; sub(/^[[:space:]]*formula:[[:space:]]*/, "", line);
          gsub(/^"|"$/, "", line); gsub(/^'\''|'\''$/, "", line);
          formula=line;
          next;
        }
        if($0 ~ /^[[:space:]]*cask:/){
          line=$0; sub(/^[[:space:]]*cask:[[:space:]]*/, "", line);
          gsub(/^"|"$/, "", line); gsub(/^'\''|'\''$/, "", line);
          cask=line;
          next;
        }
        # fim do bloco brew quando encontra uma linha com nível anterior (nova chave simples)
        if($0 ~ /^[[:space:]]*[a-zA-Z0-9_-]+:/ && $0 !~ /^[[:space:]]*(formula|cask):/){
          in_brew=0;
        }
      }
    }

    END{
      # imprime o último pendente
      if(name != ""){
        print name "|" section "|" type "|" formula "|" cask "|" desc;
      }
    }
  ' "$cfg"
}

# -------------------------------------------------------------------
# Render helpers
# -------------------------------------------------------------------
_tools_print_table(){
  # cabeçalhos: Name, Section, Type, Source
  printf "Name               Section      Type      Source\n"
  printf "-----------------  -----------  --------  ------------------------------\n"
  local IFS=$'\n'
  for ln in "$@"; do
    local name section type formula cask desc source
    name="$(echo "$ln" | cut -d'|' -f1)"
    section="$(echo "$ln" | cut -d'|' -f2)"
    type="$(echo "$ln" | cut -d'|' -f3)"
    formula="$(echo "$ln" | cut -d'|' -f4)"
    cask="$(echo "$ln" | cut -d'|' -f5)"
    if [[ -n "$formula" && "$formula" != "null" ]]; then
      source="brew:${formula}"
    elif [[ -n "$cask" && "$cask" != "null" ]]; then
      source="cask:${cask}"
    else
      source="-"
    fi
    printf "%-17s  %-11s  %-8s  %s\n" "$name" "$section" "$type" "$source"
  done
}

_tools_print_table_detailed(){
  # cabeçalhos: Name, Section, Type, Brew(formula/cask), Description
  printf "Name               Section      Type      Brew(formula/cask)            Description\n"
  printf "-----------------  -----------  --------  ------------------------------ -----------------------------------------\n"
  local IFS=$'\n'
  for ln in "$@"; do
    local name section type formula cask desc brew
    name="$(echo "$ln" | cut -d'|' -f1)"
    section="$(echo "$ln" | cut -d'|' -f2)"
    type="$(echo "$ln" | cut -d'|' -f3)"
    formula="$(echo "$ln" | cut -d'|' -f4)"
    cask="$(echo "$ln" | cut -d'|' -f5)"
    desc="$(echo "$ln" | cut -d'|' -f6)"
    if [[ -n "$formula" && "$formula" != "null" ]]; then
      brew="$formula"
    elif [[ -n "$cask" && "$cask" != "null" ]]; then
      brew="$cask"
    else
      brew="-"
    fi
    printf "%-17s  %-11s  %-8s  %-30s %s\n" "$name" "$section" "$type" "$brew" "$desc"
  done
}

_tools_print_json(){
  local first=1
  echo "["
  local IFS=$'\n'
  for ln in "$@"; do
    local name section type formula cask desc
    name="$(echo "$ln" | cut -d'|' -f1 | sed 's/"/\\"/g')"
    section="$(echo "$ln" | cut -d'|' -f2 | sed 's/"/\\"/g')"
    type="$(echo "$ln" | cut -d'|' -f3 | sed 's/"/\\"/g')"
    formula="$(echo "$ln" | cut -d'|' -f4 | sed 's/"/\\"/g')"
    cask="$(echo "$ln" | cut -d'|' -f5 | sed 's/"/\\"/g')"
    desc="$(echo "$ln" | cut -d'|' -f6 | sed 's/"/\\"/g')"
    if (( first==0 )); then echo ","; fi
    printf '  {"name":"%s","section":"%s","type":"%s","brew":{"formula":"%s","cask":"%s"},"description":"%s"}' \
      "$name" "$section" "$type" "${formula:-}" "${cask:-}" "${desc:-}"
    first=0
  done
  echo
  echo "]"
}

# -------------------------------------------------------------------
# LIST
# -------------------------------------------------------------------
_tools_list(){
  local detailed=0 as_json=0
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --detailed) detailed=1 ;;
      --json)     as_json=1  ;;
      -h|--help)  _tools_help; return 0 ;;
      *)          ;; # ignorar flags desconhecidas aqui
    esac
    shift || true
  done

  local cfg; cfg="$(_tools_cfg_path)"
  if [[ ! -f "$cfg" ]]; then
    printf "\033[33m⚠️  Catálogo não encontrado em: %s\033[0m\n" "$cfg"
    echo "Crie/adicione um 'config/tools.yml'."
    return 0
  fi

  # parse
  mapfile -t rows < <(_tools_parse_yaml_to_tsv "$cfg")
  if (( ${#rows[@]} == 0 )); then
    printf "\033[33m⚠️  Nenhuma ferramenta encontrada em: %s\033[0m\n" "$cfg"
    return 0
  fi

  if (( as_json==1 )); then
    _tools_print_json "${rows[@]}"
    return 0
  fi

  if (( detailed==1 )); then
    _tools_print_table_detailed "${rows[@]}"
  else
    _tools_print_table "${rows[@]}"
  fi
}

# -------------------------------------------------------------------
# INSTALL / UPDATE / UNINSTALL
# (já existem em presenter/cli/tools_install.sh etc.; aqui só roteamos)
# -------------------------------------------------------------------
_tools_install(){
  if declare -F tools_install_core >/dev/null 2>&1; then
    tools_install_core "$@"
  else
    echo "Instalador não disponível neste build."
  fi
}
_tools_update(){
  if declare -F tools_update_core >/dev/null 2>&1; then
    tools_update_core "$@"
  else
    echo "Atualizador não disponível neste build."
  fi
}
_tools_uninstall(){
  if declare -F tools_uninstall_core >/dev/null 2>&1; then
    tools_uninstall_core "$@"
  else
    echo "Desinstalador não disponível neste build."
  fi
}

# -------------------------------------------------------------------
# ENTRYPOINT
# -------------------------------------------------------------------
cmd_tools(){
  local sub="${1:-}"
  case "$sub" in
    ""|-h|--help|help)
      _tools_help
      ;;
    list)
      shift || true
      _tools_list "$@"
      ;;
    install)
      shift || true
      _tools_install "$@"
      ;;
    update)
      shift || true
      _tools_update "$@"
      ;;
    uninstall)
      shift || true
      _tools_uninstall "$@"
      ;;
    *)
      _tools_help
      ;;
  esac
}