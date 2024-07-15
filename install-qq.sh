#!/bin/bash

# Цвета для вывода
GREEN="\033[32m"
BLUE="\033[34m"
YELLOW="\033[33m"
RED="\033[31m"
RESET="\033[0m"

# Путь к скрипту
script_path="$HOME/qq.sh"

# Определение файла для добавления алиаса
if [ -f "$HOME/.bash_aliases" ]; then
    alias_file="$HOME/.bash_aliases"
else
    alias_file="$HOME/.bashrc"
fi

clean_install=true
# Удаление старого алиаса qq, если он существует
if grep -q "alias qq=" "$alias_file"; then
    sed -i '/alias qq=/d' "$alias_file"
    echo -e "${GREEN}Старый алиас qq был удален${RESET}"
fi

echo -e "${GREEN}Создаем файл qq.sh...${RESET}"

cat > "$script_path" << 'EOF'
#!/bin/bash

declare -A commands=(
    ["-h"]="show_help"
    ["--help"]="show_help"
    ["-l"]="list_containers"
    ["--list"]="list_containers"
    ["-la"]="list_all_containers"
    ["--list-all"]="list_all_containers"
)

show_help() {
    local cmd_descriptions=(
        "qq -h, --help       Выводит это сообщение"
        "qq -l, --list       Выводит список запущенных контейнеров"
        "qq -la, --list-all  Выводит список всех контейнеров"
        "qq [фильтр]         Останавливает все контейнеры, соответствующие фильтру"
        "qq                  Останавливает все запущенные контейнеры"
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
    containers=$(docker ps -q)
    if [ -n "$containers" ]; then
        mapfile -t container_ids <<< "$containers"
        mapfile -t names < <(docker inspect --format "{{.Name}}" "${container_ids[@]}" | cut -c2-)
        for i in "${!container_ids[@]}"; do
            container=${container_ids[$i]}
            if [[ -z "$filter" || "${names[$i]}" == *"$filter"* ]]; then
                docker "$action" "$container" > /dev/null 2>&1 &
                pids+=($!)
                container_names["$container"]="${names[$i]}"
            fi
        done
    else
        echo -e "\e[31m[END]\e[0m Нет запущенных контейнеров для остановки"
        exit 1
    fi
}

check_containers() {
    local remaining=${#pids[@]}
    while [ "$remaining" -gt 0 ]; do
        for i in "${!pids[@]}"; do
            if [ -n "${pids[$i]}" ] && ! kill -0 "${pids[$i]}" 2>/dev/null; then
                container_id=${container_ids[$i]}
                container_name=${container_names["$container_id"]}
                if [ -n "$container_name" ]; then
                    echo -e "\e[33m[INFO]\e[0m Остановлен контейнер: \e[36m$container_name\e[0m"
                else
                    echo -e "\e[33m[INFO]\e[0m Остановлен контейнер: \e[36m${container_ids[$i]}\e[0m"
                fi
                unset pids[$i]
                ((remaining--))
            fi
        done
        sleep 1
    done
    echo -e "\e[32m[INFO]\e[0m Все контейнеры успешно остановлены"
}

stop_containers() {
    docker_action "stop"
}

list_containers() {
    containers=$(docker ps -q)
    if [ -n "$containers" ]; then
        mapfile -t container_ids <<< "$containers"
        mapfile -t names < <(docker inspect --format "{{.Name}}" "${container_ids[@]}" | cut -c2-)
        for name in "${names[@]}"; do
            echo -e "\e[32m[ACTIVE]\e[0m Контейнер: \e[36m${name}\e[0m"
        done
    else
        echo -e "\e[31m[END]\e[0m Нет запущенных контейнеров"
        echo -e "Для просмотра всех контейнеров выполните \e[33mqq -la\e[0m"
    fi
}

list_all_containers() {
    containers=$(docker ps -a -q)
    if [ -n "$containers" ]; then
        mapfile -t container_ids <<< "$containers"
        mapfile -t names < <(docker inspect --format "{{.Name}}" "${container_ids[@]}" | cut -c2-)
        for i in "${!container_ids[@]}"; do
            local status=$(docker inspect --format "{{.State.Status}}" "${container_ids[$i]}")
            local status_text="STOP"
            local status_color="\e[31m"  # Red for STOP
            [[ "$status" == "running" ]] && status_text="ACTIVE" && status_color="\e[32m"  # Green for ACTIVE
            echo -e "${status_color}[$status_text]\e[0m Контейнер: \e[36m${names[$i]}\e[0m"
        done
    else
        echo -e "\e[31m[ERROR]\e[0m Нет контейнеров"
    fi
}

main() {
    declare -A container_names
    pids=()
    start_times=()
    filter=""

    if [[ -n "$1" && -n "${commands[$1]}" ]]; then
        ${commands[$1]} "$2"
        exit 0
    elif [[ -n "$1" ]]; then
        filter="$1"
        echo -e "\e[34m[START]\e[0m Начинаем остановку контейнеров с фильтром: \e[36m$filter\e[0m"
    else
        echo -e "\e[34m[START]\e[0m Начинаем остановку всех контейнеров..."
    fi

    stop_containers

    if [ -n "$containers" ]; then
        check_containers
    else
        echo -e "\e[31m[INFO]\e[0m Нет запущенных контейнеров для остановки"
    fi
    echo -e "\e[34m[FINISH]\e[0m Процесс завершен"
}

main "$@"

EOF

chmod +x "$script_path"

alias_exists=$(grep -q "alias qq=" "$alias_file" && echo "yes" || echo "no")

if $clean_install || [ "$alias_exists" = "no" ]; then
    echo -e "${GREEN}Создаем новый алиас qq...${RESET}"
    echo "alias qq='$script_path'" >> "$alias_file"
fi

echo -e "${GREEN}Установка завершена${RESET}"
echo -e "Чтобы применить изменения, выполните команду ${BLUE}source $alias_file${RESET}"
echo -e "Для получения помощи по qq выполните ${BLUE}qq -h${RESET}"
