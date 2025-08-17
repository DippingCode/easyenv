tool_name(){ echo "deno"; }
tool_provides(){ echo "versions install uninstall check"; }
tool_versions(){
  echo "Deno:"
  if command -v deno >/dev/null 2>&1; then
    local v; v="$(deno --version 2>/dev/null | awk '/^deno /{print $2}')"
    [[ -n "$v" ]] && printf "  \033[32m* %s (em uso)\033[0m\n" "$v" || echo "  (não foi possível ler a versão)"
  else
    echo "  (deno ausente)  Dica: brew install deno"
  fi
}
tool_install(){ brew install deno; }
tool_uninstall(){ brew uninstall deno || true; }
tool_check(){ command -v deno >/dev/null 2>&1; }

tool_update(){
  if command -v deno >/dev/null 2>&1; then
    info "Atualizando Deno…"
    # preferir atualizador próprio
    deno upgrade || true
    # se foi instalado via brew:
    command -v brew >/dev/null 2>&1 && brew upgrade deno >/dev/null 2>&1 || true
    deno --version || true
    ok "Deno atualizado."
  else
    warn "Deno não encontrado. Dica: brew install deno"
  fi
}

doctor_tool(){
  if command -v deno >/dev/null 2>&1; then
    ok "Deno: $(deno --version 2>/dev/null | head -n1)"
  else
    err "Deno não encontrado. Dica: brew install deno"
    return 1
  fi
}