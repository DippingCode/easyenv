# supabase — plugin easyenv (Supabase CLI)
tool_name(){ echo "supabase"; }
tool_provides(){ echo "versions install uninstall check"; }

tool_install(){
  # tap oficial
  brew tap supabase/tap || true
  if ! brew list --formula | grep -qx supabase; then
    brew install supabase/tap/supabase
  else
    echo "supabase já instalado (brew)."
  fi
}
tool_uninstall(){
  if brew list --formula | grep -qx supabase; then
    brew uninstall supabase
  else
    echo "supabase não está instalado (brew)."
  fi
}

tool_update(){
  brew tap supabase/tap || true
  brew upgrade supabase/tap/supabase || true
}

tool_versions(){
  echo "Supabase CLI:"
  if command -v supabase >/dev/null 2>&1; then
    echo "  ✅ $(supabase --version 2>/dev/null | head -n1)"
  else
    echo "  ❌ supabase não encontrado (brew install supabase/tap/supabase)"
  fi
}

tool_switch(){
  echo "Troca de versão via brew possível (brew install supabase@<versão> se disponível), sem automação aqui."
  return 1
}

doctor_tool(){
  if command -v supabase >/dev/null 2>&1; then
    ok "supabase: $(supabase --version 2>/dev/null | head -n1)"
  else
    err "Supabase CLI não encontrado. Dica: brew install supabase/tap/supabase"
    return 1
  fi

  # Supabase local depende de Docker
  if command -v docker >/dev/null 2>&1; then
    if docker info >/dev/null 2>&1; then
      ok "Docker disponível para supabase local."
    else
      warn "Docker presente mas daemon indisponível."
    fi
  else
    warn "Docker não encontrado — necessário para 'supabase start' local."
  fi
}