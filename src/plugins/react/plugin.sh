
#!/usr/bin/env bash
# EasyEnv plugin: react (frontend scaffold via create-vite)
# Interface esperada:
#   tool_versions, tool_install, tool_uninstall, tool_update, tool_switch,
#   tool_doctor, tool_paths, tool_env

tool_name(){ echo "react"; }
tool_provides(){ echo "versions switch install uninstall check"; }


set -euo pipefail

# ---------- helpers locais ----------
_have(){ command -v "$1" >/dev/null 2>&1; }

# ---------- versions ----------
tool_versions(){
  echo "React (via create-vite):"
  local nodev npmv vitver
  nodev="$({ node -v 2>/dev/null || true; })"
  npmv="$({ npm -v 2>/dev/null || true; })"

  if _have create-vite; then
    vitver="$(create-vite --version 2>/dev/null || true)"
    echo "  ✅ create-vite ${vitver:-"(versão indisponível)"}"
  else
    # tentar detectar versão instalada globalmente via npm
    local raw
    raw="$(npm list -g create-vite --depth=0 2>/dev/null || true)"
    if grep -q 'create-vite@' <<<"$raw"; then
      echo "  ✅ $(echo "$raw" | grep 'create-vite@' | head -n1 | sed 's/.*create-vite@/create-vite /')"
    else
      echo "  ❌ create-vite não encontrado (npm global)."
    fi
  fi

  if [[ -n "${nodev:-}" ]]; then
    echo "  ℹ️  Node: $nodev"
  else
    echo "  ❌ Node não encontrado (recomendado NVM)."
  fi
  [[ -n "${npmv:-}" ]] && echo "  ℹ️  npm: $npmv" || echo "  ❌ npm não encontrado."

  echo
  echo "Dicas rápidas:"
  echo "  • Criar app: npm create vite@latest meu-app -- --template react"
  echo "  • Rodar:     cd meu-app && npm i && npm run dev"
}

# ---------- install ----------
tool_install(){
  if ! _have npm; then
    echo "❌ npm não encontrado. Instale Node/NVM antes."; return 1
  fi
  echo "⬇️  Instalando create-vite globalmente…"
  npm install -g create-vite
  return 0
}

# ---------- uninstall ----------
tool_uninstall(){
  if ! _have npm; then
    echo "⚠️  npm não encontrado — nada a remover."; return 0
  fi
  echo "🧹 Removendo create-vite (npm -g)…"
  npm uninstall -g create-vite || true
  return 0
}

# ---------- update ----------
tool_update(){
  if ! _have npm; then
    echo "❌ npm não encontrado. Instale Node/NVM antes."; return 1
  fi
  echo "🔁 Atualizando create-vite para a última versão…"
  npm install -g create-vite@latest
  return 0
}

# ---------- switch (não aplicável) ----------
tool_switch(){
  echo "ℹ️  React (create-vite) não possui 'switch' de versão por projeto via EasyEnv."
  echo "    Use projeto a projeto com package.json / lockfile."
  return 0
}

# ---------- doctor ----------
tool_doctor(){
  local ok=1
  if ! _have node; then
    echo "❌ Node ausente. Sugestão: brew install nvm && configure o NVM."
    ok=0
  fi
  if ! _have npm; then
    echo "❌ npm ausente. (vem com Node)."
    ok=0
  fi
  if ! _have create-vite; then
    echo "❌ create-vite ausente. Rode: npm install -g create-vite"
    ok=0
  fi
  if (( ok==1 )); then
    echo "✅ React toolchain OK (Node/npm/create-vite)."
  fi
  return $(( ok==1 ? 0 : 1 ))
}

# ---------- paths/env (não necessário) ----------
tool_paths(){ return 0; }
tool_env(){ return 0; }