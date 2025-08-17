# Angular plugin
tool_name(){ echo "angular"; }
tool_provides(){ echo "versions install uninstall check"; }

tool_versions(){
  echo "Angular CLI:"
  if ! command -v ng >/dev/null 2>&1; then
    echo "  (ng ausente)  Dica: npm install -g @angular/cli"
    return 0
  fi
  local ver
  ver="$(ng version 2>/dev/null | grep -Eo 'Angular CLI:[[:space:]]*[0-9]+\.[0-9]+\.[0-9]+' | awk '{print $3}')"
  [[ -z "$ver" ]] && ver="$(ng version 2>/dev/null | sed -n 's/^Angular CLI:[[:space:]]*//p' | head -n1)"
  [[ -n "$ver" ]] && printf "  \033[32m* %s (em uso)\033[0m\n" "$ver" || echo "  (não foi possível determinar a versão)"
}
tool_install(){ npm install -g @angular/cli; }
tool_uninstall(){ npm remove -g @angular/cli || true; }
tool_check(){ command -v ng >/dev/null 2>&1; }

tool_update(){
  if command -v ng >/dev/null 2>&1; then
    info "Atualizando Angular CLI (npm)…"
    npm update -g @angular/cli || npm install -g @angular/cli || true
    ng version || true
    ok "Angular CLI atualizado."
  else
    warn "Angular CLI não encontrado. Dica: npm install -g @angular/cli"
  fi
}

doctor_tool(){
  if command -v ng >/dev/null 2>&1; then
    ok "Angular CLI: $(ng version 2>/dev/null | head -n1)"
  else
    err "Angular CLI não encontrado. Dica: npm i -g @angular/cli"
    return 1
  fi

  command -v node >/dev/null 2>&1 && ok "Node: $(node -v)" || warn "Node não encontrado."
  command -v npm  >/dev/null 2>&1 && ok "NPM: $(npm -v)"   || warn "NPM não encontrado."
}