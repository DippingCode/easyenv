# Kotlin plugin
tool_name(){ echo "kotlin"; }
tool_provides(){ echo "versions install uninstall check"; }

tool_versions(){
  echo "Kotlin:"
  if ! command -v kotlinc >/dev/null 2>&1; then
    echo "  (kotlin ausente)  Dica: brew install kotlin ou sdkman install kotlin"
    return 0
  fi
  local ver
  ver="$(kotlinc -version 2>&1 | grep -Eo '[0-9]+\.[0-9]+\.[0-9]+')"
  [[ -n "$ver" ]] && printf "  \033[32m* %s (em uso)\033[0m\n" "$ver" || echo "  (não foi possível determinar a versão)"
}
tool_install(){ brew install kotlin; }
tool_uninstall(){ brew uninstall kotlin || true; }
tool_check(){ command -v kotlinc >/dev/null 2>&1; }

tool_update(){
  if [[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]]; then
    # shellcheck source=/dev/null
    source "$HOME/.sdkman/bin/sdkman-init.sh"
    info "Atualizando Kotlin via SDKMAN…"
    sdk update || true
    sdk upgrade kotlin || true
    ok "Kotlin atualizado (SDKMAN)."
    return 0
  fi

  if command -v brew >/dev/null 2>&1; then
    info "Atualizando Kotlin via Homebrew…"
    brew upgrade kotlin >/dev/null 2>&1 || true
    ok "Kotlin atualizado (Homebrew)."
    return 0
  fi

  warn "Nenhum gerenciador encontrado (SDKMAN/brew)."
}

doctor_tool(){
  if command -v kotlinc >/dev/null 2>&1; then
    ok "kotlinc: $(kotlinc -version 2>&1 | head -n1)"
  else
    warn "kotlinc não encontrado. Dica: brew install kotlin ou sdkman."
  fi

  if command -v kotlin >/dev/null 2>&1; then
    ok "kotlin: $(kotlin -version 2>&1 | head -n1)"
  else
    warn "kotlin (runner) não encontrado."
  fi
}