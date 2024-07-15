#!/usr/bin/env bash

set -Eeuo pipefail

VERSION=0.5.2

# Цвета для вывода
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
BLUE="\033[34m"
CIAN="\033[36m"
WHITE="\033[37m"
BASIC=""
NOANSI="\033[0m"

declare -A commands=(
    ["-h"]="show_help"
    ["--help"]="show_help"
    ["-l"]="list_containers"
    ["--list"]="list_containers"
    ["-la"]="list_all_containers"
    ["--list-all"]="list_all_containers"
    ["-gph"]="generate_password_hash"
    ["--generate-password-hash"]="generate_password_hash"
    ["-i"]="qq_get_info"
    ["--info"]="qq_get_info"
)

stdout() {
    local message=$*
    echo -e "$message"
}

qq_get_info() {
    stdout "$YELLOWСкрипт qq$NOANSI\n$YELLOWВерсия: $VERSION$NOANSI\n$YELLOWРепозиторий скрипта: https://github.com/ArturUshakov/qq$NOANSI\n$YELLOWПо вопросам и предложениям писать: https://t.me/Mariores$NOANSI"
}

generate_password_hash() {
    local password=${1:-}
    if [ -z "$password" ]; then
        stdout "$RED[ERROR] Пожалуйста, предоставьте пароль для хэширования$NOANSI"
        exit 1
    fi
    local hash=$(php -r "echo password_hash('$password', PASSWORD_DEFAULT);")
    stdout "$WHITE Hashed password: $hash$NOANSI"
}

check_version() {
    local latest_version=$(curl -s https://raw.githubusercontent.com/ArturUshakov/qq/master/version.txt)
    if [ "$latest_version" != "$VERSION" ]; then
        stdout "$RED\nВНИМАНИЕ!$NOANSI\n$WHITEДоступна новая версия скрипта ($latest_version)$NOANSI\n$WHITEПожалуйста, обновите скрипт командой:$NOANSI\n$CIANqq update$NOANSI"
    fi
}

update() {
    curl -s https://raw.githubusercontent.com/ArturUshakov/qq/master/install-qq.sh | bash
    local changelog=$(curl -s https://raw.githubusercontent.com/ArturUshakov/qq/master/CHANGELOG.md)
    local version=$(echo "$changelog" | grep -E '^## \[.*\] - ' | head -n 1 | sed -E 's/^## \[([0-9.]+)\].*/\1/')
    local changes=$(echo "$changelog" | awk '/^## \['"$version"'\] - /{flag=1; next} /^## /{flag=0} flag')
    stdout "====================================="
    stdout "$GREENСкрипт обновлен$NOANSI до версии $RED$version$NOANSI"
    stdout "$YELLOWИзменения в версии $version:$NOANSI"
    stdout "$CIAN$changes$NOANSI"
    echo "$version" > "$HOME/qq/version.txt"
    stdout "$YELLOW\nДля обновления скрипта запустите новый терминал или выполните команду:$NOANSI\n$CIAN source ~/.bashrc$NOANSI"
}

show_help() {
    local cmd_descriptions=(
        "qq -h, --help       Выводит это сообщение"
        "qq -l, --list       Выводит список запущенных контейнеров"
        "qq -la, --list-all  Выводит список всех контейнеров"
        "qq -i, --info       Выводит информацию о скрипте"
        "qq -gph [password]  Генерирует хэш пароля"
        "qq [фильтр]         Останавливает все контейнеры, соответствующие фильтру"
        "qq                  Останавливает все запущенные контейнеры"
        "qq update           Выполняет обновление qq до актуальной версии"
    )

    local max_length=0
    for cmd in "${cmd_descriptions[@]}"; do
        local length=${#cmd}
        (( length > max_length )) && max_length=$length
    done

    local width=$((max_length + 4))

    printf "\e[1;34m%-${width}s\e[0m\n" "ДОСТУПНЫЕ КОМАНДЫ"
    for cmd in "${cmd_descriptions[@]}"; do
        printf "\e[1;32m%-${width}s\e[0m\n" "$cmd"
    done
}

docker_action() {
    local action=$1
    local containers=$(docker ps -q)
    if [ -n "$containers" ]; then
        mapfile -t container_ids <<< "$containers"
        mapfile -t names < <(docker inspect --format "{{.Name}}" "${container_ids[@]}" | cut -c2-)
        for i in "${!container_ids[@]}"; do
            local container=${container_ids[$i]}
            if [[ -z "$filter" || "${names[$i]}" == *"$filter"* ]]; then
                docker "$action" "$container" > /dev/null 2>&1 &
                pids+=($!)
                container_names["$container"]="${names[$i]}"
            fi
        done
    else
        stdout "$RED[END] Нет запущенных контейнеров для остановки$NOANSI"
        exit 1
    fi
}

check_containers() {
    local remaining=${#pids[@]}
    while [ "$remaining" -gt 0 ]; do
        for i in "${!pids[@]}"; do
            if [ -n "${pids[$i]}" ] && ! kill -0 "${pids[$i]}" 2>/dev/null; then
                local container_id=${container_ids[$i]}
                local container_name=${container_names["$container_id"]}
                if [ -n "$container_name" ]; then
                    stdout "$YELLOW[INFO] Остановлен контейнер: $CIAN$container_name$NOANSI"
                else
                    stdout "$YELLOW[INFO] Остановлен контейнер: $CIAN${container_ids[$i]}$NOANSI"
                fi
                unset pids[$i]
                ((remaining--))
            fi
        done
        sleep 1
    done
    stdout "$GREEN[INFO] Все контейнеры успешно остановлены$NOANSI"
}

stop_containers() {
    docker_action "stop"
}

list_containers() {
    local containers=$(docker ps -q)
    if [ -n "$containers" ]; then
        mapfile -t container_ids <<< "$containers"
        mapfile -t names < <(docker inspect --format "{{.Name}}" "${container_ids[@]}" | cut -c2-)
        for name in "${names[@]}"; do
            stdout "$GREEN[ACTIVE] Контейнер: $CIAN${name}$NOANSI"
        done
    else
        stdout "$RED[END] Нет запущенных контейнеров$NOANSI"
        stdout "Для просмотра всех контейнеров выполните $YELLOW qq -la$NOANSI"
    fi
}

list_all_containers() {
    local containers=$(docker ps -a -q)
    if [ -n "$containers" ]; then
        mapfile -t container_ids <<< "$containers"
        mapfile -t names < <(docker inspect --format "{{.Name}}" "${container_ids[@]}" | cut -c2-)

        printf "%-55s\n" "---------------------------------------------------------"
        printf "| %-40s | %-10s |\n" "Container Name" "Status"
        printf "%-55s\n" "---------------------------------------------------------"

        for i in "${!container_ids[@]}"; do
            local status=$(docker inspect --format "{{.State.Status}}" "${container_ids[$i]}")
            local status_text="STOP"
            local status_color="\033[31m"  # Red for STOP
            if [[ "$status" == "running" ]]; then
                status_text="ACTIVE"
                status_color="\033[32m"  # Green for ACTIVE
            fi
            printf "| %-40s | %b%-10s\033[0m |\n" "${names[$i]}" "$status_color" "$status_text"
        done

        printf "%-55s\n" "---------------------------------------------------------"
    else
        stdout "$RED[ERROR] Нет контейнеров$NOANSI"
    fi
}

_qq_completions() {
    local curr_arg="${COMP_WORDS[COMP_CWORD]}"
    local opts="-h --help -l --list -la --list-all -gph --generate-password-hash -i --info update"
    COMPREPLY=( $(compgen -W "${opts}" -- ${curr_arg}) )
}

complete -F _qq_completions qq

main() {
    declare -A container_names
    pids=()
    filter=""

    if [[ "${1:-}" == "update" ]]; then
        update
        exit 0
    elif [[ -n "${1:-}" && -n "${commands[$1]}" ]]; then
        ${commands[$1]} "${2:-}"
        check_version
        exit 0
    elif [[ -n "${1:-}" ]]; then
        filter="$1"
        stdout "$BLUE[START] Начинаем остановку контейнеров с фильтром: $CIAN$filter$NOANSI"
    else
        stdout "$BLUE[START] Начинаем остановку всех контейнеров...$NOANSI"
    fi

    stop_containers

    if [ -n "${containers:-}" ]; then
        check_containers
    else
        stdout "$RED[INFO] Нет запущенных контейнеров для остановки$NOANSI"
    fi
    stdout "$BLUE[FINISH] Процесс завершен$NOANSI"
    check_version
}

main "$@"
