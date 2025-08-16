#!/usr/bin/env bash
# workspace.sh - paths, arquivos, logging, YAML helpers e brew helpers

set -euo pipefail

EASYENV_HOME="${EASYENV_HOME:-$HOME/easyenv}"
CFG_FILE="$EASYENV_HOME/src/config/tools.yml"
SNAP_FILE="$EASYENV_HOME/src/config/.zshrc-tools.yml"
LOG_FILE="$EASYENV_HOME/src/logs/easyenv.log"
ZSHRC_FILE="$HOME/.zshrc"

# Diretório de backups (respeita BACKUP_DIR já definido pelo caller)
BACKUP_DIR="${BACKUP_DIR:-$EASYENV_HOME/backups}"

ensure_backup_dir(){
  mkdir -p "$BACKUP_DIR"
}

ensure_workspace_dirs(){
  mkdir -p "$EASYENV_HOME" \
           "$(dirname "$CFG_FILE")" \
           "$(dirname "$SNAP_FILE")" \
           "$(dirname "$LOG_FILE")"
}

log_line(){
  local cmd="$1" status="$2" msg="$3"
  ensure_workspace_dirs
  printf "[%s] cmd=%s status=%s msg=%s\n" "$(date +"%Y-%m-%d %H:%M:%S")" "$cmd" "$status" "$msg" >> "$LOG_FILE"
}

# ---------- YAML helpers ----------
yq_get(){ yq -r "$1" "$2"; }

list_sections(){
  if [[ -f "$CFG_FILE" ]]; then
    yq -r '.tools[].section' "$CFG_FILE" | sed '/^null$/d' | sort -u
  fi
}

list_tools_by_section(){
  local sec="$1"
  yq -r ".tools[] | select(.section==\"$sec\") | .name" "$CFG_FILE"
}

tool_field(){
  local name="$1" path="$2"
  yq -r ".tools[] | select(.name==\"$name\") | $path" "$CFG_FILE"
}

# ---------- brew helpers ----------
prime_brew_shellenv(){
  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
}

brew_update_quick(){ command -v brew >/dev/null 2>&1 && brew update >/dev/null; }

brew_install_if_needed(){
  local pkg="$1"
  if [[ -z "$pkg" || "$pkg" == "null" ]]; then return 0; fi
  if brew list --formula | grep -qx "$pkg"; then
    info "brew: $pkg já instalado."
  else
    info "brew install $pkg"
    brew install "$pkg"
  fi
}

brew_cask_install_if_needed(){
  local cask="$1"
  if [[ -z "$cask" || "$cask" == "null" ]]; then return 0; fi
  if brew list --cask | grep -qx "$cask"; then
    info "brew cask: $cask já instalado."
  else
    info "brew install --cask $cask"
    brew install --cask "$cask"
  fi
}

# ---------- .zshrc helpers ----------
append_once(){
  local file="$1" marker="$2" block="$3"
  touch "$file"
  if ! grep -qF "$marker" "$file"; then
    printf "\n%s\n%s\n" "$marker" "$block" >> "$file"
  fi
}

append_lines_once(){
  local file="$1" marker="$2"; shift 2
  append_once "$file" "$marker" "$marker"
  while IFS= read -r line; do
    [[ -z "${line:-}" || "$line" == "null" ]] && continue
    grep -qxF "$line" "$file" || printf "%s\n" "$line" >> "$file"
  done < <(printf "%s\n" "$@")
}

# Insere um prelude no topo do ~/.zshrc para deduplicar PATH (zsh).
ensure_zshrc_prelude(){
  local marker_start="# >>> EASYENV PRELUDE >>>"
  local marker_end="# <<< EASYENV PRELUDE <<<"

  # já existe?
  if grep -qF "$marker_start" "$ZSHRC_FILE" 2>/dev/null; then
    return 0
  fi

  zshrc_backup
  { 
    printf "%s\n" "$marker_start"
    printf "%s\n" "# Deduplica PATH/ path no zsh (evita duplicatas)"
    printf "%s\n" "typeset -U path PATH"
    printf "%s\n\n" "$marker_end"
    # mantém o conteúdo original do .zshrc
    cat "$ZSHRC_FILE" 2>/dev/null || true
  } > "${ZSHRC_FILE}.new"

  mv "${ZSHRC_FILE}.new" "$ZSHRC_FILE"
}

# Insere o prelude do Homebrew no ~/.zprofile (login shell)
ensure_zprofile_prelude(){
  local marker_start="# >>> EASYENV HOMEBREW >>>"
  local marker_end="# <<< EASYENV HOMEBREW <<<"

  # já existe?
  if grep -qF "$marker_start" "$HOME/.zprofile" 2>/dev/null; then
    return 0
  fi

  # caminho do brew prefix
  local brew_prefix
  brew_prefix="$(brew --prefix 2>/dev/null || echo "/opt/homebrew")"

  {
    printf "%s\n" "$marker_start"
    printf "%s\n" "eval \"\$(${brew_prefix}/bin/brew shellenv)\""
    printf "%s\n\n" "$marker_end"
    cat "$HOME/.zprofile" 2>/dev/null || true
  } > "$HOME/.zprofile.new"

  mv "$HOME/.zprofile.new" "$HOME/.zprofile"
}

# --- Checks de prelúdio ---

has_zprofile_brew_prelude(){
  grep -qF "# >>> EASYENV HOMEBREW >>>" "$HOME/.zprofile" 2>/dev/null
}

has_zshrc_dedup_prelude(){
  grep -qF "# >>> EASYENV PRELUDE >>>" "$ZSHRC_FILE" 2>/dev/null
}

report_preludes(){
  echo "Prelúdios:"
  if has_zprofile_brew_prelude; then
    ok "~/.zprofile: OK"
  else
    warn "~/.zprofile: AUSENTE"
    echo '  -> execute: easyenv init -reload'
  fi

  if has_zshrc_dedup_prelude; then
    ok "~/.zshrc: OK"
  else
    warn "~/.zshrc: AUSENTE"
    echo '  -> execute: easyenv init -reload'
  fi
}

# ---------- brew uninstall helpers ----------
brew_uninstall_if_installed(){
  local pkg="$1"
  [[ -z "$pkg" || "$pkg" == "null" ]] && return 0
  if brew list --formula | grep -qx "$pkg"; then
    info "brew uninstall $pkg"
    brew uninstall "$pkg"
  else
    info "brew: $pkg não está instalado (formula)."
  fi
}

brew_cask_uninstall_if_installed(){
  local cask="$1"
  [[ -z "$cask" || "$cask" == "null" ]] && return 0
  if brew list --cask | grep -qx "$cask"; then
    info "brew uninstall --cask $cask"
    brew uninstall --cask "$cask"
  else
    info "brew: $cask não está instalado (cask)."
  fi
}

brew_cleanup_safe(){
  if command -v brew >/dev/null 2>&1; then
    info "Executando brew cleanup -s (safe)…"
    brew cleanup -s || true
  fi
}

# ---------- ferramentas/listas ----------
list_all_tools(){
  yq -r '.tools[].name' "$CFG_FILE"
}

# ---------- zshrc cleanup ----------
zshrc_backup(){
  [[ -f "$ZSHRC_FILE" ]] && cp "$ZSHRC_FILE" "${ZSHRC_FILE}.bak.$(date +%Y%m%d%H%M%S)"
}

zshrc_remove_easyenv_markers(){
  # Remove linhas de marcação do EasyEnv; mantém backup acima.
  [[ ! -f "$ZSHRC_FILE" ]] && return 0
  # Remove linhas que contenham nossos marcadores
  sed -i '' '/^# ----- EASYENV (auto) -----/d' "$ZSHRC_FILE" || true
  sed -i '' '/^# EASYENV env/d' "$ZSHRC_FILE" || true
  sed -i '' '/^# EASYENV alias/d' "$ZSHRC_FILE" || true
}

# remove também as linhas de env/aliases definidas no catálogo (best effort)
zshrc_remove_tool_entries(){
  local name="$1"
  # env
  while IFS= read -r line; do
    [[ -z "${line:-}" || "$line" == "null" ]] && continue
    # escapa / para sed
    local escaped="${line//\//\\/}"
    sed -i '' "/^${escaped//\*/\\*}\$/d" "$ZSHRC_FILE" || true
  done < <(tool_field "$name" '.env[]?')

  # aliases
  while IFS= read -r line; do
    [[ -z "${line:-}" || "$line" == "null" ]] && continue
    local escaped="${line//\//\\/}"
    sed -i '' "/^${escaped//\*/\\*}\$/d" "$ZSHRC_FILE" || true
  done < <(tool_field "$name" '.aliases[]?')
}

# Remove arquivos auxiliares comuns do Zsh (.zcompdump*, backups .zshrc.bak.*)
cleanup_zsh_aux_files(){
  info "Limpando arquivos auxiliares do zsh…"
  rm -f "$HOME"/.zshrc.bak.* 2>/dev/null || true
  rm -f "$HOME"/.zcompdump* 2>/dev/null || true
}

# --- Descoberta de origem do binário e versão ---

tool_origin(){
  local name="$1"
  local bin; bin="$(command -v "$name" 2>/dev/null || true)"
  if [[ -z "$bin" ]]; then
    echo "not-found"
    return
  fi
  if [[ "$bin" == "/usr/bin/$name" ]]; then
    echo "system:$bin"
  elif [[ "$bin" == /opt/homebrew/* || "$bin" == /usr/local/* ]]; then
    echo "homebrew:$bin"
  else
    echo "other:$bin"
  fi
}

tool_version(){
  local name="$1"
  # tenta check_version_cmd do catálogo
  local cvc
  cvc="$(tool_field "$name" '.check_version_cmd // ""')"
  if [[ -n "$cvc" && "$cvc" != "null" ]]; then
    bash -lc "$cvc" 2>/dev/null | head -n1 | tr -d '\r' || true
    return 0
  fi
  # fallback padrão "<tool> --version"
  if command -v "$name" >/dev/null 2>&1; then
    "$name" --version 2>/dev/null | head -n1 | tr -d '\r' || true
  fi
}


# Lista backups mais recentes no diretório oficial
list_backups(){
  ensure_backup_dir
  ls -1t "$BACKUP_DIR"/.easyenv-backup-*.zip 2>/dev/null || true
}

# Seleção interativa de backup
#  - Usa fzf (setas+Enter) se disponível
#  - Fallback numérico caso fzf não esteja presente
choose_backup_interactive(){
  BACKUP_DIR="${BACKUP_DIR:-$EASYENV_HOME/backups}"
  ensure_backup_dir

  # colete os arquivos (mais novos primeiro)
  local files=()
  # NÃO dependa de glob falhar: redirecione erros e não estoure com -e
  mapfile -t files < <(ls -1t "$BACKUP_DIR"/.easyenv-backup-*.zip 2>/dev/null || true)
  (( ${#files[@]} == 0 )) && { echo ""; return 0; }

  # helpers locais (evita depender de numfmt)
  local _human_size
  _human_size(){
    local b="${1:-0}" u=(B KB MB GB TB) i=0
    while (( b >= 1024 && i < ${#u[@]}-1 )); do b=$(( b/1024 )); ((i++)); done
    echo "${b}${u[$i]}"
  }

  # constrói linhas bonitas + array de caminhos
  local display=() paths=()
  local f m bytes sz name i=1
  for f in "${files[@]}"; do
    m="$(stat -f '%Sm' -t '%Y-%m-%d %H:%M' "$f" 2>/dev/null || echo '')"
    bytes="$(stat -f '%z' "$f" 2>/dev/null || echo '0')"
    sz="$(_human_size "$bytes")"
    name="${f##*/}"
    display+=( "$(printf '%2d)  %-16s  %6s  %s' "$i" "$m" "$sz" "$name")" )
    paths+=( "$f" )
    ((i++))
  done

  # se fzf existir, seleção por setas
  if command -v fzf >/dev/null 2>&1; then
    # Evita pipefail matar o pipeline caso ESC/cancel
    set +o pipefail
    local choice
    choice="$(
      printf '%s\n' "${display[@]}" \
        | fzf --no-multi \
              --prompt="backup> " \
              --header="Use ↑/↓ e Enter para escolher um backup:" \
              --height=40% \
              --layout=reverse
    )"
    local rc=$?
    set -o pipefail
    [[ $rc -ne 0 || -z "$choice" ]] && { echo ""; return 0; }

    # extrai o índice "NN)" do início da linha
    local idx
    idx="$(printf '%s\n' "$choice" | sed -E 's/^[[:space:]]*([0-9]+)\).*/\1/')"
    if [[ -n "$idx" && "$idx" =~ ^[0-9]+$ ]] && (( idx>=1 && idx<=${#paths[@]} )); then
      printf '%s\n' "${paths[$((idx-1))]}"
      return 0
    else
      echo ""
      return 0
    fi
  fi

  # fallback: menu numérico
  echo "Backups encontrados em $BACKUP_DIR (escolha pelo número):"
  for choice in "${display[@]}"; do
    echo " $choice"
  done
  local pick
  read -r -p "Seleção (1-${#paths[@]} ou Enter p/ cancelar): " pick
  [[ -z "$pick" ]] && { echo ""; return 0; }
  if ! [[ "$pick" =~ ^[0-9]+$ ]] || (( pick < 1 || pick > ${#paths[@]} )); then
    echo ""
    return 0
  fi
  printf '%s\n' "${paths[$((pick-1))]}"
}

extract_backup_zip(){
  local zip="$1"
  if [[ -z "$zip" || ! -f "$zip" ]]; then
    err "Arquivo de backup inválido: $zip"
    return 1
  fi
  info "Restaurando a partir de $(basename "$zip") ..."
  local tmpdir; tmpdir="$(mktemp -d)"
  unzip -q "$zip" -d "$tmpdir"
  # Esperado conter ~/.zshrc e possivelmente outros arquivos de config
  if [[ -f "$tmpdir/.zshrc" ]]; then
    cp "$tmpdir/.zshrc" "$HOME/.zshrc"
    ok "~/.zshrc restaurado"
  fi
  if [[ -f "$tmpdir/.zprofile" ]]; then
    cp "$tmpdir/.zprofile" "$HOME/.zprofile"
    ok "~/.zprofile restaurado"
  fi
  # adicione aqui outros arquivos que decidir incluir no backup no futuro
  rm -rf "$tmpdir"
}

# --- Backup helpers ---

backup_timestamp(){
  date +"%Y%m%d-%H%M%S"
}

# Cria um zip com os arquivos principais do ambiente.
# Saída: caminho do zip criado em $BACKUP_DIR/backup-<timestamp>.zip
make_backup_zip(){
  ensure_backup_dir
  local ts zipfile tmpdir
  ts="$(backup_timestamp)"
  zipfile="$BACKUP_DIR/backup-${ts}.zip"
  tmpdir="$(mktemp -d)"

  # Coleta de arquivos (existentes)
  [[ -f "$HOME/.zshrc"     ]] && cp "$HOME/.zshrc"     "$tmpdir/.zshrc"
  [[ -f "$HOME/.zprofile"  ]] && cp "$HOME/.zprofile"  "$tmpdir/.zprofile"
  [[ -f "$SNAP_FILE"       ]] && cp "$SNAP_FILE"       "$tmpdir/$(basename "$SNAP_FILE")"
  [[ -f "$CFG_FILE"        ]] && cp "$CFG_FILE"        "$tmpdir/$(basename "$CFG_FILE")"

  # Metadata útil
  {
    echo "created_at: $(date -R)"
    echo "easyenv_home: $EASYENV_HOME"
    echo "cfg_file: $CFG_FILE"
    echo "snap_file: $SNAP_FILE"
    echo "version: ${EASYENV_VERSION:-unknown}"
  } > "$tmpdir/EASYENV-METADATA.txt"

  # Compacta (silencioso, recursivo)
  (cd "$tmpdir" && zip -qry "$zipfile" .) || {
    err "Falha ao criar backup em $zipfile"
    rm -rf "$tmpdir"
    return 1
  }

  rm -rf "$tmpdir"
  echo "$zipfile"
}


# Extrai um backup (aceita nome simples ou caminho completo)
extract_backup_zip(){
  ensure_backup_dir
  local zip="$1"
  if [[ -z "$zip" ]]; then
    err "Arquivo de backup não informado."
    return 1
  fi
  # Se veio só o nome, resolva no BACKUP_DIR
  if [[ "$zip" != /* ]]; then
    zip="$BACKUP_DIR/$zip"
  fi
  if [[ ! -f "$zip" ]]; then
    err "Backup não encontrado: $zip"
    return 1
  fi

  info "Restaurando a partir de $(basename "$zip") ..."
  local tmpdir; tmpdir="$(mktemp -d)"
  unzip -q "$zip" -d "$tmpdir"

  [[ -f "$tmpdir/.zshrc"    ]] && cp "$tmpdir/.zshrc"    "$HOME/.zshrc"    && ok "~/.zshrc restaurado"
  [[ -f "$tmpdir/.zprofile" ]] && cp "$tmpdir/.zprofile" "$HOME/.zprofile" && ok "~/.zprofile restaurado"
  # (adicione aqui outros arquivos se desejar)

  rm -rf "$tmpdir"
}

# ========= Backups (info e seleção) =========

# Garante diretório de backups
BACKUP_DIR="${BACKUP_DIR:-$EASYENV_HOME/backups}"
ensure_backup_dir(){ mkdir -p "$BACKUP_DIR"; }

# Lista arquivos de backup (mais novos primeiro)
list_backups(){
  ensure_backup_dir
  ls -1t "$BACKUP_DIR"/.easyenv-backup-*.zip 2>/dev/null || true
}

# Retorna "arquivo|mtime|size" por linha (mais novos primeiro)
# mtime no formato "YYYY-MM-DD HH:MM"
list_backups_struct(){
  ensure_backup_dir
  local f mtime size
  for f in $(ls -1t "$BACKUP_DIR"/.easyenv-backup-*.zip 2>/dev/null); do
    # macOS stat
    mtime="$(stat -f '%Sm' -t '%Y-%m-%d %H:%M' "$f" 2>/dev/null || echo '')"
    size="$(stat -f '%z' "$f" 2>/dev/null || echo '0')"
    echo "$f|$mtime|$size"
  done
}

# Formata uma linha "arquivo|mtime|size" para exibição humana
format_backup_line(){
  local line="$1"
  local file mtime size
  file="${line%%|*}"; line="${line#*|}"
  mtime="${line%%|*}"; size="${line#*|}"
  # tamanho human-readable (macOS)
  local size_h
  size_h=$(numfmt --to=iec --suffix=B "$size" 2>/dev/null || echo "${size}B")
  printf "%-19s  %8s  %s\n" "$mtime" "$size_h" "$(basename "$file")"
}

# Extrai um backup (aceita nome simples ou caminho completo)
extract_backup_zip(){
  ensure_backup_dir
  local zip="$1"
  [[ -z "$zip" ]] && { err "Arquivo de backup não informado."; return 1; }
  [[ "$zip" != /* ]] && zip="$BACKUP_DIR/$zip"
  [[ ! -f "$zip" ]] && { err "Backup não encontrado: $zip"; return 1; }

  info "Restaurando a partir de $(basename "$zip") ..."
  local tmpdir; tmpdir="$(mktemp -d)"
  unzip -q "$zip" -d "$tmpdir"

  [[ -f "$tmpdir/.zshrc"    ]] && cp "$tmpdir/.zshrc"    "$HOME/.zshrc"    && ok "~/.zshrc restaurado"
  [[ -f "$tmpdir/.zprofile" ]] && cp "$tmpdir/.zprofile" "$HOME/.zprofile" && ok "~/.zprofile restaurado"
  # (adicione aqui outros artefatos se desejar)

  rm -rf "$tmpdir"
}

# Retorna o caminho do backup mais recente (ou vazio)
latest_backup(){
  list_backups | head -n 1
}

# Apaga um backup interativamente ou por caminho
delete_backup(){
  ensure_backup_dir

  local file="$1"

  # Se não passou argumento, abre seleção
  if [[ -z "$file" ]]; then
    file="$(choose_backup_interactive)"
    [[ -z "$file" ]] && { warn "Nenhum backup selecionado."; return 1; }
  fi

  # Confirmação
  if ! confirm "Remover backup $(basename "$file")?"; then
    info "Operação cancelada."
    return 1
  fi

  if rm -f "$file"; then
    ok "Backup removido: $file"
  else
    err "Falha ao remover: $file"
    return 1
  fi
}

# Lista backups (tabela humana)
list_backups_human(){
  ensure_backup_dir
  local files
  mapfile -t files < <(ls -1t "$BACKUP_DIR"/.easyenv-backup-*.zip 2>/dev/null || true)
  (( ${#files[@]} == 0 )) && { echo "(nenhum backup encontrado em $BACKUP_DIR)"; return 0; }

  printf "%-3s  %-16s  %-8s  %s\n" "#" "Modificado" "Tamanho" "Arquivo"
  local i=1 f m bytes name

  # helper local p/ tamanho humano (sem numfmt)
  _human_size(){ local b="${1:-0}" u=(B KB MB GB TB) i=0; while (( b>=1024 && i<${#u[@]}-1 )); do b=$((b/1024)); ((i++)); done; echo "${b}${u[$i]}"; }

  for f in "${files[@]}"; do
    m="$(stat -f '%Sm' -t '%Y-%m-%d %H:%M' "$f" 2>/dev/null || echo '')"
    bytes="$(stat -f '%z' "$f" 2>/dev/null || echo '0')"
    name="${f##*/}"
    printf "%-3s  %-16s  %-8s  %s\n" "$i" "$m" "$(_human_size "$bytes")" "$name"
    ((i++))
  done
}

# Mantém apenas os N backups mais recentes e apaga o resto
purge_backups(){
  ensure_backup_dir
  local keep="${1:-0}"
  if ! [[ "$keep" =~ ^[0-9]+$ ]] || (( keep <= 0 )); then
    err "Uso: easyenv backup -purge <N>"
    return 1
  fi

  local files
  mapfile -t files < <(ls -1t "$BACKUP_DIR"/.easyenv-backup-*.zip 2>/dev/null || true)
  (( ${#files[@]} == 0 )) && { warn "Nenhum backup encontrado."; return 0; }

  if (( ${#files[@]} <= keep )); then
    info "Total de backups (${#files[@]}) já é menor ou igual a $keep. Nada a apagar."
    return 0
  fi

  local to_delete=( "${files[@]:$keep}" )
  echo "Os seguintes backups serão removidos (mantendo $keep mais recentes):"
  printf " - %s\n" "${to_delete[@]##*/}"

  if ! confirm "Confirma exclusão?"; then
    info "Operação cancelada."
    return 1
  fi

  local f
  for f in "${to_delete[@]}"; do
    rm -f "$f" && ok "Removido: $(basename "$f")" || err "Falha ao remover: $f"
  done
}