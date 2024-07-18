#!/bin/bash

source $HOME/qq/commands.sh

function get_commands {
  local commands=""
  for cmd in "${!COMMANDS_HELP[@]}"; do
    IFS=',' read -r -a array <<<"$cmd"
    for element in "${array[@]}"; do
      commands="${commands} ${element}"
    done
  done
  for cmd in "${!COMMANDS_LIST[@]}"; do
    IFS=',' read -r -a array <<<"$cmd"
    for element in "${array[@]}"; do
      commands="${commands} ${element}"
    done
  done
  for cmd in "${!COMMANDS_MANAGE[@]}"; do
    IFS=',' read -r -a array <<<"$cmd"
    for element in "${array[@]}"; do
      commands="${commands} ${element}"
    done
  done
  printf "%s\n" "${commands}"
}

_open_folder_completions() {
  local cur prev folders
  COMPREPLY=()
  cur="${COMP_WORDS[COMP_CWORD]}"
  prev="${COMP_WORDS[COMP_CWORD - 1]}"
  if [[ ${prev} == "open-folder" || ${prev} == "-of" ]]; then
    folders=$(find ~ -mindepth 1 -maxdepth 3 -type d -path "*/${cur}*" -exec basename {} \;)
    COMPREPLY=($(compgen -W "${folders}" -- "${cur}"))
  fi
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
      return 0
      ;;
    -gph)
      return 0
      ;;
    down | -d)
      containers=$(docker ps --format '{{.Names}}')
      COMPREPLY=($(compgen -W "${containers}" -- "${cur}"))
      return 0
      ;;
    up)
      containers=$(docker ps -a --format '{{.Names}}')
      COMPREPLY=($(compgen -W "${containers}" -- "${cur}"))
      return 0
      ;;
    open-folder | -of)
      _open_folder_completions
      return 0
      ;;
    *)
      if [[ ${cur} == -* ]]; then
        COMPREPLY=($(compgen -W "${commands}" -- "${cur}"))
      else
        containers=$(docker ps --format '{{.Names}}')
        COMPREPLY=($(compgen -W "${commands} ${containers}" -- "${cur}"))
      fi
      return 0
      ;;
  esac
}

complete -F _qq_completions qq
