tool_name(){ echo "python"; }
tool_provides(){ echo "versions switch install uninstall check"; }

tool_versions(){
  echo "Python:"
  if command -v pyenv >/dev/null 2>&1; then
    local cur; cur="$(pyenv version-name 2>/dev/null || echo "")"
    local -a vers=(); while IFS= read -r v; do [[ -n "$v" ]] && vers+=("$v"); done < <(pyenv versions --bare 2>/dev/null)
    if (( ${#vers[@]} )); then
      for v in "${vers[@]}"; do
        [[ "$v" == "$cur" ]] && printf "  \033[32m* %s (ativo)\033[0m\n" "$v" || printf "    %s\n" "$v"
      done
    else
      echo "  (nenhuma versão instalada no pyenv)"
    fi
    local sys=""; command -v python3 >/dev/null 2>&1 && sys="$(python3 -V 2>/dev/null | awk '{print $2}')"
    [[ -n "$sys" ]] && { [[ "$cur" == "system" || -z "$cur" ]] && printf "  \033[32m* system (%s) (ativo)\033[0m\n" "$sys" || echo "    system ($sys)"; }
    return 0
  fi
  if command -v python3 >/dev/null 2>&1; then
    local v; v="$(python3 -V 2>/dev/null | awk '{print $2}')"
    printf "  \033[32m* %s (em uso — sem pyenv)\033[0m\n" "$v"
    echo "  Dica: brew install pyenv"
  else
    echo "  (Python ausente)  Dica: brew install python ou brew install pyenv"
  fi
}
tool_install(){ brew install pyenv; }
tool_uninstall(){ brew uninstall pyenv || true; }
tool_check(){ command -v python3 >/dev/null 2>&1 || command -v pyenv >/dev/null 2>&1; }

tool_update(){
  local target="${1:-}"  # opcional: ex. 3.12.5

  if command -v pyenv >/dev/null 2>&1; then
    info "Atualizando pyenv (Homebrew)…"
    command -v brew >/dev/null 2>&1 && brew upgrade pyenv >/dev/null 2>&1 || true

    if [[ -n "$target" ]]; then
      info "Instalando Python $target via pyenv e definindo como global…"
      pyenv install -s "$target" || return 1
      pyenv global "$target"
      pyenv rehash || true
      python3 -V || true
      ok "Python atualizado para $target (pyenv)."
    else
      info "Dica: 'easyenv update python 3.x.y' para instalar e ativar uma versão específica via pyenv."
      pyenv --version || true
    fi
    return 0
  fi

  if command -v brew >/dev/null 2>&1; then
    info "Atualizando python via Homebrew…"
    brew upgrade python >/dev/null 2>&1 || true
    python3 -V || true
    ok "Python (brew) verificado/atualizado."
  else
    warn "Sem pyenv e sem brew. Não há método automático de update disponível."
  fi
}

doctor_tool(){
  command -v python3 >/dev/null 2>&1 && ok "Python3: $(python3 --version 2>/dev/null)" || warn "Python3 não encontrado."
  command -v pip3    >/dev/null 2>&1 && ok "pip3: $(pip3 --version 2>/dev/null)"       || warn "pip3 não encontrado."

  if command -v pyenv >/dev/null 2>&1; then
    ok "pyenv presente."
    local cur v
    cur="$(pyenv version-name 2>/dev/null || true)"
    v="$(pyenv versions --bare 2>/dev/null | sed 's/^/   /')"
    [[ -n "$cur" ]] && ok "pyenv atual: $cur"
    [[ -n "$v" ]] && echo "Versões pyenv:\n$v"
  else
    warn "pyenv ausente. Dica: brew install pyenv"
  fi
}