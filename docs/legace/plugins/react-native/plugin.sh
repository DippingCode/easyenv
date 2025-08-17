#!/usr/bin/env bash
# EasyEnv plugin: react-mobile (React Native CLI + setup Android/iOS)
# Interface:
#   tool_versions, tool_install, tool_uninstall, tool_update,
#   tool_switch, tool_doctor, tool_paths, tool_env


tool_name(){ echo "react-native"; }
tool_provides(){ echo "versions switch install uninstall check"; }

set -euo pipefail

_have(){ command -v "$1" >/dev/null 2>&1; }

# ---------- versions ----------
tool_versions(){
  echo "React Native (react-mobile):"
  local nodev npmv yarnv
  nodev="$({ node -v 2>/dev/null || true; })"
  npmv="$({ npm -v 2>/dev/null || true; })"
  yarnv="$({ yarn -v 2>/dev/null || true; })"

  if _have react-native; then
    echo "  ✅ $(react-native --version 2>/dev/null || echo "react-native-cli instalado")"
  else
    echo "  ❌ react-native CLI não encontrado (use npx ou npm -g)."
  fi

  [[ -n "$nodev" ]] && echo "  ℹ️ Node: $nodev" || echo "  ❌ Node ausente"
  [[ -n "$npmv" ]] && echo "  ℹ️ npm: $npmv"   || echo "  ❌ npm ausente"
  [[ -n "$yarnv" ]] && echo "  ℹ️ yarn: $yarnv" || echo "  ⚠️ yarn não encontrado (opcional)"
  
  echo
  echo "Criação de projeto:"
  echo "  npx react-native init MeuApp"
  echo "Rodar:"
  echo "  cd MeuApp && npx react-native run-ios"
  echo "  cd MeuApp && npx react-native run-android"
}

# ---------- install ----------
tool_install(){
  if ! _have npm; then
    echo "❌ npm não encontrado. Instale Node/NVM antes."; return 1
  fi
  echo "⬇️ Instalando react-native CLI global…"
  npm install -g react-native-cli
  return 0
}

# ---------- uninstall ----------
tool_uninstall(){
  if _have npm; then
    echo "🧹 Removendo react-native-cli global…"
    npm uninstall -g react-native-cli || true
  else
    echo "⚠️ npm não encontrado — nada a remover."
  fi
  return 0
}

# ---------- update ----------
tool_update(){
  if ! _have npm; then
    echo "❌ npm não encontrado."; return 1
  fi
  echo "🔁 Atualizando react-native-cli global…"
  npm install -g react-native-cli@latest
  return 0
}

# ---------- switch (não aplicável) ----------
tool_switch(){
  echo "ℹ️ React Native não possui switch global. Use nvm para alternar Node."
  return 0
}

# ---------- doctor ----------
tool_doctor(){
  local ok=1
  if ! _have node; then
    echo "❌ Node ausente."; ok=0
  fi
  if ! _have npm; then
    echo "❌ npm ausente."; ok=0
  fi
  if ! _have java; then
    echo "❌ Java (JDK) ausente. Necessário para Android."; ok=0
  fi
  if ! _have adb; then
    echo "❌ Android SDK/adb ausente. Configure $ANDROID_HOME."; ok=0
  fi
  if ! _have pod; then
    echo "⚠️ CocoaPods ausente. Necessário para iOS: gem install cocoapods"; ok=0
  fi
  if (( ok==1 )); then
    echo "✅ React Native toolchain OK."
  else
    echo "⚠️ Problemas encontrados no ambiente React Native."
  fi
  return $(( ok==1 ? 0 : 1 ))
}

# ---------- paths/env ----------
tool_paths(){
  # Android SDK e Xcode (já podem estar no .zshrc default)
  echo "Adicionar Android SDK ao PATH (se não estiver):"
  echo "  export ANDROID_HOME=\$HOME/Library/Android/sdk"
  echo "  export PATH=\$ANDROID_HOME/platform-tools:\$PATH"
}

tool_env(){ return 0; }