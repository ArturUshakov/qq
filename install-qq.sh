#!/bin/bash

# Функция для вывода цветного текста
print_colored() {
    echo -e "\033[${1}m${2}\033[0m"
}

# Проверка наличия Docker
if ! command -v docker &> /dev/null; then
    print_colored "31" "Docker не найден. Установите Docker и повторите попытку."
    exit 1
fi

# Цвета для вывода
GREEN="32"
BLUE="34"
YELLOW="33"
RED="31"
WHITE="37"
CIAN="36"

# Путь к скрипту и файлу версии
script_dir="$HOME/qq"
script_path="$script_dir/qq.sh"
alias_file="$HOME/.bash_aliases"
[ ! -f "$alias_file" ] && alias_file="$HOME/.bashrc"

# Создание папки для скрипта, если она не существует
mkdir -p "$script_dir"

# Удаление существующего алиаса и создание нового
if grep -q "alias qq=" "$alias_file"; then
    sed -i '/alias qq=/d' "$alias_file"
fi

# Создание скрипта qq.sh
cat > "$script_path" << 'EOF'
#!/bin/bash

VERSION=0.5.1

# Цвета для вывода
GREEN=32
BLUE=34
YELLOW=33
RED=31
WHITE=37
CIAN=36
BASIC=""

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
    local color=$1
    shift
    local message=$*
    if [ -z "$color" ] || [ "$color" == "$BASIC" ]; then
        echo "$message"
    else
        echo -e "\033[${color}m${message}\033[0m"
    fi
}

qq_get_info() {
    stdout $YELLOW "Скрипт qq"
    stdout $YELLOW "Версия: $VERSION"
    stdout $YELLOW "Репозиторий скрипта: https://github.com/ArturUshakov/qq"
    stdout $YELLOW "По вопросам и предложениям писать: https://t.me/Mariores"
}

generate_password_hash() {
    local password=$1
    local hash=$(php -r "echo password_hash('$password', PASSWORD_DEFAULT);")
    stdout $WHITE "Hashed password: $hash"
}

check_version() {
    local latest_version=$(curl -s https://raw.githubusercontent.com/ArturUshakov/qq/master/version.txt)

    if [ "$latest_version" != "$VERSION" ]; then
        stdout $RED "\nВНИМАНИЕ!"
        stdout $WHITE "Доступна новая версия скрипта ($latest_version)"
        stdout $WHITE "Пожалуйста, обновите скрипт командой:"
        stdout $CIAN "qq update"
    fi
}

update() {
    curl -s https://raw.githubusercontent.com/ArturUshakov/qq/master/install-qq.sh | bash

    changelog=$(curl -s https://raw.githubusercontent.com/ArturUshakov/qq/master/CHANGELOG.md)
    version=$(echo "$changelog" | grep -E '^## \[.*\] - ' | head -n 1 | sed -E 's/^## \[([0-9.]+)\].*/\1/')
    changes=$(echo "$changelog" | awk '/^## \['"$version"'\] - /{flag=1; next} /^## /{flag=0} flag')

    stdout $BASIC "====================================="
    stdout $GREEN "Скрипт обновлен до версии $version"
    stdout $YELLOW "Изменения в версии $version:"
    stdout 36 "$changes"
    echo "$version" > "$HOME/qq/version.txt"
    stdout $YELLOW "\nДля обновления скрипта запустите новый терминал или выполните команду:"
    stdout 36 "source ~/.bashrc"
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
        echo -e "\033[31m[ERROR]\033[0m Нет контейнеров"
    fi
}

main() {
    declare -A container_names
    pids=()
    start_times=()
    filter=""

    if [[ "$1" == "update" ]]; then
        update
        exit 0
    elif [[ -n "$1" && -n "${commands[$1]}" ]]; then
        ${commands[$1]} "$2"
        check_version
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
    check_version
}

main "$@"

EOF

chmod +x "$script_path"

echo "alias qq='$script_path'" >> "$alias_file"

print_colored "$GREEN" "Установка завершена\n"
print_colored "$YELLOW" "Если вы скачали скрипт впервые, то выполните команду:"
print_colored "$BLUE" "source ~/.bashrc\n"
print_colored "$YELLOW" "Для получения помощи по qq выполните:"
print_colored "$BLUE" "qq -h"
