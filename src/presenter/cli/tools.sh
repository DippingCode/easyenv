#!/usr/bin/env bash
# presenter/cli/tools.sh — gestão de catálogo (list/install/update/uninstall)

set -euo pipefail

# Requer que o router tenha carregado: core/{config,utils,guards,logging}.sh
# Funções: info, warn, err, ok, confirm, require_cmd

# ---------------------------
# Resolvedor de paths
# ---------------------------
__tools_resolve_catalog() {
  if [[ -n "${EASYENV_TOOLS_YML:-}" && -f "${EASYENV_TOOLS_YML}" ]]; then
    echo "${EASYENV_TOOLS_YML}"; return 0
  fi
  local base="${EASYENV_HOME:-}"
  if [[ -n "$base" && -f "$base/config/tools.yml" ]]; then
    echo "$base/config/tools.yml"; return 0
  fi
  local here; here="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
  if [[ -f "$here/config/tools.yml" ]]; then
    echo "$here/config/tools.yml"; return 0
  fi
  echo "${EASYENV_HOME:-}/config/tools.yml"
  return 1
}

__tools_catalog_count() {
  local cat="$1"
  yq -r '.tools | length // 0' "$cat"
}

__tools_each_name() {
  local cat="$1"
  yq -r '.tools[].name' "$cat"
}

__tools_get_field() {
  local cat="$1" name="$2" jqpath="$3"
  yq -r --arg n "$name" ".tools[] | select(.name==\$n) | ${jqpath} // empty" "$cat"
}

# ---------------------------
# Brew helpers (seguros)
# ---------------------------
__have_brew() { command -v brew >/dev/null 2>&1; }
__have_jq()   { command -v jq   >/dev/null 2>&1; }

__brew_installed_version() {
  local pkg="$1"
  if ! __have_brew; then echo "-"; return 0; fi

  # fórmula
  if brew list --formula >/dev/null 2>&1; then
    if brew list --versions "$pkg" >/dev/null 2>&1; then
      brew list --versions "$pkg" | awk '{print $NF}'
      return 0
    fi
  fi
  # cask
  if brew list --cask >/dev/null 2>&1; then
    if brew list --cask --versions "$pkg" >/dev/null 2>&1; then
      brew list --cask --versions "$pkg" | awk '{print $NF}'
      return 0
    fi
  fi
  echo "-"
}

__brew_latest_formula() {
  local formula="$1"
  if ! __have_brew; then echo "-"; return 0; fi

  if __have_jq; then
    if out="$(brew info --json=v2 "$formula" 2>/dev/null || true)"; then
      if [[ -n "$out" ]]; then
        echo "$out" | jq -r '.formulae[0].versions.stable // "-"'
        return 0
      fi
    fi
  fi

  # Fallback textual
  local first
  first="$(brew info "$formula" 2>/dev/null | head -n1 || true)"
  if [[ -n "$first" ]]; then
    # tenta achar token de versão
    echo "$first" | grep -Eo '[0-9]+(\.[0-9A-Za-z\-+]+)+' | head -n1 || true
    return 0
  fi
  echo "-"
}

__brew_latest_cask() {
  local cask="$1"
  if ! __have_brew; then echo "-"; return 0; fi

  if __have_jq; then
    if out="$(brew info --cask --json=v2 "$cask" 2>/dev/null || true)"; then
      if [[ -n "$out" ]]; then
        echo "$out" | jq -r '.casks[0].versions.current // "-"'
        return 0
      fi
    fi
  fi

  # Fallback textual
  local line
  line="$(brew info --cask "$cask" 2>/dev/null | head -n1 || true)"
  [[ -z "$line" ]] && { echo "-"; return 0; }
  echo "$line" | grep -Eo '[0-9]+(\.[0-9A-Za-z\-+]+)+' | head -n1 || echo "-"
}

# ---------------------------
# Versões (installed / latest)
# ---------------------------
__installed_version_for_tool() {
  local cat="$1" name="$2"

  local check; check="$(__tools_get_field "$cat" "$name" '.check_version_cmd')"
  if [[ -n "$check" && "$check" != "null" ]]; then
    # Não deixar pipefail matar a leitura quando o comando falhar:
    local out
    set +o pipefail
    out="$(bash -lc "$check" 2>/dev/null | head -n1 || true)"
    set -o pipefail
    [[ -n "$out" ]] && { echo "$out" | sed 's/[[:space:]]*$//'; return 0; }
  fi

  local formula cask
  formula="$(__tools_get_field "$cat" "$name" '.brew.formula')"
  cask="$(__tools_get_field "$cat" "$name" '.brew.cask')"

  if [[ -n "$formula" && "$formula" != "null" ]]; then
    __brew_installed_version "$formula"; return 0
  fi
  if [[ -n "$cask" && "$cask" != "null" ]]; then
    __brew_installed_version "$cask"; return 0
  fi

  echo "-"
}

__latest_version_for_tool() {
  local cat="$1" name="$2"
  local formula cask
  formula="$(__tools_get_field "$cat" "$name" '.brew.formula')"
  cask="$(__tools_get_field "$cat" "$name" '.brew.cask')"

  if [[ -n "$formula" && "$formula" != "null" ]]; then
    __brew_latest_formula "$formula"; return 0
  fi
  if [[ -n "$cask" && "$cask" != "null" ]]; then
    __brew_latest_cask "$cask"; return 0
  fi
  echo "-"
}

# ---------------------------
# Sync (grava no tools.yml)
# ---------------------------
__tools_sync_versions() {
  local cat="$1" name="$2" installed="$3" latest="$4"
  if [[ -n "$installed" && "$installed" != "-" && "$installed" != "null" ]]; then
    yq -i --arg n "$name" --arg v "$installed" \
      '.tools |= (map(if .name == $n then .version_installed = $v else . end))' \
      "$cat" || true
  fi
  if [[ -n "$latest" && "$latest" != "-" && "$latest" != "null" ]]; then
    yq -i --arg n "$name" --arg v "$latest" \
      '.tools |= (map(if .name == $n then .version_latest = $v else . end))' \
      "$cat" || true
  fi
}

# ---------------------------
# Renderização
# ---------------------------
__tools_render_list() {
  local cat="$1" mode="${2:-plain}" debug="${3:-0}"

  local count; count="$(__tools_catalog_count "$cat")"
  if [[ "$count" == "0" ]]; then
    warn "Nenhuma ferramenta definida em: $cat (.tools vazio)"
    return 0
  fi

  case "$mode" in
    json)
      echo '['
      local first=1
      while IFS= read -r name; do
        [[ -z "$name" ]] && continue
        local type formula cask check installed latest
        type="$(__tools_get_field   "$cat" "$name" '.type')"
        formula="$(__tools_get_field "$cat" "$name" '.brew.formula')"
        cask="$(__tools_get_field    "$cat" "$name" '.brew.cask')"
        check="$(__tools_get_field   "$cat" "$name" '.check_version_cmd')"
        installed="$(__installed_version_for_tool "$cat" "$name")"
        latest="$(__latest_version_for_tool "$cat" "$name")"
        __tools_sync_versions "$cat" "$name" "$installed" "$latest"
        (( first==0 )) && echo ','
        first=0
        printf '  {"name":"%s","type":"%s","installed":"%s","latest":"%s","formula":"%s","cask":"%s","check":"%s"}' \
          "$name" "${type:-"-"}" "${installed:-"-"}" "${latest:-"-"}" \
          "${formula:-""}" "${cask:-""}" "${check:-""}"
      done < <(__tools_each_name "$cat")
      echo
      echo ']'
      ;;

    detailed)
      printf "%-22s %-12s %-18s %-18s\n" "Name" "Type" "Installed" "Latest"
      printf "%-22s %-12s %-18s %-18s\n" "----------------------" "------------" "------------------" "------------------"
      while IFS= read -r name; do
        [[ -z "$name" ]] && continue
        local type installed latest formula cask check
        type="$(__tools_get_field "$cat" "$name" '.type')"
        installed="$(__installed_version_for_tool "$cat" "$name")"
        latest="$(__latest_version_for_tool "$cat" "$name")"
        __tools_sync_versions "$cat" "$name" "$installed" "$latest"
        printf "%-22s %-12s %-18s %-18s\n" "$name" "${type:-"-"}" "${installed:-"-"}" "${latest:-"-"}"
        if (( debug==1 )); then
          formula="$(__tools_get_field "$cat" "$name" '.brew.formula')"
          cask="$(__tools_get_field "$cat" "$name" '.brew.cask')"
          check="$(__tools_get_field "$cat" "$name" '.check_version_cmd')"
          printf "    [debug] formula=%s cask=%s check=%s\n" "${formula:-""}" "${cask:-""}" "${check:-""}"
        fi
      done < <(__tools_each_name "$cat")
      ;;

    *)
      while IFS= read -r name; do
        [[ -z "$name" ]] && continue
        local installed latest
        installed="$(__installed_version_for_tool "$cat" "$name")"
        latest="$(__latest_version_for_tool "$cat" "$name")"
        __tools_sync_versions "$cat" "$name" "$installed" "$latest"
        printf " - %-22s  %s (latest: %s)\n" "$name" "${installed:-"-"}" "${latest:-"-"}"
      done < <(__tools_each_name "$cat")
      ;;
  esac
}

# ---------------------------
# Instalar / Update / Uninstall
# ---------------------------
__tools_install_one() {
  local cat="$1" name="$2"
  info "Instalando: $name"
  local formula cask
  formula="$(__tools_get_field "$cat" "$name" '.brew.formula')"
  cask="$(__tools_get_field "$cat" "$name" '.brew.cask')"

  if __have_brew; then
    [[ -n "${formula:-}" && "$formula" != "null" ]] && { brew list "$formula" >/dev/null 2>&1 || brew install "$formula"; }
    [[ -n "${cask:-}"    && "$cask"    != "null" ]] && { brew list --cask "$cask" >/dev/null 2>&1 || brew install --cask "$cask"; }
  fi

  local install_cmd; install_cmd="$(__tools_get_field "$cat" "$name" '.install')"
  if [[ -n "$install_cmd" && "$install_cmd" != "null" ]]; then
    bash -lc "$install_cmd" || warn "Instalação extra falhou para $name"
  fi

  local installed latest
  installed="$(__installed_version_for_tool "$cat" "$name")"
  latest="$(__latest_version_for_tool "$cat" "$name")"
  __tools_sync_versions "$cat" "$name" "$installed" "$latest"
  ok "$name instalado."
}

__tools_update_one() {
  local cat="$1" name="$2"
  info "Atualizando: $name"
  local formula cask update_cmd
  formula="$(__tools_get_field "$cat" "$name" '.brew.formula')"
  cask="$(__tools_get_field "$cat" "$name" '.brew.cask')"
  update_cmd="$(__tools_get_field "$cat" "$name" '.update_cmd')"

  if [[ -n "$update_cmd" && "$update_cmd" != "null" ]]; then
    bash -lc "$update_cmd" || warn "Falha ao atualizar $name"
  else
    if __have_brew; then
      [[ -n "${formula:-}" && "$formula" != "null" ]] && brew upgrade "$formula" || true
      [[ -n "${cask:-}"    && "$cask"    != "null" ]] && brew upgrade --cask "$cask" || true
    fi
  fi

  local installed latest
  installed="$(__installed_version_for_tool "$cat" "$name")"
  latest="$(__latest_version_for_tool "$cat" "$name")"
  __tools_sync_versions "$cat" "$name" "$installed" "$latest"
  ok "$name atualizado."
}

__tools_uninstall_one() {
  local cat="$1" name="$2"
  info "Removendo: $name"
  local formula cask uninstall_cmd
  formula="$(__tools_get_field "$cat" "$name" '.brew.formula')"
  cask="$(__tools_get_field "$cat" "$name" '.brew.cask')"
  uninstall_cmd="$(__tools_get_field "$cat" "$name" '.uninstall')"

  if __have_brew; then
    [[ -n "${formula:-}" && "$formula" != "null" ]] && { brew list "$formula" >/dev/null 2>&1 && brew uninstall "$formula" || true; }
    [[ -n "${cask:-}"    && "$cask"    != "null" ]] && { brew list --cask "$cask" >/dev/null 2>&1 && brew uninstall --cask "$cask" || true; }
  fi

  if [[ -n "$uninstall_cmd" && "$uninstall_cmd" != "null" ]]; then
    bash -lc "$uninstall_cmd" || true
  fi

  yq -i --arg n "$name" \
    '.tools |= (map(if .name == $n then .version_installed = "-" else . end))' \
    "$cat" || true

  ok "$name removido."
}

# ---------------------------
# Subcomandos
# ---------------------------
__cmd_tools_list() {
  local mode="plain" debug=0
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --detailed) mode="detailed" ;;
      --json)     mode="json" ;;
      --debug)    debug=1 ;;
      *)          warn "Opção desconhecida em 'tools list': $1" ;;
    esac
    shift || true
  done

  require_cmd "yq" "Instale yq: brew install yq"

  local catalog resolved
  resolved="$(__tools_resolve_catalog)" || true
  catalog="$resolved"

  if (( debug==1 )); then
    echo "DEBUG: EASYENV_HOME=${EASYENV_HOME:-<unset>}"
    echo "DEBUG: EASYENV_TOOLS_YML=${EASYENV_TOOLS_YML:-<unset>}"
    echo "DEBUG: resolved_catalog=$resolved"
    echo -n "DEBUG: catalog_exists="; [[ -f "$catalog" ]] && echo "yes" || echo "no"
    echo -n "DEBUG: have_brew="; if __have_brew; then echo "yes"; else echo "no"; fi
    echo -n "DEBUG: have_jq=";   if __have_jq;   then echo "yes"; else echo "no"; fi
  fi

  if [[ ! -f "$catalog" ]]; then
    warn "Catálogo não encontrado em: $catalog"
    echo "Crie/adicione um 'config/tools.yml'."
    return 0
  fi

  __tools_render_list "$catalog" "$mode" "$debug"
}

__cmd_tools_install() {
  require_cmd "yq" "Instale yq: brew install yq"
  local catalog; catalog="$(__tools_resolve_catalog)"
  if [[ ! -f "$catalog" ]]; then err "Catálogo não encontrado em: $catalog"; return 1; fi
  info "Instalando ferramentas do catálogo: $catalog"
  if __have_brew; then brew update || true; fi
  while IFS= read -r name; do
    [[ -z "$name" ]] && continue
    __tools_install_one "$catalog" "$name"
  done < <(__tools_each_name "$catalog")
  ok "Instalação concluída."
}

__cmd_tools_update() {
  require_cmd "yq" "Instale yq: brew install yq"
  local catalog; catalog="$(__tools_resolve_catalog)"
  if [[ ! -f "$catalog" ]]; then err "Catálogo não encontrado em: $catalog"; return 1; fi
  info "Atualizando ferramentas do catálogo: $catalog"
  if __have_brew; then brew update || true; fi
  while IFS= read -r name; do
    [[ -z "$name" ]] && continue
    __tools_update_one "$catalog" "$name"
  done < <(__tools_each_name "$catalog")
  ok "Atualização concluída."
}

__cmd_tools_uninstall() {
  require_cmd "yq" "Instale yq: brew install yq"
  local catalog; catalog="$(__tools_resolve_catalog)"
  if [[ ! -f "$catalog" ]]; then err "Catálogo não encontrado em: $catalog"; return 1; fi
  if ! confirm "Tem certeza que deseja remover TODAS as ferramentas do catálogo?"; then
    info "Operação cancelada."
    return 0
  fi
  while IFS= read -r name; do
    [[ -z "$name" ]] && continue
    __tools_uninstall_one "$catalog" "$name"
  done < <(__tools_each_name "$catalog")
  ok "Remoção concluída."
}

cmd_tools_help() {
  cat <<EOF
Uso:
  easyenv tools <subcomando>

Subcomandos:
  install                    Instala os pré-requisitos e utilitários definidos em config/tools.yml
  list [--detailed|--json]   Lista o catálogo de ferramentas (sincroniza versões no arquivo)
  update                     Atualiza todas as ferramentas do catálogo
  uninstall                  Desinstala todas as ferramentas do catálogo (confirmação interativa)

Exemplos:
  easyenv tools install
  easyenv tools list
  easyenv tools list --detailed
  easyenv tools list --json
  easyenv tools update
  easyenv tools uninstall
EOF
}

cmd_tools() {
  local sub="${1:-}"; shift || true
  case "$sub" in
    ""|-h|--help) cmd_tools_help; return 0 ;;
    list)         __cmd_tools_list "$@"; return $? ;;
    install)      __cmd_tools_install "$@"; return $? ;;
    update)       __cmd_tools_update "$@"; return $? ;;
    uninstall)    __cmd_tools_uninstall "$@"; return $? ;;
    *)            warn "Subcomando desconhecido: $sub"; cmd_tools_help; return 1 ;;
  esac
}