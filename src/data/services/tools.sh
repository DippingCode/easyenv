#!/usr/bin/env bash
# data/services/tools.sh — operações sobre o catálogo de ferramentas (config/tools.yml)

set -euo pipefail

EASYENV_HOME="${EASYENV_HOME:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)}"
source "${EASYENV_HOME}/src/core/utils.sh"
source "${EASYENV_HOME}/src/core/guards.sh"

# ---------- Pré-requisitos ----------
__ensure_prereqs(){
  # Git é necessário para clone de plugins e oh-my-zsh
  require_cmd "git" "Instale git primeiro (no macOS já vem: Xcode CLT)."
  # Homebrew (no macOS)
  if ! command -v brew >/dev/null 2>&1; then
    info "Homebrew não encontrado — instalando…"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    # shellenv para sessão atual
    if [[ -x /opt/homebrew/bin/brew ]]; then
      eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -x /usr/local/bin/brew ]]; then
      eval "$(/usr/local/bin/brew shellenv)"
    fi
  fi
  # yq para ler o catálogo
  if ! command -v yq >/dev/null 2>&1; then
    info "Instalando yq…"
    brew install yq
  fi
}

__brew_shellenv_now(){
  if command -v brew >/dev/null 2>&1; then
    local p; p="$(brew --prefix 2>/dev/null || true)"
    if [[ -n "$p" && -x "$p/bin/brew" ]]; then
      eval "$("$p/bin/brew" shellenv)"
    fi
  fi
}

# ---------- Utilidades ----------
__human_size(){
  # bytes -> human (aproximado)
  local bytes="${1:-0}"
  awk -v b="$bytes" 'function hum(x){s="B   KB  MB  GB  TB  PB";n=split(s,a);for(i=1;i<=n&&x>=1024;i++)x/=1024;return sprintf("%.0f%s",x,a[i])} BEGIN{print hum(b)}'
}

__jq_escape(){
  # escape simples p/ json string
  printf '%s' "$1" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))'
}

# ---------- Leitura do catálogo ----------
__tools_count(){
  local yml="$1"
  yq -r '.tools | length' "$yml" 2>/dev/null || echo 0
}

__tools_iter(){
  # imprime nome|section|type|brew_formula|brew_cask
  local yml="$1"
  yq -r '.tools[] | [
      (.name // ""),
      (.section // ""),
      (.type // ""),
      (.brew.formula // ""),
      (.brew.cask // "")
    ] | @tsv' "$yml" 2>/dev/null \
  | awk -F'\t' '{printf "%s|%s|%s|%s|%s\n",$1,$2,$3,$4,$5}'
}

# ---------- Listagem ----------
tools_service_list_plain(){
  local yml="$1"
  local n; n="$(__tools_count "$yml")"
  echo "Ferramentas no catálogo (${n}):"
  __tools_iter "$yml" | awk -F'|' '{printf " - %-20s %-10s (%s)\n",$1,$2,$3}'
}

tools_service_list_detailed(){
  local yml="$1"
  local n; n="$(__tools_count "$yml")"
  echo "Catálogo detalhado (${n}):"
  echo
  printf "%-20s %-12s %-8s  %-24s %-18s\n" "NAME" "SECTION" "TYPE" "BREW(FORMULA)" "BREW(CASK)"
  printf -- "------------------------------------------------------------------------------------------\n"
  __tools_iter "$yml" \
    | while IFS='|' read -r name section type f c; do
        printf "%-20s %-12s %-8s  %-24s %-18s\n" "$name" "$section" "$type" "${f:-"-"}" "${c:-"-"}"
      done
}

tools_service_list_json(){
  local yml="$1"
  yq -o=json '.tools' "$yml"
}

# ---------- Instalação/Atualização/Remoção ----------
__run_block(){
  local shcode="$1"
  [[ -z "${shcode// }" ]] && return 0
  # executa em subshell bash -lc para pegar PATH do brew shellenv
  bash -lc "$shcode"
}

__ensure_node_for_npm(){
  if ! command -v npm >/dev/null 2>&1; then
    info "npm não encontrado — instalando Node (LTS) via brew…"
    brew install node
  fi
}

__install_one(){
  local name="$1" section="$2" type="$3" formula="$4" cask="$5" yml="$6"

  _bld "Instalando: $name"
  __brew_shellenv_now

  # brew formula/cask
  if [[ -n "$formula" && "$formula" != "null" ]]; then
    if brew list --formula | grep -qx "$formula"; then
      info "brew: $formula já instalado."
    else
      info "brew install $formula"
      brew install "$formula"
    fi
  fi
  if [[ -n "$cask" && "$cask" != "null" ]]; then
    if brew list --cask | grep -qx "$cask"; then
      info "brew cask: $cask já instalado."
    else
      info "brew install --cask $cask"
      brew install --cask "$cask"
    fi
  fi

  # extra installs (npm/git/custom)
  local npm_pkg; npm_pkg="$(yq -r --arg n "$name" '.tools[] | select(.name==$n) | .extra.install_npm // empty' "$yml")"
  local git_repo; git_repo="$(yq -r --arg n "$name" '.tools[] | select(.name==$n) | .extra.install_git.repo // empty' "$yml")"
  local git_dest; git_dest="$(yq -r --arg n "$name" '.tools[] | select(.name==$n) | .extra.install_git.dest // empty' "$yml")"
  local install_block; install_block="$(yq -r --arg n "$name" '.tools[] | select(.name==$n) | .install // empty' "$yml")"

  if [[ -n "$npm_pkg" && "$npm_pkg" != "null" ]]; then
    __ensure_node_for_npm
    info "npm i -g $npm_pkg"
    npm install -g "$npm_pkg" || warn "Falha ao instalar npm:$npm_pkg (continuando)"
  fi

  if [[ -n "$git_repo" && "$git_repo" != "null" ]]; then
    local d="${git_dest:-$HOME/.local/share/${name}}"
    if [[ -d "$d/.git" ]]; then
      info "git repo já presente em $d — atualizando…"
      git -C "$d" pull --ff-only || true
    else
      info "git clone $git_repo → $d"
      mkdir -p "$(dirname "$d")"
      git clone "$git_repo" "$d" || warn "Falha ao clonar $git_repo"
    fi
  fi

  if [[ -n "$install_block" && "$install_block" != "null" ]]; then
    info "Rodando bloco install de $name…"
    __run_block "$install_block" || warn "Bloco install falhou em $name (continuando)"
  fi

  # env/aliases/paths no ~/.zshrc
  local zshrc_file="$HOME/.zshrc"
  local env_count; env_count="$(yq -r --arg n "$name" '.tools[] | select(.name==$n) | .env | length // 0' "$yml")"
  local alias_count; alias_count="$(yq -r --arg n "$name" '.tools[] | select(.name==$n) | .aliases | length // 0' "$yml")"
  local paths_count; paths_count="$(yq -r --arg n "$name" '.tools[] | select(.name==$n) | .paths | length // 0' "$yml")"

  if (( env_count + alias_count + paths_count > 0 )); then
    local block="# >>> EASYENV:TOOL:${name} >>>"$'\n'
    if (( env_count > 0 )); then
      while IFS= read -r line; do
        block+="${line}"$'\n'
      done < <(yq -r --arg n "$name" '.tools[] | select(.name==$n) | .env[]' "$yml")
    fi
    if (( alias_count > 0 )); then
      while IFS= read -r line; do
        block+="${line}"$'\n'
      done < <(yq -r --arg n "$name" '.tools[] | select(.name==$n) | .aliases[]' "$yml")
    fi
    if (( paths_count > 0 )); then
      while IFS= read -r line; do
        block+="${line}"$'\n'
      done < <(yq -r --arg n "$name" '.tools[] | select(.name==$n) | .paths[]' "$yml")
    fi
    block+="# <<< EASYENV:TOOL:${name} <<<"$'\n'
    # remove bloco antigo e injeta novo (idempotente simples)
    if [[ -f "$zshrc_file" ]]; then
      awk -v s="# >>> EASYENV:TOOL:${name} >>>" -v e="# <<< EASYENV:TOOL:${name} <<<" '
        BEGIN{skip=0}
        $0==s {skip=1; next}
        $0==e {skip=0; next}
        skip==0 {print}
      ' "$zshrc_file" > "$zshrc_file.__tmp" && mv "$zshrc_file.__tmp" "$zshrc_file"
    fi
    printf "\n%s" "$block" >> "$zshrc_file"
  fi

  ok "$name instalado."
}

__update_one(){
  local name="$1" formula="$2" cask="$3" yml="$4"
  __brew_shellenv_now
  brew update || true
  if [[ -n "$formula" && "$formula" != "null" ]]; then
    if brew list --formula | grep -qx "$formula"; then
      info "brew upgrade $formula"
      brew upgrade "$formula" || true
    fi
  fi
  if [[ -n "$cask" && "$cask" != "null" ]]; then
    if brew list --cask | grep -qx "$cask"; then
      info "brew upgrade --cask $cask"
      brew upgrade --cask "$cask" || true
    fi
  fi

  local update_cmd; update_cmd="$(yq -r --arg n "$name" '.tools[] | select(.name==$n) | .update_cmd // empty' "$yml")"
  if [[ -n "$update_cmd" && "$update_cmd" != "null" ]]; then
    __run_block "$update_cmd" || true
  fi
  ok "$name atualizado."
}

__uninstall_one(){
  local name="$1" formula="$2" cask="$3" yml="$4"
  __brew_shellenv_now
  if [[ -n "$formula" && "$formula" != "null" ]] && brew list --formula | grep -qx "$formula"; then
    info "brew uninstall $formula"
    brew uninstall "$formula" || true
  fi
  if [[ -n "$cask" && "$cask" != "null" ]] && brew list --cask | grep -qx "$cask"; then
    info "brew uninstall --cask $cask"
    brew uninstall --cask "$cask" || true
  fi

  local uninstall_block; uninstall_block="$(yq -r --arg n "$name" '.tools[] | select(.name==$n) | .uninstall // empty' "$yml")"
  if [[ -n "$uninstall_block" && "$uninstall_block" != "null" ]]; then
    __run_block "$uninstall_block" || true
  fi

  # limpar bloco do zshrc
  local zshrc_file="$HOME/.zshrc"
  if [[ -f "$zshrc_file" ]]; then
    awk -v s="# >>> EASYENV:TOOL:${name} >>>" -v e="# <<< EASYENV:TOOL:${name} <<<" '
      BEGIN{skip=0}
      $0==s {skip=1; next}
      $0==e {skip=0; next}
      skip==0 {print}
    ' "$zshrc_file" > "$zshrc_file.__tmp" && mv "$zshrc_file.__tmp" "$zshrc_file"
  fi

  ok "$name removido."
}

# ---------- Orquestradores públicos ----------
tools_service_install_all(){
  local yml="$1"
  __ensure_prereqs
  if [[ ! -f "$yml" ]]; then
    err "Catálogo inexistente: $yml"
    return 1
  fi
  __brew_shellenv_now

  # ordem: garanta oh-my-zsh / tema cedo
  local ordered
  ordered="$(yq -r '.tools | sort_by(.type == "core" ? 0 : 1) | .[] | .name' "$yml")"
  if [[ -z "$ordered" ]]; then
    warn "Nenhuma ferramenta definida em $yml"
    return 0
  fi

  while IFS='|' read -r name section type formula cask; do
    __install_one "$name" "$section" "$type" "$formula" "$cask" "$yml"
  done < <(__tools_iter "$yml")
}

tools_service_update_all(){
  local yml="$1"
  __ensure_prereqs
  if [[ ! -f "$yml" ]]; then
    err "Catálogo inexistente: $yml"
    return 1
  fi
  __brew_shellenv_now
  while IFS='|' read -r name _ _ formula cask; do
    __update_one "$name" "$formula" "$cask" "$yml"
  done < <(__tools_iter "$yml")
}

tools_service_uninstall_all(){
  local yml="$1"
  __ensure_prereqs
  if [[ ! -f "$yml" ]]; then
    err "Catálogo inexistente: $yml"
    return 1
  fi
  echo
  warn "Você está prestes a desinstalar TODAS as ferramentas listadas em $yml."
  read -r -p "Confirmar? (yes/NO) " ans || true
  if [[ ! "$ans" =~ ^(y|Y|yes|YES)$ ]]; then
    info "Operação cancelada."
    return 1
  fi

  # desinstala em ordem inversa só por segurança
  tac_out="$(__tools_iter "$yml" | tac || cat)" # se tac indisponível, cai no cat (ordem normal)
  while IFS='|' read -r name _ _ formula cask; do
    __uninstall_one "$name" "$formula" "$cask" "$yml"
  done <<< "$tac_out"

  # um cleanup leve do brew
  brew cleanup -s || true
}