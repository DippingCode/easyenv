# aws-cli — plugin easyenv
tool_name(){ echo "aws"; }
tool_provides(){ echo "versions install uninstall check"; }

tool_install(){
  if ! brew list --formula | grep -qx awscli; then
    brew install awscli
  else
    echo "awscli já instalado (brew)."
  fi
}
tool_uninstall(){
  if brew list --formula | grep -qx awscli; then
    brew uninstall awscli
  else
    echo "awscli não está instalado (brew)."
  fi
}

tool_update(){
  brew upgrade awscli || true
}

tool_versions(){
  echo "AWS CLI instalado:"
  if command -v aws >/dev/null 2>&1; then
    echo "  ✅ $(aws --version 2>&1 | head -n1)"
  else
    echo "  ❌ aws não encontrado"
  fi
}

tool_switch(){
  echo "Troca de versão não suportada via plugin para AWS CLI."
  return 1
}

doctor_tool(){
  if command -v aws >/dev/null 2>&1; then
    ok "aws: $(aws --version 2>&1 | head -n1)"
  else
    err "aws CLI não encontrada. Dica: brew install awscli"
    return 1
  fi

  # Credenciais?
  if aws sts get-caller-identity >/dev/null 2>&1; then
    ok "Credenciais válidas (STS ok)."
  else
    warn "Sem credenciais válidas. Dica: aws configure"
  fi
}