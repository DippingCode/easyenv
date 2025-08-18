# Java plugin
tool_name(){ echo "java"; }
tool_provides(){ echo "versions switch install uninstall check"; }

# --- helpers ---
__have_sdkman(){ [[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]]; }
__have_jenv(){ command -v jenv >/dev/null 2>&1; }

__append_once(){
  # __append_once <file> <marker> <block>
  local file="$1" marker="$2" block="$3"
  touch "$file"
  if ! grep -qF "$marker" "$file"; then
    printf "\n%s\n%s\n" "$marker" "$block" >> "$file"
  fi
}

tool_versions(){
  echo "Java (JDK):"

  if command -v java >/dev/null 2>&1; then
    local current
    current="$(java -version 2>&1 | head -n1 | grep -Eo '[0-9]+\.[0-9]+\.[0-9_]+' || true)"
    [[ -n "$current" ]] && printf "  \033[32m* %s (em uso)\033[0m\n" "$current" || echo "  (não foi possível determinar a versão)"
  else
    echo "  (java ausente)  Dica: brew install openjdk  ou  sdkman install java <id>"
  fi

  # Se tiver SDKMAN, lista candidatos
  if __have_sdkman; then
    # shellcheck source=/dev/null
    source "$HOME/.sdkman/bin/sdkman-init.sh"
    echo ""
    echo "SDKMAN! (candidates/java):"
    if [[ -d "$HOME/.sdkman/candidates/java" ]]; then
      local cur_id
      cur_id="$(readlink "$HOME/.sdkman/candidates/java/current" 2>/dev/null | xargs basename || true)"
      ls -1 "$HOME/.sdkman/candidates/java" | while read -r v; do
        [[ "$v" == "current" ]] && continue
        if [[ "$v" == "$cur_id" ]]; then
          printf "  \033[32m* %s (default SDKMAN)\033[0m\n" "$v"
        else
          printf "    %s\n" "$v"
        fi
      done
    else
      echo "  (nenhuma versão via SDKMAN)"
    fi
  fi

  # Se tiver jenv, lista
  if __have_jenv; then
    echo ""
    echo "jenv:"
    jenv versions 2>/dev/null | sed 's/^/  /'
  fi
}

tool_install(){
  echo "Instalando Java (OpenJDK via Homebrew)…"
  brew install openjdk
  echo "Dica: você pode preferir gerenciar versões com SDKMAN (https://sdkman.io) ou jenv (https://www.jenv.be/)."
}

tool_uninstall(){
  echo "Removendo Java (OpenJDK Homebrew)…"
  brew uninstall openjdk || true
}

tool_check(){
  command -v java >/dev/null 2>&1
}

# tool_switch <seletor> [--scope here|global]
# seletor: "21", "23", "17.0.10" (java_home), ou ID do SDKMAN "temurin-21.0.3", "zulu-17.0.12", etc.
tool_switch(){
  local sel="${1:-}"; shift || true
  [[ -z "$sel" ]] && { err "Uso: easyenv switch java <versão|sdkman-id> [--scope here|global]"; return 1; }

  local scope="global"
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --scope) shift; scope="${1:-global}" ;;
    esac
    shift || true
  done
  [[ "$scope" != "here" && "$scope" != "global" ]] && { err "scope inválido: $scope (use here|global)"; return 1; }

  # 1) Preferência: SDKMAN!
  if __have_sdkman; then
    # shellcheck source=/dev/null
    source "$HOME/.sdkman/bin/sdkman-init.sh"
    info "Usando SDKMAN para instalar/ativar Java '$sel'…"
    sdk install java "$sel" || true
    if [[ "$scope" == "here" ]]; then
      # cria .sdkmanrc local
      echo "java=$sel" > "$PWD/.sdkmanrc"
      sdk env install || true
      sdk env || true
      ok "Java (SDKMAN) setado localmente (.sdkmanrc) → $sel"
    else
      sdk default java "$sel"
      ok "Java (SDKMAN) default → $sel"
    fi
    java -version 2>&1 | head -n 2 || true
    return 0
  fi

  # 2) Segundo: jenv
  if __have_jenv; then
    info "Usando jenv para alternar Java…"
    # tenta localizar um JAVA_HOME compatível
    local home
    home="$(/usr/libexec/java_home -v "$sel" 2>/dev/null || true)"
    if [[ -z "$home" ]]; then
      warn "Não encontrei JAVA_HOME para '-v $sel'."
      warn "Instale um JDK dessa linha (ex.: brew install openjdk@${sel%%.*}) ou use SDKMAN."
      return 1
    fi
    jenv add "$home" >/dev/null 2>&1 || true
    # pegar nome “versão” dentro do jenv
    local vername
    vername="$(jenv versions --bare 2>/dev/null | grep -F "$home" -m1 || jenv versions --bare | tail -n1)"
    if [[ -z "$vername" ]]; then
      # fallback: tentar nome derivado
      vername="$(basename "$home")"
    fi
    if [[ "$scope" == "here" ]]; then
      jenv local "$vername"
      ok "Java (jenv) local → $vername"
    else
      jenv global "$vername"
      ok "Java (jenv) global → $vername"
    fi
    java -version 2>&1 | head -n 2 || true
    return 0
  fi

  # 3) Fallback macOS: /usr/libexec/java_home
  info "Usando /usr/libexec/java_home -v \"$sel\" para configurar JAVA_HOME (fallback)…"
  local jh
  jh="$(/usr/libexec/java_home -v "$sel" 2>/dev/null || true)"
  if [[ -z "$jh" ]]; then
    err "Nenhum JDK compatível encontrado para '-v $sel'."
    echo "Sugestões:"
    echo "  - brew install openjdk@${sel%%.*}  (e depois symlink em /Library/Java/JavaVirtualMachines se necessário)"
    echo "  - Instale via SDKMAN: https://sdkman.io"
    return 1
  fi

  mkdir -p "$HOME/.easyenv"
  local envfile="$HOME/.easyenv/java_env"
  cat > "$envfile" <<EOF
# gerado pelo easyenv — JAVA
export JAVA_HOME="$jh"
# prepend bin ao PATH
case ":\$PATH:" in
  *":\$JAVA_HOME/bin:"*) ;;
  *) export PATH="\$JAVA_HOME/bin:\$PATH" ;;
esac
EOF

  # garante include no .zshrc de forma idempotente
  __append_once "$HOME/.zshrc" "# EASYENV::JAVA" '[[ -f "$HOME/.easyenv/java_env" ]] && source "$HOME/.easyenv/java_env"'

  ok "JAVA_HOME configurado para: $jh"
  echo "Dica: abra um novo shell ou rode: source ~/.zshrc"
  java -version 2>&1 | head -n 2 || true
  return 0
}

tool_update(){
  # 1) SDKMAN
  if __have_sdkman; then
    # shellcheck source=/dev/null
    source "$HOME/.sdkman/bin/sdkman-init.sh"
    info "Atualizando Java via SDKMAN…"
    sdk update || true
    sdk upgrade java || true
    ok "Java atualizado (SDKMAN)."
    return 0
  fi

  # 2) jenv
  if __have_jenv; then
    warn "jenv não instala/atualiza JDKs, apenas gerencia versões."
    echo "Instale manualmente um novo JDK (ex.: brew install openjdk@21) e adicione ao jenv:"
    echo "  jenv add \$(/usr/libexec/java_home -v 21)"
    return 0
  fi

  # 3) Fallback Homebrew
  if command -v brew >/dev/null 2>&1; then
    info "Atualizando Java (OpenJDK) via Homebrew…"
    brew upgrade openjdk || true
    ok "Java atualizado (Homebrew)."
    return 0
  fi

  err "Nenhum método de atualização disponível (sem SDKMAN, jenv ou brew)."
  return 1
}

doctor_tool(){
  if command -v java >/dev/null 2>&1; then
    ok "java: $(java -version 2>&1 | head -n1)"
  else
    err "Java não encontrado."
    return 1
  fi

  local jh
  jh="$(/usr/libexec/java_home -V 2>&1 || true)"
  if [[ -n "$jh" ]]; then
    ok "JDKs disponíveis (java_home -V):"
    echo "$jh"
  else
    warn "Nenhum JDK listado por /usr/libexec/java_home -V"
  fi
}