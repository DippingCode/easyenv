tool_name(){ echo "dotnet"; }
tool_provides(){ echo "versions switch install uninstall check"; }

tool_versions(){
  echo ".NET SDKs:"
  mapfile -t sdks < <(dotnet --list-sdks 2>/dev/null | awk '{print $1}')
  local active=""
  if [[ -f "./global.json" ]]; then active="$(jq -r '.sdk.version' ./global.json 2>/dev/null)"
  elif [[ -f "$HOME/global.json" ]]; then active="$(jq -r '.sdk.version' "$HOME/global.json" 2>/dev/null)"
  else active="$(dotnet --version 2>/dev/null)"; fi
  if (( ${#sdks[@]} == 0 )); then echo "  (nenhum SDK encontrado)"; return 0; fi
  for v in "${sdks[@]}"; do
    [[ "$v" == "$active" ]] && printf "  \033[32m* %s (em uso)\033[0m\n" "$v" || printf "    %s\n" "$v"
  done
}
tool_install(){ brew install dotnet || brew install --cask dotnet-sdk; }
tool_uninstall(){ brew uninstall dotnet || brew uninstall --cask dotnet-sdk || true; }
tool_check(){ dotnet --version >/dev/null 2>&1; }
tool_switch(){
  local v="$1"; shift || true
  [[ -z "$v" ]] && { err "Uso: easyenv switch dotnet <versão> [--scope here|global]"; return 1; }

  local scope="here"
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --scope) shift; scope="${1:-here}" ;;
    esac
    shift || true
  done

  local have=0
  while IFS= read -r sdk; do
    [[ "$sdk" == "$v"* ]] && have=1
  done < <(dotnet --list-sdks 2>/dev/null | awk '{print $1}')

  if (( have==0 )); then
    warn "SDK .NET $v não encontrado localmente."
    echo "Sugestão: curl -fsSL https://dot.net/v1/dotnet-install.sh | bash -s -- -Version $v"
  fi

  local target
  case "$scope" in
    here)   target="$PWD/global.json" ;;
    global) target="$HOME/global.json" ;;
    *) err "scope inválido: $scope"; return 1 ;;
  esac

  info "Escrevendo $target com SDK $v…"
  mkdir -p "$(dirname "$target")"
  cat > "$target" <<JSON
{
  "sdk": {
    "version": "$v",
    "rollForward": "latestFeature",
    "allowPrerelease": false
  }
}
JSON

  ok ".NET fixado em $v (scope: $scope)."
  dotnet --info | head -n 15 || true
}

tool_update(){
  # tentar atualizar via brew (cask ou formula)
  if command -v brew >/dev/null 2>&1; then
    info "Atualizando .NET via Homebrew…"
    brew upgrade --cask dotnet-sdk >/dev/null 2>&1 || brew upgrade dotnet >/dev/null 2>&1 || true
  fi

  # dicas de atualização granular
  if command -v dotnet >/dev/null 2>&1; then
    info "Verificando SDKs .NET instalados… (dotnet --list-sdks)"
    dotnet --list-sdks | tail -n +1 || true
    info "Para um SDK exato, use o instalador oficial:"
    echo "  curl -fsSL https://dot.net/v1/dotnet-install.sh | bash -s -- -Version <SDK>"
    ok ".NET verificado/atualizado."
  else
    warn ".NET não encontrado. Dica: brew install --cask dotnet-sdk"
  fi
}

doctor_tool(){
  if ! command -v dotnet >/dev/null 2>&1; then
    err ".NET SDK não encontrado. Dica: brew install --cask dotnet-sdk"
    return 1
  fi

  ok "dotnet: $(dotnet --version 2>/dev/null)"
  echo "SDKs instalados:"
  dotnet --list-sdks 2>/dev/null | sed 's/^/  - /' || true

  if [[ -f "./global.json" ]]; then
    ok "global.json encontrado no diretório atual."
    cat ./global.json
  else
    warn "Sem global.json no diretório atual (opcional para fixar versão)."
  fi
}