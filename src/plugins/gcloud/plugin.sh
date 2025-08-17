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
  if command -v gcloud >/dev/null 2;&1; then
    ok "gcloud: $(gcloud --version 2>/dev/null | head -n1)"
  else
    err "gcloud não encontrado. Dica: brew install --cask google-cloud-sdk"
    return 1
  fi

  # Autenticação ativa?
  if gcloud auth list --filter=status:ACTIVE --format="value(account)" >/dev/null 2>&1; then
    ok "Conta autenticada detectada."
  else
    warn "Nenhuma conta ativa. Dica: gcloud auth login"
  fi
}