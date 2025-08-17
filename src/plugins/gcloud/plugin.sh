# gcloud — plugin easyenv (Google Cloud SDK)
tool_name(){ echo "gcloud"; }
tool_provides(){ echo "versions install uninstall check"; }

tool_install(){
  if ! brew list --cask | grep -qx google-cloud-sdk; then
    brew install --cask google-cloud-sdk
  else
    echo "google-cloud-sdk já instalado (cask)."
  fi
}
tool_uninstall(){
  if brew list --cask | grep -qx google-cloud-sdk; then
    brew uninstall --cask google-cloud-sdk
  else
    echo "google-cloud-sdk não está instalado (cask)."
  fi
}

tool_update(){
  brew upgrade --cask google-cloud-sdk || true
}

tool_versions(){
  echo "gcloud instalado:"
  if command -v gcloud >/dev/null 2>&1; then
    echo "  ✅ $(gcloud --version 2>/dev/null | head -n1)"
  else
    echo "  ❌ gcloud não encontrado"
  fi
}

tool_switch(){
  echo "Troca de versão não suportada via plugin para gcloud."
  return 1
}

doctor_tool(){
  # Verifica binário
  if command -v gcloud >/dev/null 2>&1; then
    ok "gcloud: $(gcloud --version 2>/dev/null | head -n1)"
  else
    err "gcloud não encontrado. Dica: brew install --cask google-cloud-sdk"
    return 1
  fi

  # Conta autenticada ativa?
  local active_acct
  active_acct="$(gcloud auth list --filter=status:ACTIVE --format='value(account)' 2>/dev/null | head -n1 || true)"
  if [[ -n "$active_acct" ]]; then
    ok "Conta autenticada: $active_acct"
  else
    warn "Nenhuma conta ativa. Dica: gcloud auth login"
  fi

  # Projeto padrão (se configurado)
  local def_proj
  def_proj="$(gcloud config get-value core/project 2>/dev/null || true)"
  if [[ -n "$def_proj" ]]; then
    ok "Projeto padrão: $def_proj"
  else
    warn "Sem projeto padrão. Dica: gcloud config set project <PROJECT_ID>"
  fi
}