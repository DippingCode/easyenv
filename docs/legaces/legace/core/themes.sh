#!/usr/bin/env bash
# ============================================
# EasyEnv - Theme Manager (core/themes.sh)
# ============================================

set -euo pipefail

# APIs do core usadas:
# - ok, info, warn, err, confirm
# - zshrc_backup, inject_zshrc_block
# - append_once (utils)

THEME_CONFIG_DIR="$HOME/.easyenv/themes"
ZSHRC_FILE="$HOME/.zshrc"
mkdir -p "$THEME_CONFIG_DIR"

# --- helpers internos ---
_theme_exists_in_zshrc(){
  grep -q '^ZSH_THEME=' "$ZSHRC_FILE" 2>/dev/null
}

_theme_write_to_zshrc(){
  local theme="$1"
  zshrc_backup
  if _theme_exists_in_zshrc; then
    sed -i.bak 's/^ZSH_THEME=.*/ZSH_THEME="'"$theme"'"/' "$ZSHRC_FILE"
  else
    printf '\nZSH_THEME="%s"\n' "$theme" >> "$ZSHRC_FILE"
  fi
  ok "ZSH_THEME=\"$theme\" gravado em ~/.zshrc"
}

_theme_current(){
  grep -E '^ZSH_THEME=' "$ZSHRC_FILE" 2>/dev/null | tail -n1 | sed -E 's/^ZSH_THEME="([^"]+)".*$/\1/'
}

_theme_state_file(){ echo "$THEME_CONFIG_DIR/active"; }

# --- comandos ---
themes_list(){
  cat <<EOF
🎨 Temas suportados:
  - powerlevel10k (p10k)
  - spaceship
  - agnoster
  - robbyrussell (padrão)
EOF
}

themes_install(){
  local theme="${1:-}"
  [[ -z "$theme" ]] && { err "Uso: easyenv theme install <tema>"; return 1; }
  case "$theme" in
    powerlevel10k|p10k)
      info "Instalando Powerlevel10k..."
      brew list romkatv/powerlevel10k/powerlevel10k >/dev/null 2>&1 || \
        brew install romkatv/powerlevel10k/powerlevel10k
      echo 'powerlevel10k' > "$(_theme_state_file)"
      ok "Powerlevel10k instalado."
      ;;
    spaceship)
      info "Instalando Spaceship..."
      brew list spaceship >/dev/null 2>&1 || brew install spaceship
      echo 'spaceship' > "$(_theme_state_file)"
      ok "Spaceship instalado."
      ;;
    agnoster)
      echo 'agnoster' > "$(_theme_state_file)"
      ok "Agnoster pronto (vem no Oh-My-Zsh)."
      ;;
    robbyrussell|default)
      echo 'robbyrussell' > "$(_theme_state_file)"
      ok "Tema padrão selecionado."
      ;;
    *)
      err "Tema desconhecido: $theme"
      themes_list
      return 1
      ;;
  esac
}

themes_set(){
  local theme="${1:-}"
  [[ -z "$theme" ]] && { err "Uso: easyenv theme set <tema>"; return 1; }
  case "$theme" in
    powerlevel10k|p10k)
      echo 'powerlevel10k' > "$(_theme_state_file)"
      ;;
    spaceship|agnoster|robbyrussell|default)
      echo "$theme" > "$(_theme_state_file)"
      ;;
    *)
      err "Tema desconhecido: $theme"
      themes_list
      return 1
      ;;
  esac
  ok "Tema ativo marcado: $theme"
}

themes_apply(){
  local reload=0
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -reload) reload=1 ;;
    esac
    shift || true
  done

  local theme
  if [[ -f "$(_theme_state_file)" ]]; then
    theme="$(cat "$(_theme_state_file)")"
  else
    warn "Nenhum tema ativo marcado. Usando robbyrussell."
    theme="robbyrussell"
  fi

  case "$theme" in
    powerlevel10k|p10k) _theme_write_to_zshrc 'powerlevel10k/powerlevel10k' ;;
    spaceship)
      _theme_write_to_zshrc 'spaceship'
      # bloco opcional de configuração spaceship
      inject_zshrc_block "spaceship" "$(cat <<'EOS'
# Spaceship prompt (opcional). Veja https://github.com/spaceship-prompt/spaceship-prompt
SPACESHIP_PROMPT_ORDER=(
  time user dir host git node ruby elixir xcode swift golang php rust docker
  venv pyenv kubectl terraform aws gcloud exec_time line_sep battery char
)
EOS
)" "default" || true
      ;;
    agnoster)     _theme_write_to_zshrc 'agnoster' ;;
    robbyrussell) _theme_write_to_zshrc 'robbyrussell' ;;
    *)
      warn "Tema ativo desconhecido: $theme"
      return 1
      ;;
  esac

  ok "Tema aplicado. Recarregue o shell (exec zsh -l) para ver."
  (( reload==1 )) && { info "Recarregando shell..."; exec zsh -l; }
}

themes_wizard(){
  if brew list romkatv/powerlevel10k/powerlevel10k >/dev/null 2>&1; then
    if confirm "Abrir configurador interativo do Powerlevel10k agora?"; then
      exec zsh -l -c 'p10k configure'
    else
      info "Você pode rodar depois: p10k configure"
    fi
  else
    warn "Powerlevel10k não está instalado. Rode: easyenv theme install powerlevel10k"
  fi
}

# CLI interno (caso queira chamar direto, mas normalmente é via cmd_theme)
themes_cli(){
  local sub="${1:-}"
  case "$sub" in
    list|"") themes_list ;;
    install) shift || true; themes_install "${1:-}" ;;
    set)     shift || true; themes_set "${1:-}" ;;
    apply)   shift || true; themes_apply "$@" ;;
    wizard|configure) themes_wizard ;;
    *) err "Uso: easyenv theme [list|install <tema>|set <tema>|apply [-reload]|wizard]"; themes_list; return 1 ;;
  esac
}