# Go plugin
tool_name(){ echo "go"; }
tool_provides(){ echo "versions install uninstall check"; }

# Detectores de gerenciadores
__have_asdf(){ command -v asdf >/dev/null 2>&1; }
__have_goenv(){ command -v goenv >/dev/null 2>&1; }

tool_versions(){
  echo "Go (Golang):"

  # 1) asdf tem prioridade se presente
  if __have_asdf; then
    local cur=""
    cur="$(asdf current golang 2>/dev/null | awk '{print $2}' | sed 's/^[*]//')"
    local listed=0
    while IFS= read -r v; do
      [[ -z "$v" ]] && continue
      listed=1
      if [[ "$v" == "$cur" ]]; then
        printf "  \033[32m* %s (ativo via asdf)\033[0m\n" "$v"
      else
        printf "    %s\n" "$v"
      fi
    done < <(asdf list golang 2>/dev/null | sed 's/^[[:space:]]*//')
    if (( listed==0 )); then
      if command -v go >/dev/null 2>&1; then
        printf "  \033[32m* %s (em uso — fora do asdf)\033[0m\n" "$(go version | awk '{print $3}')"
      else
        echo "  (nenhuma versão via asdf; go ausente)"
      fi
    fi
    return 0
  fi

  # 2) goenv, se presente
  if __have_goenv; then
    local cur=""; cur="$(goenv version-name 2>/dev/null || true)"
    local listed=0
    while IFS= read -r v; do
      [[ -z "$v" ]] && continue
      listed=1
      if [[ "$v" == "$cur" ]]; then
        printf "  \033[32m* %s (ativo via goenv)\033[0m\n" "$v"
      else
        printf "    %s\n" "$v"
      fi
    done < <(goenv versions --bare 2>/dev/null || true)
    if (( listed==0 )); then
      if command -v go >/dev/null 2>&1; then
        printf "  \033[32m* %s (em uso — fora do goenv)\033[0m\n" "$(go version | awk '{print $3}')"
      else
        echo "  (nenhuma versão via goenv; go ausente)"
      fi
    fi
    return 0
  fi

  # 3) Fallback: go do sistema/brew
  if command -v go >/dev/null 2>&1; then
    printf "  \033[32m* %s (em uso)\033[0m\n" "$(go version | awk '{print $3}')"
    # Dicas de gerenciadores
    echo "  (Gerenciadores opcionais: asdf plugin-add golang | brew install goenv)"
  else
    echo "  (Go ausente)  Dica: brew install go"
  fi
}

tool_install(){
  echo "Instalando Go (Homebrew)…"
  brew install go
  # Tip: GOPATH/PATH não é estritamente necessário no macOS moderno, mas pode ajudar:
  # echo 'export GOPATH="$HOME/go"' && echo 'export PATH="$GOPATH/bin:$PATH"'
}

tool_uninstall(){
  echo "Removendo Go…"
  brew uninstall go || true
}

tool_check(){
  command -v go >/dev/null 2>&1
}

tool_update(){
  local target="${1:-}"  # opcional quando usar asdf/goenv

  if command -v asdf >/dev/null 2>&1; then
    info "Atualizando Go via asdf…"
    asdf plugin update golang || true
    if [[ -n "$target" ]]; then
      asdf install golang "$target" || return 1
      asdf global golang "$target"
      go version || true
      ok "Go atualizado para $target (asdf)."
    else
      asdf list all golang | tail -n 5 || true
      info "Dica: 'easyenv update go <versão>' para instalar/ativar via asdf."
      ok "Go (asdf) verificado."
    fi
    return 0
  fi

  if command -v goenv >/dev/null 2>&1; then
    info "Atualizando Go via goenv…"
    if [[ -n "$target" ]]; then
      goenv install -s "$target" || return 1
      goenv global "$target"
      eval "$(goenv init -)" 2>/dev/null || true
      go version || true
      ok "Go atualizado para $target (goenv)."
    else
      goenv versions || true
      info "Dica: 'easyenv update go <versão>' para instalar/ativar via goenv."
      ok "Go (goenv) verificado."
    fi
    return 0
  fi

  if command -v brew >/dev/null 2>&1; then
    info "Atualizando Go (Homebrew)…"
    brew upgrade go >/dev/null 2>&1 || true
    go version || true
    ok "Go (brew) verificado/atualizado."
  else
    warn "Sem asdf/goenv/brew detectados; não há método automático de update."
  fi
}

doctor_tool(){
  if command -v go >/dev/null 2>&1; then
    ok "Go: $(go version 2>/dev/null)"
    go env GOPATH GOROOT 2>/dev/null | sed 's/^/  /'
  else
    err "Go não encontrado. Dica: brew install go"
    return 1
  fi
}