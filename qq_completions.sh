#!/bin/bash

_qq_completions() {
    local cur prev opts commands
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    commands="-h help qq -i info -l list -la list-all -li list-images -ri -gph -d down update -id install-docker -im install-make -gl gitlab -pb prune-builder up -dni generate-password-hash"

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
