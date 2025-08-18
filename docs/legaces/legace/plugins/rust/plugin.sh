# Rust plugin
tool_name(){ echo "rust"; }
tool_provides(){ echo "versions switch install uninstall check update"; }

tool_versions(){
  echo "Rust (rustup):"
  if command -v rustup >/dev/null 2>&1; then
    # Ex.: 
    # stable-aarch64-apple-darwin (default)
    # nightly-aarch64-apple-darwin (override)
    # 1.80.1-x86_64-unknown-linux-gnu (profile set via custom toolchain names)
    rustup toolchain list 2>/dev/null | sed 's/^/    /'
    # destacar a default
    local def
    def="$(rustup default 2>/dev/null | awk '{print $1}')"
    if [[ -n "$def" ]]; then
      printf "  \033[32m* %s (ativo)\033[0m\n" "$def"
    fi
    return 0
  fi

  # Sem rustup, tenta rustc direto
  if command -v rustc >/dev/null 2>&1; then
    local v; v="$(rustc --version 2>/dev/null | awk '{print $2}')"
    printf "  \033[32m* rustc %s (em uso — sem rustup)\033[0m\n" "$v"
    echo "  (Gerenciador recomendado: rustup-init)"
  else
    echo "  (Rust ausente)  Dica: brew install rustup-init && rustup-init -y"
  fi
}

tool_switch(){
  local chain="${1:-}"
  [[ -z "$chain" ]] && { echo "Uso: easyenv switch rust <toolchain>"; echo "Ex.: stable, nightly, 1.78.0"; return 1; }
  if ! command -v rustup >/dev/null 2>&1; then
    echo "rustup ausente. Dica: brew install rustup-init && rustup-init -y"
    return 1
  fi
  rustup toolchain install "$chain" -y
  rustup default "$chain"
  rustc --version || true
}

tool_install(){
  if command -v rustup >/dev/null 2>&1; then
    echo "rustup já instalado."
    return 0
  fi
  echo "Instalando rustup (Homebrew)…"
  brew install rustup-init
  echo "Executando rustup-init -y …"
  rustup-init -y
}

tool_uninstall(){
  echo "Removendo Rust (rustup)…"
  rustup self uninstall -y || true
  brew uninstall rustup-init || true
}

tool_update(){
  if command -v rustup >/dev/null 2>&1; then
    rustup self update || true
    rustup update || true
  else
    brew upgrade rust || true
  fi
}

tool_check(){
  command -v rustc >/dev/null 2>&1 || command -v rustup >/dev/null 2>&1
}

doctor_tool(){
  if command -v rustc >/dev/null 2>&1; then
    ok "rustc: $(rustc --version 2>/dev/null)"
  else
    warn "rustc não encontrado."
  fi

  if command -v cargo >/dev/null 2>&1; then
    ok "cargo: $(cargo --version 2>/dev/null)"
  else
    warn "cargo não encontrado."
  fi

  if command -v rustup >/dev/null 2>&1; then
    ok "rustup presente."
    rustup show 2>/dev/null | sed 's/^/  /' || true
  else
    warn "rustup ausente. Dica: brew install rustup-init && rustup-init -y"
  fi
}