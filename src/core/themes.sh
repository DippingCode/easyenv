#!/usr/bin/env bash
# ============================================
# EasyEnv - Theme Manager (themes.sh)
# Gerencia temas do oh-my-zsh
# ============================================

THEME_CONFIG_DIR="$HOME/.easyenv/themes"
ZSHRC_FILE="$HOME/.zshrc"

# Garante que a pasta de temas exista
mkdir -p "$THEME_CONFIG_DIR"

# ------------------------------
# Listar temas disponíveis
# ------------------------------
themes_list() {
  echo "🎨 Temas disponíveis:"
  echo "  - powerlevel10k"
  echo "  - spaceship"
  echo "  - agnoster"
  echo "  - robbyrussell (padrão)"
}

# ------------------------------
# Instalar um tema
# ------------------------------
themes_install() {
  local theme=$1
  case "$theme" in
    powerlevel10k)
      echo "⬇️ Instalando Powerlevel10k..."
      brew install romkatv/powerlevel10k/powerlevel10k
      echo "ZSH_THEME=\"powerlevel10k/powerlevel10k\"" >> "$THEME_CONFIG_DIR/active"
      ;;
    spaceship)
      echo "⬇️ Instalando Spaceship..."
      brew install spaceship
      echo "ZSH_THEME=\"spaceship\"" >> "$THEME_CONFIG_DIR/active"
      ;;
    agnoster)
      echo "✅ Tema Agnoster já incluso no oh-my-zsh"
      echo "ZSH_THEME=\"agnoster\"" >> "$THEME_CONFIG_DIR/active"
      ;;
    robbyrussell|default)
      echo "✅ Usando tema padrão do oh-my-zsh"
      echo "ZSH_THEME=\"robbyrussell\"" >> "$THEME_CONFIG_DIR/active"
      ;;
    *)
      echo "❌ Tema desconhecido: $theme"
      themes_list
      return 1
      ;;
  esac

  echo "✅ Tema $theme configurado!"
}

# ------------------------------
# Aplicar tema escolhido no .zshrc
# ------------------------------
themes_apply() {
  local theme=$(cat "$THEME_CONFIG_DIR/active" | cut -d'"' -f2)

  if [[ -z "$theme" ]]; then
    echo "❌ Nenhum tema configurado. Use: easyenv theme set <nome>"
    return 1
  fi

  echo "⚡ Aplicando tema: $theme"

  # Atualiza linha do ZSH_THEME no .zshrc
  sed -i.bak "s/^ZSH_THEME=.*/ZSH_THEME=\"$theme\"/" "$ZSHRC_FILE"
  source "$ZSHRC_FILE"

  echo "✅ Tema $theme aplicado com sucesso!"
}

# ------------------------------
# CLI principal
# ------------------------------
themes_cli() {
  case "$1" in
    list) themes_list ;;
    install) themes_install "$2" ;;
    apply) themes_apply ;;
    *) 
      echo "Uso: easyenv theme <comando>"
      echo "Comandos disponíveis:"
      echo "   list              Lista temas suportados"
      echo "   install <tema>    Instala e configura um tema"
      echo "   apply             Aplica o tema configurado"
      ;;
  esac
}