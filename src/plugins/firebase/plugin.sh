# firebase — plugin easyenv (Firebase CLI)
tool_name(){ echo "firebase"; }
tool_provides(){ echo "versions install uninstall check"; }

tool_install(){
  if command -v npm >/dev/null 2>&1; then
    npm install -g firebase-tools
  else
    echo "npm não encontrado. Instale Node/NPM primeiro."
    return 1
  fi
}
tool_uninstall(){
  if command -v npm >/dev/null 2>&1; then
    npm rm -g firebase-tools || true
  fi
}

tool_update(){
  if command -v npm >/dev/null 2>&1; then
    npm install -g firebase-tools || true
  fi
}

tool_versions(){
  echo "Firebase CLI:"
  if command -v firebase >/dev/null 2>&1; then
    echo "  ✅ $(firebase --version 2>/dev/null)"
  else
    echo "  ❌ firebase não encontrado (npm i -g firebase-tools)"
  fi
}

tool_switch(){
  echo "Troca de versão via npm possível (npm i -g firebase-tools@<versão>), mas sem automação aqui."
  return 1
}

doctor_tool(){
  if command -v firebase >/dev/null 2>&1; then
    ok "firebase: $(firebase --version 2>/dev/null)"
  else
    err "Firebase CLI não encontrado. Dica: npm i -g firebase-tools"
    return 1
  fi

  # Verifica login (pode abrir navegador; aqui só lista se houver)
  firebase login:list >/dev/null 2>&1 && ok "Conta(s) autenticada(s) detectada(s)." || warn "Nenhuma conta autenticada (execute: firebase login)."
}