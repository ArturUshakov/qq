#!/bin/bash

. $HOME/qq/commands.sh
. $HOME/qq/src/*

# Главная функция
function main {
  local COMMAND=""
  local ARG="$1"
  shift

  if [[ -z "$ARG" ]]; then
    print_help
    return
  fi

  for group in $(compgen -A variable); do
    if declare -p "$group" 2>/dev/null | grep -q 'declare -A'; then
      declare -n cmd_group="$group"
      for key in "${!cmd_group[@]}"; do
        if [[ ",${key}," == *",$ARG,"* ]]; then
          COMMAND="${cmd_group[$key]}"
          break 2
        fi
      done
    fi
  done

  if [[ -n "$COMMAND" ]]; then
    IFS='|' read -r func desc <<<"$COMMAND"
    if [[ "$ARG" == "down" || "$ARG" == "-d" ]]; then
      [[ -z "$1" ]] && stop_all_containers || stop_filtered_containers "$1"
    else
      $func "$@"
    fi
  else
    print_colored red "Неизвестная команда: $ARG"
  fi

  check_for_updates
}

main "$@"
