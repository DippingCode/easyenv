#!/usr/bin/env bash
# src/presenter/cli/push.sh
# QoL: usa a PRIMEIRA entrada (tasks[0]) do dev-log para commit, tag e incrementa build.

set -euo pipefail

__require_cmd() {
  local c="$1" hint="${2:-instale e tente novamente.}"
  command -v "$c" >/dev/null 2>&1 || { echo "❌ Dependência ausente: $c — $hint" >&2; exit 1; }
}

__iso_now() {
  # ISO-8601 com timezone: 2025-08-17T13:20:00-03:00 (compat macOS e Linux)
  local raw tzfix
  raw="$(date +"%Y-%m-%dT%H:%M:%S%z")"
  # insere ":" no offset final
  tzfix="$(printf "%s" "$raw" | sed -E 's/([0-9]{2})([0-9]{2})$/\1:\2/')"
  printf "%s" "$tzfix"
}

__find_devlog_file() {
  local candidates=(
    "$EASYENV_HOME/dev-log.yml"
    "$EASYENV_HOME/dev-log.yaml"
    "$EASYENV_HOME/docs/dev-log.yml"
    "$EASYENV_HOME/docs/dev-log.yaml"
  )
  local f
  for f in "${candidates[@]}"; do
    [[ -f "$f" ]] && { echo "$f"; return 0; }
  done
  echo ""
}

# Lê (version, build, commit) da PRIMEIRA entrada (newest-first)
__read_first_entry_from_devlog() {
  local devlog="$1"
  yq -r '.tasks
         | (.[0] // {})
         | [
             (.version // ""),
             (if has("build") and .build != null then (.build|tostring) else "" end),
             (.commit // "")
           ]
         | @tsv' "$devlog"
}

__inc_build_preserve_width() {
  local b="${1:-}"
  if [[ -z "$b" || "$b" == "null" ]]; then
    echo "01"; return 0
  fi
  if ! [[ "$b" =~ ^[0-9]+$ ]]; then
    echo "01"; return 0
  fi
  local width=${#b}
  local n=$((10#$b + 1))
  printf "%0${width}d" "$n"
}

__update_first_build_in_devlog() {
  local devlog="$1" new_build="$2" update_date="${3:-1}"
  if [[ "$update_date" == "1" ]]; then
    yq -i '.tasks[0].build = "'"$new_build"'" | .tasks[0].date = "'"$(__iso_now)"'"' "$devlog"
  else
    yq -i '.tasks[0].build = "'"$new_build"'"' "$devlog"
  fi
}

__version_differs_from_latest_tag() {
  local version="$1"
  local last_tag
  last_tag="$(git describe --tags --abbrev=0 2>/dev/null || echo "")"
  [[ "v$version" != "$last_tag" ]]
}

cmd_push() {
  __require_cmd git "instale Git (brew install git)."
  __require_cmd yq  "instale yq (brew install yq)."

  git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { echo "❌ Não parece estar em um repositório Git." >&2; exit 1; }
  local branch; branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")"
  [[ -z "$branch" ]] && { echo "❌ Não foi possível detectar a branch atual." >&2; exit 1; }

  local devlog; devlog="$(__find_devlog_file)"
  [[ -n "$devlog" ]] || { echo "❌ dev-log (dev-log.yml/.yaml) não encontrado." >&2; exit 1; }

  local row version build commit_msg
  row="$(__read_first_entry_from_devlog "$devlog")" || true
  IFS=$'\t' read -r version build commit_msg <<<"$row"
  version="${version:-}"
  build="${build:-}"
  commit_msg="${commit_msg:-}"

  [[ -z "$commit_msg" || "$commit_msg" == "null" ]] && commit_msg="chore: update (no commit message in dev-log)"
  [[ -z "$version"    || "$version" == "null"    ]] && version="0.0.0"

  local new_build; new_build="$(__inc_build_preserve_width "$build")"
  __update_first_build_in_devlog "$devlog" "$new_build" 1

  echo "📦  dev-log: version=$version  build $build → $new_build"
  echo "📝  commit:  $commit_msg"
  echo "🌿  branch:  $branch"
  echo

  git add -A
  if ! git diff --cached --quiet; then
    git commit -m "$commit_msg"
  else
    echo "ℹ️  Nenhuma alteração para commit (index vazio)."
  fi

  if __version_differs_from_latest_tag "$version"; then
    local tag="v$version"
    echo "🏷️  Criando tag $tag ..."
    git tag -a "$tag" -m "release: $tag (build $new_build)"
  else
    echo "🏷️  Versão no dev-log coincide com a última tag — nenhuma tag criada."
  fi

  local remote; remote="$(git remote 2>/dev/null | head -n1 || true)"
  if [[ -z "$remote" ]]; then
    echo "❌ Nenhum remote Git configurado. Configure e rode novamente: git remote add origin <url>" >&2
    exit 1
  fi

  echo "⤴️  Enviando commits para '$remote/$branch'…"
  git push "$remote" "$branch"

  echo "⤴️  Enviando tags…"
  git push --tags "$remote"

  echo "✅ push concluído."
}