#!/bin/bash

_qq_completions() {
    local cur prev opts commands
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    commands="-h --help -i --info -l --list -la --list-all -li --list-images -ri -gph --update --install-docker --install-make --gitlab -pb --prune-builder"

    case "${prev}" in
        -ri)
            COMPREPLY=( $(compgen -W "$(docker images --format '{{.Tag}}')" -- ${cur}) )
            return 0
            ;;
        -gph)
            return 0
            ;;
        *)
            if [[ ${cur} == -* ]]; then
                COMPREPLY=( $(compgen -W "${commands}" -- ${cur}) )
            else
                local containers=$(docker ps --format '{{.Names}}')
                COMPREPLY=( $(compgen -W "${commands} ${containers}" -- ${cur}) )
            fi
            return 0
            ;;
    esac
}

complete -F _qq_completions qq
