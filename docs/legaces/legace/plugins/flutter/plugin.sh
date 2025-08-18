tool_name(){ echo "flutter"; }
tool_provides(){ echo "versions switch install uninstall check env"; }

tool_versions(){
  echo "Flutter (FVM):"
  local dir="$HOME/.fvm/versions"
  local active=""; [[ -L "$HOME/.fvm/default" ]] && active="$(basename "$(readlink "$HOME/.fvm/default")")"
  [[ -d "$dir" ]] || { echo "  (nenhuma versão em $dir)"; echo "  Dica: brew install fvm && fvm install stable"; return 0; }
  ls -1 "$dir" | sort -V | while read -r v; do
    [[ "$v" == "$active" ]] && printf "  \033[32m* %s (ativo)\033[0m\n" "$v" || printf "    %s\n" "$v"
  done
}
tool_install(){ brew install fvm; }
tool_uninstall(){ brew uninstall fvm || true; }
tool_check(){ command -v flutter >/dev/null 2>&1 || [[ -L "$HOME/.fvm/default" ]]; }
tool_env(){ echo 'export PATH="$HOME/.fvm/default/bin:$PATH"'; }
tool_switch(){
  local v="$1"
  [[ -z "$v" ]] && { err "Uso: easyenv switch flutter <versão>"; return 1; }
  require_cmd "fvm" "Instale fvm: brew install fvm"

  info "Instalando Flutter $v via FVM (se necessário)…"
  fvm install "$v" || true

  info "Atualizando symlink ~/.fvm/default → ~/.fvm/versions/$v"
  mkdir -p "$HOME/.fvm/versions"
  ln -sfn "$HOME/.fvm/versions/$v" "$HOME/.fvm/default"

  inject_env_and_paths "fvm"
  ok "Flutter alternado para $v."
  bash -lc 'flutter --version || true'
}

tool_update(){
  local target="${1:-}"  # opcional: ex. 3.13.9 | stable
  command -v brew >/dev/null 2>&1 && brew upgrade fvm >/dev/null 2>&1 || true

  if [[ -n "$target" ]]; then
    info "Instalando Flutter '$target' (via FVM) e ativando como default…"
    fvm install "$target" || true
    mkdir -p "$HOME/.fvm/versions"
    ln -sfn "$HOME/.fvm/versions/$target" "$HOME/.fvm/default"
    inject_env_and_paths "fvm"
    flutter --version || true
    ok "Flutter atualizado para '$target'."
  else
    info "FVM verificado. Dica: 'easyenv update flutter stable' para mover p/ canal estável."
  fi
}

doctor_tool(){
  if ! command -v flutter >/dev/null 2>&1; then
    err "Flutter não encontrado no PATH."
    echo "Dica: instale via FVM (brew install fvm) e rode: fvm install stable"
    return 1
  fi
  flutter --version || true

  # Verifica FVM
  if command -v fvm >/dev/null 2>&1; then
    ok "FVM presente."
  else
    warn "FVM ausente. Dica: brew install fvm"
  fi

  # Checa Android toolchain
  if flutter doctor -v | grep -q "Android toolchain"; then
    ok "Flutter detecta Android toolchain."
  else
    warn "Android toolchain não detectado pelo flutter doctor."
  fi

  # Executa flutter doctor resumido
  flutter doctor || true
  ok "Flutter doctor executado."
}