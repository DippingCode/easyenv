# Node plugin
tool_name(){ echo "node"; }
tool_provides(){ echo "versions switch install uninstall check update"; }

__nvm_sh(){
  for cand in "/opt/homebrew/opt/nvm/nvm.sh" "/usr/local/opt/nvm/nvm.sh" "$HOME/.nvm/nvm.sh"; do
    [[ -s "$cand" ]] && { echo "$cand"; return 0; }
  done; return 1
}

tool_versions(){
  echo "Node (NVM):"
  local nvm_sh; nvm_sh="$(__nvm_sh)" || {
    if command -v node >/dev/null 2>&1; then
      local cur; cur="$(node -v 2>/dev/null | sed 's/^v//')"
      [[ -n "$cur" ]] && printf "  \033[32m* %s (em uso — fora do NVM)\033[0m\n" "$cur" || echo "  (Node ausente)"
      echo "  Dica: brew install nvm"
      return 0
    fi
    echo "  (NVM e Node ausentes)  Dica: brew install nvm"
    return 0
  }
  local out cur list
  out="$(bash --noprofile --norc -c ". \"$nvm_sh\"; cur=\$(nvm current || echo none); nvm ls --no-colors \
        | sed -n 's/^[^v]*v\\([0-9]\\+\\.[0-9]\\+\\.[0-9]\\+\\).*/\\1/p' | sort -Vu; echo __CURRENT__:\$cur")"
  cur="$(printf "%s\n" "$out" | awk -F: '/^__CURRENT__:/ {print $2}' | sed 's/^v//')"
  list="$(printf "%s\n" "$out" | grep -v '^__CURRENT__:' || true)"
  if [[ -z "$list" ]]; then
    local sys="$(node -v 2>/dev/null | sed 's/^v//')"
    [[ -n "$sys" ]] && printf "  \033[32m* %s (em uso — fora do NVM)\033[0m\n" "$sys"
    echo "  (NVM não possui versões instaladas. Dica: nvm install --lts)"
    return 0
  fi
  while read -r v; do
    [[ -z "$v" ]] && continue
    [[ "$v" == "$cur" ]] && printf "  \033[32m* %s (ativo)\033[0m\n" "$v" || printf "    %s\n" "$v"
  done <<< "$list"
}

tool_install(){ brew install nvm; mkdir -p "$HOME/.nvm"; }
tool_uninstall(){ brew uninstall nvm || true; }
tool_check(){ command -v node >/dev/null 2>&1; }
tool_update(){ brew upgrade nvm || true; }

tool_switch(){
  local v="$1"
  [[ -z "$v" ]] && { err "Uso: easyenv switch node <versão|lts>"; return 1; }

  local nvmpath="/opt/homebrew/opt/nvm/nvm.sh"
  for cand in "$nvmpath" "/usr/local/opt/nvm/nvm.sh" "$HOME/.nvm/nvm.sh"; do
    [[ -s "$cand" ]] && nvmpath="$cand" && break
  done
  [[ -s "$nvmpath" ]] || { err "NVM não encontrado. Instale: brew install nvm"; return 1; }

  info "Alternando Node para '$v' via NVM…"
  bash -lc ". \"$nvmpath\" && nvm install \"$v\" && nvm alias default \"$v\" && nvm use default && node -v && npm -v" \
    || { err "Falha ao alternar Node"; return 1; }

  ok "Node alternado para '$v'."
}

tool_update(){
  local target="${1:-}"  # opcional: lts | <versão>

  # atualizar nvm (se instalado via brew)
  command -v brew >/dev/null 2>&1 && brew upgrade nvm >/dev/null 2>&1 || true

  # localizar nvm.sh
  local nvmpath="/opt/homebrew/opt/nvm/nvm.sh"
  for cand in "$nvmpath" "/usr/local/opt/nvm/nvm.sh" "$HOME/.nvm/nvm.sh"; do
    [[ -s "$cand" ]] && nvmpath="$cand" && break
  done
  if [[ -s "$nvmpath" ]]; then
    if [[ -n "$target" ]]; then
      info "Atualizando/instalando Node '$target' e definindo como default (via NVM)…"
      bash -lc ". \"$nvmpath\"; nvm install \"$target\"; nvm alias default \"$target\"; nvm use default; node -v; npm -v" || return 1
      ok "Node atualizado para '$target'."
    else
      info "NVM disponível. Dica: 'easyenv update node lts' para mover p/ última LTS."
      bash -lc ". \"$nvmpath\"; nvm --version; nvm ls-remote --lts | tail -n 5" || true
      ok "NVM verificado."
    fi
    return 0
  fi

  # sem NVM → apenas informar node atual
  if command -v node >/dev/null 2>&1; then
    warn "NVM ausente; atualize o Node via brew: brew upgrade node"
  else
    warn "Node não encontrado. Dica: brew install nvm && reinicie o shell."
  fi
}

doctor_tool(){
  command -v node >/dev/null 2>&1 && ok "Node: $(node -v)" || { err "Node não encontrado."; return 1; }
  command -v npm  >/dev/null 2>&1 && ok "NPM: $(npm -v)"    || warn "NPM não encontrado."
  local nvmsh="/opt/homebrew/opt/nvm/nvm.sh"
  [[ -s "$nvmsh" ]] && ok "NVM instalado." || warn "NVM ausente. Dica: brew install nvm"
}