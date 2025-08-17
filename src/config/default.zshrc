# >>> EASYENV PRELUDE >>>
# Deduplica PATH/ path no zsh (evita duplicatas)
typeset -U path PATH
# <<< EASYENV PRELUDE <<<

# =========================================================
#                   Z S H   W O R K S P A C E
# =========================================================
# Estrutura:
# - TEMA & ZSH (oh-my-zsh, history, opções)
# - CLI TOOLS (sub-seções por ferramenta)
# - STACKS (Flutter, Android, iOS/Xcode, Node, Deno, .NET, Java)
# - GIT (aliases)
# - DOCKER (aliases)
# - OUTROS (atalhos gerais)
# =========================================================

# ----- TEMA & CONFIGS .ZSHRC --------------------------------------
# Environment
export ZSH="$HOME/.oh-my-zsh"
export ZSH_CUSTOM="${ZSH_CUSTOM:-$ZSH/custom}"

# Tema (escolha um e comente os demais)
# ZSH_THEME="spaceship"
# ZSH_THEME="agnoster"
ZSH_THEME="powerlevel10k/powerlevel10k"   # recomendado

# Powerlevel10k: instant prompt (evita warning de I/O no início)
typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet

# Plugins do Oh My Zsh (adicione/remova conforme uso)
plugins=(
  git
  docker
  fzf
  zsh-autosuggestions
  zsh-syntax-highlighting
  fzf-tab
)

# ----- Homebrew (fallback p/ shells não-login) ---------------------
# >>> EASYENV:CORE:BREW_SHELLENV_FALLBACK >>>
if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi
# <<< EASYENV:CORE:BREW_SHELLENV_FALLBACK <<<

# Carregar Oh My Zsh (se instalado)
[[ -s "$ZSH/oh-my-zsh.sh" ]] && source "$ZSH/oh-my-zsh.sh"

# Zsh Options / Completion
# Configs
setopt AUTO_CD             # cd <dir> sem precisar escrever 'cd'
setopt EXTENDED_GLOB
setopt HIST_IGNORE_DUPS
setopt SHARE_HISTORY
setopt INTERACTIVE_COMMENTS
unsetopt BEEP
# Completion case-insensitive
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'

# Histórico
# Configs
HISTFILE="$HOME/.zsh_history"
HISTSIZE=20000
SAVEHIST=20000
HIST_STAMPS="yyyy-mm-dd"
export HISTIGNORE="(history|ls|ll|la|pwd|clear)"

# Caminhos de base (Apple Silicon Homebrew + bin local)
# Environment
if [[ -d /opt/homebrew/bin ]]; then
  export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"
fi
export PATH="$HOME/.local/bin:$PATH"

# Keybindings / UX
# Configs
bindkey -e
bindkey '^[[H' beginning-of-line
bindkey '^[[F' end-of-line
bindkey '^[[3~' delete-char
bindkey '^H' backward-kill-word


# ----- CLI TOOLS ---------------------------------------------------
# Uso: utilitários de produtividade do terminal

## fzf (fuzzy finder)
# Environment
if command -v fd >/dev/null 2>&1; then
  export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
elif command -v rg >/dev/null 2>&1; then
  export FZF_DEFAULT_COMMAND='rg --files --hidden --follow -g !.git'
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
fi
# Outros
[[ -f ~/.fzf.zsh ]] && source ~/.fzf.zsh

## fzf-tab (autocomplete no zsh via fzf)
# (já carregado pelos plugins do Oh My Zsh)

## zoxide (cd inteligente)
# Environment
command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init zsh)"
# Aliases
alias z='zoxide query -l | fzf | xargs -I{} cd "{}"'

## direnv (env por pasta)
# Environment
command -v direnv >/dev/null 2>&1 && eval "$(direnv hook zsh)"

## thefuck (corrige comandos)
# Environment
command -v thefuck >/dev/null 2>&1 && eval "$(thefuck --alias)"   # Uso: digite 'fuck' após um erro de comando

## tldr (man simplificado)
# Environment
export TLDR_LANGUAGE=pt-BR
# Aliases
alias help='tldr'

## bat / eza / ripgrep / fd (modernos)
# Aliases
alias cat='bat -p'
alias ls='eza -G'
alias ll='eza -la --group-directories-first --icons'
alias la='eza -a'
alias lt='eza -T'
alias grep='rg'

## httpie / jq
# Aliases
alias http='httpie'   # ou use 'http' direto se preferir o bin `http`
alias jqc='jq -C . | less -R'   # JSON colorido paginado

## GitHub CLI / ghq
# Aliases
alias ghl='gh auth login'
alias ghqget='gh repo list --limit 100 | fzf | awk "{print \$1}" | xargs -I{} ghq get {}'

## Sistemas / Monitoramento
# Aliases
alias top='btop'                    # btop > htop > top
alias gl='glances'                  # overview de recursos
alias nettr='sudo mtr -c 50 1.1.1.1' # traceroute+ping
alias fetch='fastfetch || neofetch' # infos do sistema

## Miscelânea
# Aliases
alias o.='open .'                   # abre Finder na pasta atual
alias path='echo $PATH | tr ":" "\n"'
alias zclean='rm -f ~/.zcompdump* && exec zsh'


# ----- STACK: FLUTTER ----------------------------------------------
# Configs / Environment
export FVM_CACHE_PATH="${FVM_CACHE_PATH:-$HOME/.fvm}"
export PUB_CACHE="${PUB_CACHE:-$HOME/.pub-cache}"
# >>> EASYENV:FLUTTER:AUTO >>>
if [[ -d "$FVM_CACHE_PATH/default/bin" ]]; then
  export PATH="$FVM_CACHE_PATH/default/bin:$PATH"
fi
# Inclui cache do pub para executáveis (melos, very_good, etc.)
export PATH="$PUB_CACHE/bin:$PATH"
# <<< EASYENV:FLUTTER:AUTO <<<

# Aliases
alias fver='flutter --version'
alias fdoc='flutter doctor -v'
alias fpk='flutter pub get'
alias fpkc='flutter pub cache clean'
alias frun='flutter run'
alias fdev='flutter run -d'
alias fapk='flutter build apk --release'

# Funções
# Uso:
#   fvmst <versão>           -> alterna global (ex.: 3.13.9, stable)
#   fvmst -install <versão>  -> instala sem alternar
#   fvmst -versions          -> lista instaladas
#   fvmst -current           -> mostra ativa
fvmst() {
  local cmd="${1:-}"
  local arg="${2:-}"

  if [[ "$cmd" == "-versions" || "$cmd" == "--versions" ]]; then
    if [[ -d "$FVM_CACHE_PATH/versions" ]]; then
      echo "Versões instaladas em $FVM_CACHE_PATH/versions:"
      local active_target
      active_target="$(readlink "$FVM_CACHE_PATH/default" 2>/dev/null || true)"
      for v in "$FVM_CACHE_PATH/versions"/*; do
        [[ -d "$v" ]] || continue
        local name="${v##*/}"
        if [[ -n "$active_target" && "$v" == "$active_target" ]]; then
          echo "  * $name   (ATIVA)"
        else
          echo "    $name"
        fi
      done
    else
      echo "Nenhuma versão instalada ainda. Use: fvmst -install <versão>"
    fi
    return 0
  fi

  if [[ "$cmd" == "-current" ]]; then
    local active_target
    active_target="$(readlink "$FVM_CACHE_PATH/default" 2>/dev/null || true)"
    if [[ -n "$active_target" ]]; then
      echo "Versão ativa: ${active_target##*/}"
      flutter --version
    else
      echo "Nenhuma versão ativa encontrada. Use fvmst <versão>."
    fi
    return 0
  fi

  if [[ "$cmd" == "-install" ]]; then
    if [[ -z "$arg" ]]; then
      echo "Uso: fvmst -install <versão>"
      return 1
    fi
    if [[ -d "$FVM_CACHE_PATH/versions/$arg" ]]; then
      echo "⚠️  Versão $arg já existe em $FVM_CACHE_PATH/versions"
    else
      echo "⬇️  Instalando versão $arg ..."
      fvm install "$arg" || { echo "❌ Falha ao instalar $arg"; return 1; }
      echo "✅ Versão $arg instalada (não ativa)."
    fi
    return 0
  fi

  if [[ -z "$cmd" ]]; then
    echo "Uso:"
    echo "  fvmst <versão>          -> alterna para a versão"
    echo "  fvmst -install <versão> -> instala sem alternar"
    echo "  fvmst -versions         -> lista versões instaladas"
    echo "  fvmst -current          -> mostra versão ativa"
    return 1
  fi

  local version="$cmd"
  local vdir="$FVM_CACHE_PATH/versions/$version"
  [[ -d "$vdir" ]] || { echo "❌ $version não encontrada. Instalando..."; fvm install "$version" || { echo "❌ Falha ao instalar $version"; return 1; }; }

  ln -sfn "$vdir" "$FVM_CACHE_PATH/default"
  case ":$PATH:" in *":$FVM_CACHE_PATH/default/bin:"*) ;; *) export PATH="$FVM_CACHE_PATH/default/bin:$PATH" ;; esac
  echo "✅ Flutter alternado para versão: $version"
  flutter --version
}


# ----- STACK: ANDROID ----------------------------------------------
# Environment
export ANDROID_SDK_ROOT="$HOME/Library/Android/sdk"
export ANDROID_HOME="$ANDROID_SDK_ROOT"
# >>> EASYENV:ANDROID:ENV >>>
if [[ -d "$ANDROID_SDK_ROOT/platform-tools" ]]; then
  export PATH="$ANDROID_SDK_ROOT/platform-tools:$PATH"
fi
if [[ -d "$ANDROID_SDK_ROOT/emulator" ]]; then
  export PATH="$ANDROID_SDK_ROOT/emulator:$PATH"
fi
if [[ -d "$ANDROID_SDK_ROOT/cmdline-tools/latest/bin" ]]; then
  export PATH="$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$PATH"
fi
# <<< EASYENV:ANDROID:ENV >>>

# Aliases
alias sdk='open "$ANDROID_SDK_ROOT"'
alias androidstudio='open -a "Android Studio"'
alias emus='emulator -list-avds'
alias emu7='emulator -avd Pixel_7_API_34 -netdelay none -netspeed full &'
alias adbkill='adb kill-server && adb start-server && adb devices'
alias logcatf='adb logcat | grep -i --line-buffered -E "E/|FATAL|Exception|Crash"'

# ----- STACK: iOS / XCODE ------------------------------------------
# Environment
export DEVELOPER_DIR="/Applications/Xcode.app/Contents/Developer"

# Aliases
alias xcode='open -a Xcode'
alias sim='open -a Simulator'
alias xver='xcodebuild -version && swift --version'


# ----- STACK: NODE / ANGULAR ---------------------------------------
# NVM (lazy load para shell rápido)
# >>> EASYENV:NVM:INIT >>>
export NVM_DIR="$HOME/.nvm"
if [[ -s "/opt/homebrew/opt/nvm/nvm.sh" ]]; then
  nvm() { unset -f nvm; . "/opt/homebrew/opt/nvm/nvm.sh"; nvm "$@"; }
fi
# <<< EASYENV:NVM:INIT >>>
# Angular completion (carrega somente se 'ng' existir)
if command -v ng >/dev/null 2>&1; then
  source <(ng completion script)
fi
# PATH dos bins globais do npm (se desejar)
if command -v npm >/dev/null 2>&1; then
  export PATH="$PATH:$(npm bin -g 2>/dev/null)"
fi
# Aliases
alias ngs='ng serve'
alias ngb='ng build'
alias ngr='ng g @schematics/angular:component'   # exemplo

# ----- STACK: DENO --------------------------------------------------
# Environment (instalação via script oficial)
# >>> EASYENV:DENO:INIT >>>
if [[ -d "$HOME/.deno/bin" ]]; then
  export PATH="$HOME/.deno/bin:$PATH"
fi
# <<< EASYENV:DENO:INIT >>>
# Aliases
alias drun='deno run'
alias dtest='deno test'
alias dserve='deno run --allow-net --allow-read'


# ----- STACK: .NET --------------------------------------------------
# Suporte a instalação oficial no $HOME (opcional)
# >>> EASYENV:DOTNET:PATH >>>
if [[ -d "$HOME/.dotnet" ]]; then
  export DOTNET_ROOT="$HOME/.dotnet"
  export PATH="$DOTNET_ROOT:$PATH"
fi
# <<< EASYENV:DOTNET:PATH >>>
# Aliases
alias dotnet-sdks='dotnet --list-sdks'
alias dotnet-runtimes='dotnet --list-runtimes'


# ----- STACK: JAVA (Switch) ----------------------------------------
# Environment (padrão Android/AGP 8.x → JDK 17)
# >>> EASYENV:JAVA:HOME >>>
if command -v /usr/libexec/java_home >/dev/null 2>&1; then
  export JAVA_HOME="$(/usr/libexec/java_home -v 17 2>/dev/null || true)"
  [[ -n "$JAVA_HOME" ]] && export PATH="$JAVA_HOME/bin:$PATH"
fi
# <<< EASYENV:JAVA:HOME >>>

# Funções
# Uso:
#  use_jdk 17 | 21 | 23  (alterna a versão ativa no terminal atual)
use_jdk() {
  if [[ -z "$1" ]]; then
    echo "Uso: use_jdk <versão> (ex.: 17, 21, 23)"
    /usr/libexec/java_home -V
    return 1
  fi
  local v="$1"
  local jp
  jp="$(
    /usr/libexec/java_home -v "$v" 2>/dev/null \
    || /usr/libexec/java_home -F -v "$v" 2>/dev/null
  )" || { echo "❌ JDK $v não encontrado"; /usr/libexec/java_home -V; return 1; }
  export JAVA_HOME="$jp"
  export PATH="$JAVA_HOME/bin:$PATH"
  echo "✅ Agora usando JDK $(java -version 2>&1 | head -n1)"
}
# Aliases
alias jdks='/usr/libexec/java_home -V'


# ----- GIT (CLI TOOL) ----------------------------------------------
# Aliases
alias gs='git status -sb'
alias ga='git add -A'
alias gc='git commit -m'
alias gca='git commit --amend --no-edit'
alias gp='git push'
alias gpf='git push --force-with-lease'
alias gl='git pull --rebase'
alias gco='git checkout'
alias gcb='git checkout -b'
alias gd='git diff'
alias gds='git diff --staged'
alias glg='git log --oneline --graph --decorate -n 30'


# ----- DOCKER (CLI TOOL) -------------------------------------------
# Aliases
alias d='docker'
alias dps='docker ps'
alias dpsa='docker ps -a'
alias di='docker images'
alias dstop='docker stop $(docker ps -q)'
alias drm-stopped='docker rm $(docker ps -aq -f status=exited)'
alias drmi-dangling='docker rmi $(docker images -q -f "dangling=true")'
alias dlogs='docker logs -f'
alias dsh='docker exec -it'   # uso: dsh <container> /bin/sh


# ----- OUTROS (ATALHOS GERAIS) -------------------------------------
# Funções
mkcd() { mkdir -p "$1" && cd "$1"; }       # cria a pasta e entra
extract() {                                # extrai arquivos comuns
  local f="$1"; [[ -f "$f" ]] || { echo "Arquivo não existe: $f"; return 1; }
  case "$f" in
    *.tar.bz2) tar xjf "$f";;
    *.tar.gz)  tar xzf "$f";;
    *.tar.xz)  tar xJf "$f";;
    *.tar)     tar xf  "$f";;
    *.tbz2)    tar xjf "$f";;
    *.tgz)     tar xzf "$f";;
    *.zip)     unzip   "$f";;
    *.rar)     unrar x "$f";;
    *.7z)      7z x    "$f";;
    *.gz)      gunzip  "$f";;
    *.bz2)     bunzip2 "$f";;
    *.xz)      unxz    "$f";;
    *) echo "Formato não suportado: $f";;
  esac
}
serve() {                                  # servidor HTTP local
  local port="${1:-8000}"
  if command -v python3 >/dev/null 2>&1; then python3 -m http.server "$port"; else python -m SimpleHTTPServer "$port"; fi
}

# ----- WORKSPACE / EASYENV -----------------------------------------
# Atalhos opcionais para o EasyEnv (já disponível em PATH)
alias ee='easyenv'
# Ex.: ee status, ee init -steps -y, ee update --outdated

# ----- Rodapé -------------------------------------------------------
# Evite prints aqui para não conflitar com o "instant prompt" do Powerlevel10k.
# Use: easyenv theme install powerlevel10k && easyenv theme set powerlevel10k && easyenv theme apply
#      e, se quiser, rode 'easyenv theme wizard' para configurar o prompt interativamente.