#!/usr/bin/env bash
# EasyEnv — roteador de subcomandos
# Regras:
#  - Mapeia "easyenv <cmd> [args]" → "src/presenter/cli/<cmd>.sh" e executa "cmd_<cmd> [args]"
#  - Aliases comuns (-h/--help → help, -v/--version → version, upgrade→update, diag→doctor)
#  - Logging centralizado (user.log e debug.log) com mesmo request-id
#  - Lista comandos disponíveis quando <cmd> não existe

set -euo pipefail

# ---------- Helpers locais (independentes do restante do core) ----------

__router_now_iso(){ date +"%Y-%m-%dT%H:%M:%S%z"; }

__router_uuid(){
  if command -v uuidgen >/dev/null 2>&1; then uuidgen
  else printf "req-%s-%04d" "$(date +%s)" "$RANDOM"
  fi
}

__router_cli_dir(){ echo "$EASYENV_HOME/src/presenter/cli"; }
__router_log_dir(){ echo "$EASYENV_HOME/var/logs"; }
__router_user_log(){ echo "$EASYENV_HOME/var/logs/user.log"; }
__router_debug_log(){ echo "$EASYENV_HOME/var/logs/debug.log"; }

__router_list_commands(){
  local d; d="$(__router_cli_dir)"
  [[ -d "$d" ]] || return 0
  find "$d" -maxdepth 1 -type f -name "*.sh" -print \
    | sed -e "s|$d/||" -e 's|\.sh$||' \
    | sort -u
}

__router_alias_of(){
  local raw="${1:-}"
  case "$raw" in
    ""|"help"|"-h"|"--help"|"--usage") echo "help" ;;
    "-v"|"--version"|"version")        echo "version" ;;
    "upgrade")                          echo "update" ;;
    "diag"|"doctor")                    echo "doctor" ;;
    *)                                  echo "$raw" ;;
  esac
}

__router_cmd_file(){
  local cmd="$1"
  echo "$EASYENV_HOME/src/presenter/cli/${cmd}.sh"
}

__router_print_unknown(){
  local bad="$1"
  echo "❌ Comando desconhecido: $bad" >&2
  echo "Comandos disponíveis:" >&2
  local c; while IFS= read -r c; do echo "  - $c"; done < <(__router_list_commands)
  echo >&2
  echo "Dica: easyenv --help" >&2
}

# ---------- Logging (central) ----------

# Registra uma linha JSON no user.log
__router_log_user(){
  local id="$1" ts="$2" cmd="$3" args="$4" status="$5" code="$6"
  local logf; logf="$(__router_user_log)"
  mkdir -p "$(__router_log_dir)"
  printf '{"id":"%s","ts":"%s","cmd":"%s","args":"%s","status":"%s","code":%s}\n' \
    "$id" "$ts" "$cmd" "$args" "$status" "$code" >> "$logf"
}

# Registra bloco delimitado no debug.log (stdout/stderr completos)
__router_log_debug(){
  local id="$1" ts="$2" cmd="$3" args="$4" code="$5" outfile="$6"
  local logf; logf="$(__router_debug_log)"
  mkdir -p "$(__router_log_dir)"
  {
    echo "----- DEBUG START id=$id ts=$ts cmd=$cmd args=$args -----"
    if [[ -f "$outfile" ]]; then
      cat "$outfile"
    else
      echo "(sem saída capturada)"
    fi
    echo "----- DEBUG END id=$id exit=$code -----"
    echo
  } >> "$logf"
}

# Executa cmd_<nome> de um presenter/cli, capturando saída e centralizando logs
__router_exec_with_logs(){
  local cmd="$1"; shift || true
  local req_id ts args_str status exit_code
  req_id="$(__router_uuid)"
  ts="$(__router_now_iso)"
  args_str="$(printf "%q " "$@")"

  local cli_file; cli_file="$(__router_cmd_file "$cmd")"
  # shellcheck disable=SC1090
  source "$cli_file"

  # A função a ser chamada deve se chamar cmd_<cmd>
  local fn="cmd_${cmd}"
  if ! declare -F "$fn" >/dev/null 2>&1; then
    echo "❌ A função '$fn' não foi encontrada em $cli_file" >&2
    exit 2
  fi

  # Captura saída com tee para o usuário ver + gravar em debug
  local tmp_out; tmp_out="$(mktemp -t "easyenv_${cmd}.XXXX")"
  set +e
  (
    # Subshell para isolar "set -e"
    "$fn" "$@"
  ) > >(tee "$tmp_out") 2>&1
  exit_code=$?
  set -e

  status=$([[ $exit_code -eq 0 ]] && echo "Success" || echo "Error")

  __router_log_user  "$req_id" "$ts" "$cmd" "$args_str" "$status" "$exit_code"
  __router_log_debug "$req_id" "$ts" "$cmd" "$args_str" "$exit_code" "$tmp_out"

  rm -f "$tmp_out" || true
  return "$exit_code"
}

# ---------- Router público ----------

router_dispatch(){
  local raw_cmd="${1:-}"; shift || true
  local cmd; cmd="$(__router_alias_of "$raw_cmd")"

  # Sem comando → help (se existir), senão lista comandos
  if [[ -z "$cmd" ]]; then
    if [[ -f "$(__router_cmd_file help)" ]]; then
      __router_exec_with_logs "help" "$@"
      return $?
    fi
    echo "EasyEnv — comandos disponíveis:"
    __router_list_commands | sed 's/^/  - /'
    return 0
  fi

  local file; file="$(__router_cmd_file "$cmd")"
  if [[ ! -f "$file" ]]; then
    __router_print_unknown "$cmd"
    return 1
  fi

  __router_exec_with_logs "$cmd" "$@"
}