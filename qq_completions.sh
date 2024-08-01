#!/bin/bash

. $HOME/qq/commands.sh

function get_commands {
  local commands=""
  local command_arrays=(COMMANDS_HELP COMMANDS_LIST COMMANDS_MANAGE COMMANDS_UPDATE COMMANDS_MISC COMMANDS_INSTALL)

  for command_array_name in "${command_arrays[@]}"; do
    declare -n command_array="$command_array_name"
    for cmd in "${!command_array[@]}"; do
      IFS=',' read -r -a array <<<"$cmd"
      for element in "${array[@]}"; do
        commands="${commands} ${element}"
      done
    done
  done
  printf "%s\n" "${commands}"
}

_open_folder_completions() {
  local cur folders
  COMPREPLY=()
  cur="${COMP_WORDS[COMP_CWORD]}"
  folders=$(find ~ -mindepth 1 -maxdepth 3 -type d -path "*/${cur}*" -exec basename {} \;)
  COMPREPLY=($(compgen -W "${folders}" -- "${cur}"))
}

_qq_completions() {
  local cur prev commands containers
  COMPREPLY=()
  cur="${COMP_WORDS[COMP_CWORD]}"
  prev="${COMP_WORDS[COMP_CWORD - 1]}"
  commands=$(get_commands)

  case "${prev}" in
    -ri)
      COMPREPLY=($(compgen -W "$(docker images --format '{{.Tag}}')" -- "${cur}"))
      ;;
    down | -d | up)
      containers=$(docker ps -a --format '{{.Names}}')
      [[ "${prev}" == "down" || "${prev}" == "-d" ]] && containers=$(docker ps --format '{{.Names}}')
      COMPREPLY=($(compgen -W "${containers}" -- "${cur}"))
      ;;
    open-folder | -of)
      _open_folder_completions
      ;;
    *)
      if [[ ${cur} == -* ]]; then
        COMPREPLY=($(compgen -W "${commands}" -- "${cur}"))
      else
        containers=$(docker ps --format '{{.Names}}')
        COMPREPLY=($(compgen -W "${commands} ${containers}" -- "${cur}"))
      fi
      ;;
  esac
}

complete -F _qq_completions qq
