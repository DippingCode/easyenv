#!/usr/bin/env bash
# Android plugin — SDK/CLI/Studio/AVDs (macOS/arm64 friendly)
# Requisitos do core: info, ok, warn, err, confirm, append_once (utils.sh)

tool_name(){ echo "android"; }
tool_provides(){ echo "versions install update uninstall check switch avd"; }

# ===========================
# Helpers internos
# ===========================

__android_default_sdk_root(){
  # preferir SDK do usuário criado pelo Android Studio
  if [[ -d "$HOME/Library/Android/sdk" ]]; then
    echo "$HOME/Library/Android/sdk"; return 0
  fi
  # fallback: diretório do brew commandlinetools (vamos replicar estrutura)
  if [[ -d "/opt/homebrew/share/android-commandlinetools" ]]; then
    echo "$HOME/Library/Android/sdk"; return 0
  fi
  echo "$HOME/Library/Android/sdk"
}

__sdkmanager_path(){
  local cands=(
    "$ANDROID_SDK_ROOT/cmdline-tools/latest/bin/sdkmanager"
    "$ANDROID_SDK_ROOT/cmdline-tools/bin/sdkmanager"
    "$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager"
    "$ANDROID_HOME/cmdline-tools/bin/sdkmanager"
    "/opt/homebrew/share/android-commandlinetools/cmdline-tools/latest/bin/sdkmanager"
    "/opt/homebrew/share/android-commandlinetools/cmdline-tools/bin/sdkmanager"
  )
  local x
  for x in "${cands[@]}"; do
    [[ -x "$x" ]] && { echo "$x"; return 0; }
  done
  echo ""
}

__avdmanager_path(){
  local base="${ANDROID_SDK_ROOT:-$HOME/Library/Android/sdk}"
  local cands=(
    "$base/cmdline-tools/latest/bin/avdmanager"
    "$base/cmdline-tools/bin/avdmanager"
    "/opt/homebrew/share/android-commandlinetools/cmdline-tools/latest/bin/avdmanager"
    "/opt/homebrew/share/android-commandlinetools/cmdline-tools/bin/avdmanager"
  )
  local x
  for x in "${cands[@]}"; do
    [[ -x "$x" ]] && { echo "$x"; return 0; }
  done
  echo ""
}

__adb_path(){
  local base="${ANDROID_SDK_ROOT:-$HOME/Library/Android/sdk}"
  local cands=(
    "$base/platform-tools/adb"
    "$ANDROID_HOME/platform-tools/adb"
    "$HOME/Library/Android/sdk/platform-tools/adb"
  )
  local x
  for x in "${cands[@]}"; do
    [[ -x "$x" ]] && { echo "$x"; return 0; }
  done
  echo ""
}

__emulator_path(){
  local base="${ANDROID_SDK_ROOT:-$HOME/Library/Android/sdk}"
  local cands=(
    "$base/emulator/emulator"
    "$ANDROID_HOME/emulator/emulator"
    "$HOME/Library/Android/sdk/emulator/emulator"
  )
  local x
  for x in "${cands[@]}"; do
    [[ -x "$x" ]] && { echo "$x"; return 0; }
  done
  echo ""
}

__ensure_zshrc_block(){
  # injeta ANDROID_* e PATH de forma idempotente no ~/.zshrc
  local marker="# >>> EASYENV:ANDROID >>>"
  local block
  read -r -d '' block <<'ZRC'
# >>> EASYENV:ANDROID >>>
export ANDROID_SDK_ROOT="${ANDROID_SDK_ROOT:-$HOME/Library/Android/sdk}"
export ANDROID_HOME="$ANDROID_SDK_ROOT"
# PATHs essenciais do Android SDK
case ":$PATH:" in
  *":$ANDROID_SDK_ROOT/platform-tools:"*) ;;
  *) export PATH="$ANDROID_SDK_ROOT/platform-tools:$PATH" ;;
esac
case ":$PATH:" in
  *":$ANDROID_SDK_ROOT/emulator:"*) ;;
  *) export PATH="$ANDROID_SDK_ROOT/emulator:$PATH" ;;
esac
# cmdline-tools/latest/bin (sdkmanager/avdmanager)
if [ -d "$ANDROID_SDK_ROOT/cmdline-tools/latest/bin" ]; then
  case ":$PATH:" in
    *":$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:"*) ;;
    *) export PATH="$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$PATH" ;;
  esac
fi
# <<< EASYENV:ANDROID <<<
ZRC
  append_once "$HOME/.zshrc" "$marker" "$block"
}

__ensure_cmdline_tools_layout(){
  # Garante que exista $ANDROID_SDK_ROOT/cmdline-tools/latest
  # Se o brew instalou em /opt/homebrew/share/android-commandlinetools, linkamos.
  local dest="$ANDROID_SDK_ROOT/cmdline-tools/latest"
  local brewroot="/opt/homebrew/share/android-commandlinetools/cmdline-tools/latest"
  local brewroot2="/opt/homebrew/share/android-commandlinetools/cmdline-tools"
  mkdir -p "$ANDROID_SDK_ROOT/cmdline-tools" || true
  if [[ -x "$dest/bin/sdkmanager" ]]; then
    return 0
  fi
  if [[ -x "$brewroot/bin/sdkmanager" ]]; then
    ln -sfn "$brewroot" "$dest"
    return 0
  fi
  # alguns brews instalam como .../cmdline-tools/bin (sem latest)
  if [[ -x "$brewroot2/bin/sdkmanager" ]]; then
    # cria uma árvore latest copiando/espelhando
    mkdir -p "$dest"
    cp -R "$brewroot2/"* "$dest/" 2>/dev/null || true
    [[ -x "$dest/bin/sdkmanager" ]] && return 0
  fi
  return 0
}

__accept_licenses(){
  local sdkm="$(__sdkmanager_path)"
  if [[ -x "$sdkm" ]]; then
    yes | "$sdkm" --licenses >/dev/null 2>&1 || true
  fi
}

__sdk_install_essentials(){
  # instala/atualiza pacotes essenciais via sdkmanager
  local sdkm="$(__sdkmanager_path)"
  if [[ -z "$sdkm" ]]; then
    warn "sdkmanager não encontrado; pulando instalação de pacotes."
    return 0
  fi

  info "Instalando/atualizando pacotes essenciais do Android SDK…"
  # API 34 é estável; 35 pode estar em prévia dependendo da data. Mantemos 34 + emulator + platform-tools
  "$sdkm" --install \
    "cmdline-tools;latest" \
    "platform-tools" \
    "platforms;android-34" \
    "build-tools;34.0.0" \
    "emulator" \
    >/dev/null 2>&1 || true

  # Instalar uma imagem padrão ARM64 (boa para Macs Apple Silicon)
  "$sdkm" --install "system-images;android-34;google_apis;arm64-v8a" >/dev/null 2>&1 || true

  __accept_licenses
}

# ===========================
# API do plugin
# ===========================

tool_check(){
  # retorna 0 se ambiente está OK o suficiente (sdkmanager/adb localizáveis)
  export ANDROID_SDK_ROOT="${ANDROID_SDK_ROOT:-$(__android_default_sdk_root)}"
  local okcount=0
  [[ -x "$(__sdkmanager_path)" ]] && ((okcount++))
  [[ -x "$(__adb_path)" ]] && ((okcount++))
  (( okcount >= 1 ))
}

tool_install(){
  export ANDROID_SDK_ROOT="${ANDROID_SDK_ROOT:-$(__android_default_sdk_root)}"
  info "Instalando Android command line tools e platform-tools (Homebrew)…"
  brew install android-commandlinetools android-platform-tools || true

  mkdir -p "$ANDROID_SDK_ROOT" || true
  __ensure_cmdline_tools_layout
  __ensure_zshrc_block

  info "Aceitando licenças e instalando pacotes essenciais…"
  __sdk_install_essentials

  ok "Android SDK base instalado em: $ANDROID_SDK_ROOT"
  echo "Abra um novo shell ou rode: source ~/.zshrc"
}

tool_update(){
  export ANDROID_SDK_ROOT="${ANDROID_SDK_ROOT:-$(__android_default_sdk_root)}"
  brew upgrade android-commandlinetools android-platform-tools >/dev/null 2>&1 || true

  __ensure_cmdline_tools_layout
  local sdkm="$(__sdkmanager_path)"
  if [[ -n "$sdkm" ]]; then
    info "Atualizando pacotes via sdkmanager --update …"
    "$sdkm" --update >/dev/null 2>&1 || true
    __sdk_install_essentials
    ok "Android SDK atualizado."
  else
    warn "sdkmanager não encontrado. Verifique PATH e instalação do cmdline-tools."
  fi
}

tool_uninstall(){
  export ANDROID_SDK_ROOT="${ANDROID_SDK_ROOT:-$(__android_default_sdk_root)}"

  info "Desinstalando via Homebrew (commandlinetools e platform-tools)…"
  brew uninstall android-commandlinetools >/dev/null 2>&1 || true
  brew uninstall android-platform-tools   >/dev/null 2>&1 || true

  if confirm "Deseja remover o SDK em '$ANDROID_SDK_ROOT'? (remove diretório)"; then
    rm -rf "$ANDROID_SDK_ROOT"
    ok "SDK removido: $ANDROID_SDK_ROOT"
  else
    info "Mantendo diretório do SDK."
  fi

  # remove bloco do zshrc (marcador)
  if grep -qF "# >>> EASYENV:ANDROID >>>" "$HOME/.zshrc" 2>/dev/null; then
    info "Removendo bloco EASYENV:ANDROID do ~/.zshrc"
    # sed -i compatível com macOS (faz backup .bak)
    sed -i.bak '/# >>> EASYENV:ANDROID >>>/,/# <<< EASYENV:ANDROID <<</d' "$HOME/.zshrc"
    ok "Bloco removido. Backup: ~/.zshrc.bak"
  fi
}

tool_versions(){
  export ANDROID_SDK_ROOT="${ANDROID_SDK_ROOT:-$(__android_default_sdk_root)}"

  echo "Android SDK:"
  echo "  SDK Root: ${ANDROID_SDK_ROOT}"
  local sdkm="$(__sdkmanager_path)"
  local avdm="$(__avdmanager_path)"
  local adb="$(__adb_path)"
  local emu="$(__emulator_path)"

  printf "  sdkmanager: %s\n" "${sdkm:-(não encontrado)}"
  printf "  avdmanager: %s\n" "${avdm:-(não encontrado)}"
  printf "  adb:        %s\n" "${adb:-(não encontrado)}"
  printf "  emulator:   %s\n" "${emu:-(não encontrado)}"
  echo

  if [[ -d "$ANDROID_SDK_ROOT/build-tools" ]]; then
    echo "Build-tools instalados:"
    ls -1 "$ANDROID_SDK_ROOT/build-tools" | sed 's/^/  - /'
  else
    echo "Build-tools: (nenhum encontrado)"
  fi

  echo
  if [[ -d "$ANDROID_SDK_ROOT/platforms" ]]; then
    echo "Platforms instaladas:"
    ls -1 "$ANDROID_SDK_ROOT/platforms" | sed 's/^/  - /'
  else
    echo "Platforms: (nenhuma encontrada)"
  fi

  echo
  if [[ -n "$avdm" ]]; then
    echo "AVDs:"
    "$avdm" list avd 2>/dev/null | sed 's/^/  /' || echo "  (nenhum AVD)"
  else
    echo "AVDs: (avdmanager não encontrado)"
  fi
}

# Define/muda o SDK atual ou mostra sugestão
# Uso:
#   easyenv switch android                      -> só re-injeta bloco no zshrc (usa default)
#   easyenv switch android /caminho/do/sdk      -> aponta ANDROID_SDK_ROOT para esse caminho
tool_switch(){
  local newroot="${1:-}"
  if [[ -n "$newroot" ]]; then
    if [[ ! -d "$newroot" ]]; then
      err "Diretório SDK inválido: $newroot"
      return 1
    fi
    export ANDROID_SDK_ROOT="$newroot"
  else
    export ANDROID_SDK_ROOT="${ANDROID_SDK_ROOT:-$(__android_default_sdk_root)}"
  fi
  __ensure_zshrc_block
  ok "ANDROID_SDK_ROOT ajustado para: $ANDROID_SDK_ROOT"
  echo "Abra um novo shell ou rode: source ~/.zshrc"
}

# ===========================
# Subcomando AVD
# ===========================
# easyenv android avd list
# easyenv android avd create <NAME> [--image <system-image-id>] [--device <device-id>]
# easyenv android avd start <NAME>
# easyenv android avd kill  <NAME>

tool_avd(){
  export ANDROID_SDK_ROOT="${ANDROID_SDK_ROOT:-$(__android_default_sdk_root)}"
  local avdm="$(__avdmanager_path)"
  local emu="$(__emulator_path)"

  case "${1:-}" in
    list|"")
      if [[ -n "$avdm" ]]; then
        "$avdm" list avd || true
      else
        err "avdmanager não encontrado."
        return 1
      fi
      ;;

    create)
      shift || true
      local name="${1:-}"; shift || true
      [[ -z "$name" ]] && { err "Uso: easyenv android avd create <NAME> [--image <id>] [--device <id>]"; return 1; }
      local image="system-images;android-34;google_apis;arm64-v8a"
      local device="pixel_7"

      while [[ $# -gt 0 ]]; do
        case "$1" in
          --image) shift; image="${1:-$image}" ;;
          --device) shift; device="${1:-$device}" ;;
          *) warn "Opção desconhecida para avd create: $1" ;;
        esac
        shift || true
      done

      # garantir que a imagem existe
      local sdkm="$(__sdkmanager_path)"
      if [[ -n "$sdkm" ]]; then
        info "Garantindo system image '$image' instalada…"
        "$sdkm" --install "$image" >/dev/null 2>&1 || true
        __accept_licenses
      fi

      if [[ -z "$avdm" ]]; then
        err "avdmanager não encontrado."
        return 1
      fi

      info "Criando AVD '$name' (device: $device, image: $image)…"
      echo "no" | "$avdm" create avd -n "$name" -k "$image" -d "$device" || {
        err "Falha ao criar AVD."
        return 1
      }
      ok "AVD criado: $name"
      ;;

    start)
      shift || true
      local name="${1:-}"; shift || true
      [[ -z "$name" ]] && { err "Uso: easyenv android avd start <NAME>"; return 1; }
      [[ -z "$emu" ]] && { err "emulator não encontrado."; return 1; }

      info "Iniciando emulador '$name'…"
      nohup "$emu" -avd "$name" >/dev/null 2>&1 &
      ok "Emulador '$name' iniciado (background)."
      ;;

    kill)
      shift || true
      local adb="$(__adb_path)"
      [[ -z "$adb" ]] && { err "adb não encontrado."; return 1; }

      info "Encerrando quaisquer emuladores em execução…"
      "$adb" devices | awk '/emulator-/{print $1}' | while read -r dev; do
        "$adb" -s "$dev" emu kill || true
      done
      ok "Emuladores encerrados (se havia)."
      ;;

    *)
      err "Uso: easyenv android avd {list|create|start|kill}"
      return 1
      ;;
  esac
}

# ===========================
# Roteador do plugin (opcional)
# ===========================
# O core chama tool_* diretamente via plugin_call. Se você quiser expor
# um sub-dispatch manual, pode usar esta função:
tool_dispatch(){
  local sub="${1:-}"; shift || true
  case "$sub" in
    versions) tool_versions "$@" ;;
    install)  tool_install  "$@" ;;
    update)   tool_update   "$@" ;;
    uninstall) tool_uninstall "$@" ;;
    check)    tool_check    "$@" ;;
    switch)   tool_switch   "$@" ;;
    avd)      tool_avd      "$@" ;;
    *) err "android plugin: subcomando desconhecido '$sub'"; return 1 ;;
  esac
}

doctor_tool(){
  local sdk="${ANDROID_SDK_ROOT:-${ANDROID_HOME:-}}"

  if [[ -z "$sdk" ]]; then
    warn "ANDROID_SDK_ROOT/ANDROID_HOME não definido."
    echo "Dica: export ANDROID_SDK_ROOT=\"$HOME/Library/Android/sdk\""
  else
    ok "SDK: $sdk"
  fi

  if ! command -v sdkmanager >/dev/null 2>&1; then
    warn "sdkmanager não encontrado no PATH."
    echo "Dica: export PATH=\$PATH:$HOME/Library/Android/sdk/cmdline-tools/latest/bin"
  else
    ok "sdkmanager encontrado: $(command -v sdkmanager)"
    sdkmanager --version || true
  fi

  if ! command -v avdmanager >/dev/null 2>&1; then
    warn "avdmanager não encontrado no PATH."
  else
    ok "avdmanager encontrado."
  fi

  if ! command -v adb >/dev/null 2>&1; then
    warn "adb não encontrado."
  else
    ok "adb encontrado: $(adb version | head -n1)"
  fi

  # Licenças
  if [[ -d "${sdk:-}/licenses" ]]; then
    ok "Licenças presentes em $sdk/licenses"
  else
    warn "Licenças ausentes. Dica: sdkmanager --licenses"
  fi

  # Emuladores (opcional)
  if command -v emulator >/dev/null 2>&1; then
    ok "Emulador disponível."
  else
    warn "Emulador não encontrado."
  fi
}