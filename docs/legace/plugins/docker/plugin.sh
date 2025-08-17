# docker — plugin easyenv
tool_name(){ echo "docker"; }
tool_provides(){ echo "versions install uninstall check"; }

# docker — plugin easyenv (Docker Desktop for Mac)

tool_install(){
  if ! brew list --cask | grep -qx docker; then
    brew install --cask docker
  else
    echo "Docker Desktop já instalado (cask)."
  fi
}
tool_uninstall(){
  if brew list --cask | grep -qx docker; then
    brew uninstall --cask docker
  else
    echo "Docker Desktop não está instalado (cask)."
  fi
}

tool_update(){
  brew upgrade --cask docker || true
}

tool_versions(){
  echo "Docker instalado:"
  if command -v docker >/dev/null 2>&1; then
    echo "  ✅ $(docker --version 2>/dev/null)"
    if docker compose version >/dev/null 2>&1; then
      echo "  docker compose: $(docker compose version 2>/dev/null | head -n1)"
    fi
  else
    echo "  ❌ docker não encontrado (abra o Docker Desktop após instalar)."
  fi
}

tool_switch(){
  echo "Troca de versão não suportada via plugin para Docker."
  return 1
}

doctor_tool(){
  if ! command -v docker >/dev/null 2>&1; then
    err "docker não encontrado. Dica: brew install --cask docker (abra o app após instalação)."
    return 1
  fi
  ok "docker: $(docker --version 2>/dev/null)"

  # Verifica daemon
  if docker info >/dev/null 2>&1; then
    ok "Docker daemon acessível."
  else
    warn "Docker daemon não acessível. Abra o Docker Desktop e aguarde iniciar."
  fi
}