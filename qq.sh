#!/bin/bash

declare -A COMMANDS_HELP=(
    ["-h"]="print_help|Выводит это сообщение"
    ["--help"]="print_help|Выводит это сообщение"
    ["-i"]="script_info|Выводит информацию о скрипте"
    ["--info"]="script_info|Выводит информацию о скрипте"
)

declare -A COMMANDS_LIST=(
    ["-l"]="list_running_containers|Выводит список запущенных контейнеров докера"
    ["--list"]="list_running_containers|Выводит список запущенных контейнеров докера"
    ["-la"]="list_all_containers|Выводит список всех контейнеров"
    ["--list-all"]="list_all_containers|Выводит список всех контейнеров"
    ["-li"]="list_images|Выводит список всех образов"
    ["--list-images"]="list_images|Выводит список всех образов"
)

declare -A COMMANDS_MANAGE=(
    ["-ri"]="remove_image|Удаляет образ по версии"
    ["-gph"]="generate_password_hash|Генерирует хэш пароля"
    ["qq"]="stop_all_containers|Останавливает все запущенные контейнеры"
    ["--update"]="update_script|Выполняет обновление qq до актуальной версии"
    ["--install-docker"]="install_docker|Выполняет полную установку докера"
    ["--install-make"]="install_make|Выполняет установку утилиты make"
    ["--gitlab"]="open_gitlab|Открывает страницу gitlab.efko.ru"
    ["-pb"]="prune_builder|Удаляет неиспользуемые объекты сборки"
    ["--prune-builder"]="prune_builder|Удаляет неиспользуемые объекты сборки"
)

#COMMANDS_HELP
function print_help {
    print_colored blue "Команда               Описание"
    print_colored blue "--------------------  --------------------------------------------------"

    print_colored blue "\nСправка:"
    for key in "${!COMMANDS_HELP[@]}"; do
        IFS='|' read -r func desc <<< "${COMMANDS_HELP[$key]}"
        printf "$(print_colored green "%-30s") $(print_colored yellow "%s")\n" "$key" "$desc"
    done

    print_colored blue "\nСписки:"
    for key in "${!COMMANDS_LIST[@]}"; do
        IFS='|' read -r func desc <<< "${COMMANDS_LIST[$key]}"
        printf "$(print_colored green "%-30s") $(print_colored yellow "%s")\n" "$key" "$desc"
    done

    print_colored blue "\nУправление:"
    for key in "${!COMMANDS_MANAGE[@]}"; do
        IFS='|' read -r func desc <<< "${COMMANDS_MANAGE[$key]}"
        printf "$(print_colored green "%-30s") $(print_colored yellow "%s")\n" "$key" "$desc"
    done
}

function print_colored {
    local color_code
    case "$1" in
        red)
            color_code="31"
            ;;
        green)
            color_code="32"
            ;;
        yellow)
            color_code="33"
            ;;
        blue)
            color_code="34"
            ;;
        *)
            color_code="0"
            ;;
    esac
    shift
    echo -e "\e[${color_code}m$*\e[0m"
}

function get_version {
    grep -m 1 -oP '(?<=## \[)\d+\.\d+\.\d+(?=\])' "$HOME/qq/CHANGELOG.md"
}

function script_info {
    print_colored blue "QQ Script Information"
    echo "Repository: $(print_colored green "https://github.com/ArturUshakov/qq")"
    echo "Version: $(print_colored yellow "$(get_version)")"
    echo "Creator: $(print_colored green "https://t.me/Mariores")"
}

function get_latest_version {
    curl -s "https://raw.githubusercontent.com/ArturUshakov/qq/master/CHANGELOG.md" | grep -m 1 -oP '(?<=## \[)\d+\.\d+\.\d+(?=\])'
}

function check_for_updates {
    local installed_version=$(get_version)
    local latest_version=$(get_latest_version)

    if [ "$installed_version" != "$latest_version" ]; then
        print_colored red "\nВнимание!"
        print_colored yellow "Доступна новая версия qq: $latest_version. Ваша версия: $installed_version."
        print_colored yellow "Используйте 'qq --update' для обновления до последней версии."
    fi
}

#COMMANDS_LIST
function list_running_containers {
    print_colored blue "Запущенные контейнеры:"
    print_colored blue "-------------------------------------------------------------------------------------------------"
    printf "%-40s %-55s %s\n" "$(print_colored blue "ID")" "$(print_colored blue "ИМЯ")" "$(print_colored blue "СТАТУС")"
    print_colored blue "-------------------------------------------------------------------------------------------------"

    docker ps --format "{{.ID}}\t{{.Names}}\t{{.Status}}" | while IFS=$'\t' read -r id name status; do
        id_col=$(print_colored green "$id")
        name_col=$(print_colored yellow "$name")
        status_col=$(print_colored red "$status")

        printf "%-35s %-55s %s\n" "$id_col" "$name_col" "$status_col"
    done
}

function list_all_containers {
       print_colored blue "Запущенные контейнеры:"
    print_colored blue "-------------------------------------------------------------------------------------------------"
    printf "%-40s %-55s %s\n" "$(print_colored blue "ID")" "$(print_colored blue "ИМЯ")" "$(print_colored blue "СТАТУС")"
    print_colored blue "-------------------------------------------------------------------------------------------------"

    docker ps -a --format "{{.ID}}\t{{.Names}}\t{{.Status}}" | while IFS=$'\t' read -r id name status; do
        id_col=$(print_colored green "$id")
        name_col=$(print_colored yellow "$name")
        status_col=$(print_colored red "$status")

        printf "%-35s %-55s %s\n" "$id_col" "$name_col" "$status_col"
    done
}

function list_images {
    print_colored blue "Список образов:"
    print_colored blue "--------------------------------------------------------------------------------------------"
    printf "%-25s %-60s %-27s %-15s\n" "$(print_colored blue "ID")" "$(print_colored blue "РЕПОЗИТОРИЙ")" "$(print_colored blue "ТЕГ")" "$(print_colored blue "РАЗМЕР")"
    print_colored blue "--------------------------------------------------------------------------------------------"

    docker images --format "{{.ID}}\t{{.Repository}}\t{{.Tag}}\t{{.Size}}" | while IFS=$'\t' read -r id repository tag size; do
        id_col=$(print_colored green "$id")
        repository_col=$(print_colored yellow "$repository")
        tag_col=$(print_colored cyan "$tag")
        size_col=$(print_colored red "$size")

        printf "%-20s %-50s %-25s %-15s\n" "$id_col" "$repository_col" "$tag_col" "$size_col"
    done
}

function remove_image {
    if [ -z "$1" ]; then
        echo "Ой! Пожалуйста, укажите версию для удаления."
        return
    fi

    local version="$1"
    local images_to_remove=()

    while IFS=$'\t' read -r repository tag id; do
        if [[ "$tag" == "$version" ]]; then
            images_to_remove+=("$id")
        fi
    done < <(docker images --format "{{.Repository}}\t{{.Tag}}\t{{.ID}}")

    if [ ${#images_to_remove[@]} -eq 0 ]; then
        echo "Образы с версией '$version' не найдены."
        return
    fi

    for image_id in "${images_to_remove[@]}"; do
        docker rmi "$image_id"
        echo "Удален образ с ID: $image_id"
    done
}

function generate_password_hash {
    if [ -z "$1" ]; then
        echo "Пожалуйста, укажите пароль для генерации хеша."
        return
    fi

    local password
    local hash

    password="$1"
    hash=$(php -r "echo password_hash('$password', PASSWORD_DEFAULT);")

    echo "Сгенерированный хеш: $hash"
}

function stop_filtered_containers {
    if [ -z "$1" ]; then
        echo "Пожалуйста, укажите фильтр для остановки контейнеров."
        return
    fi

    local filter="$1"
    local container_ids=($(docker ps --filter "name=$filter" -q))

    if [ ${#container_ids[@]} -eq 0 ]; then
        echo "Контейнеры, соответствующие фильтру '$filter', не найдены."
        return
    fi

    print_colored blue "Остановка контейнеров, соответствующих фильтру '$filter':"
    print_colored blue "-----------------------------------------------------------"

    for container_id in "${container_ids[@]}"; do
        local container_name=$(docker ps --filter "id=$container_id" --format "{{.Names}}")
        docker stop "$container_id" > /dev/null
        printf "%s\n%s\n%s\n" "$(print_colored green "ID: $container_id")" "$(print_colored yellow "Имя: $container_name")" "$(print_colored red "Остановлен")"
        print_colored blue "-----------------------------------------------------------"
    done
}

function stop_all_containers {
    local container_ids=($(docker ps -q))

    if [ ${#container_ids[@]} -eq 0 ]; then
        print_colored red "Нет запущенных контейнеров для остановки."
        return
    fi

    print_colored blue "Остановка всех запущенных контейнеров:"
    print_colored blue "-----------------------------------------------------------"

   for container_id in "${container_ids[@]}"; do
        local container_name=$(docker ps --filter "id=$container_id" --format "{{.Names}}")
        docker stop "$container_id" > /dev/null
        printf "%s\n%s\n%s\n" "$(print_colored green "ID: $container_id")" "$(print_colored yellow "Имя: $container_name")" "$(print_colored red "Остановлен")"
        print_colored blue "-----------------------------------------------------------"
    done
}

function update_script {
    local REPO_URL="https://raw.githubusercontent.com/ArturUshakov/qq/master"
    local INSTALL_DIR="$HOME/qq"

    print_colored blue "Обновление скрипта qq..."

    # Список файлов для обновления
    local files=("qq.sh" "qq_completions.sh" "CHANGELOG.md")

    for file in "${files[@]}"; do
        curl -s "$REPO_URL/$file" -o "$INSTALL_DIR/$file"
        if [ $? -eq 0 ]; then
            print_colored green "$file обновлен успешно."
        else
            print_colored red "Ошибка обновления $file."
        fi
    done

    print_colored green "Обновление завершено."
}

function install_docker {
    print_colored blue "Установка Docker..."

    if command -v docker &> /dev/null; then
        print_colored green "Docker уже установлен."
        return
    fi

    # Шаг 1: Загрузка установочного скрипта Docker
    curl -fsSL https://get.docker.com -o get-docker.sh
    if [ $? -ne 0 ]; then
        print_colored red "Ошибка загрузки установочного скрипта Docker."
        return
    fi

    # Шаг 2: Запуск скрипта установки с предварительной проверкой
    sudo sh ./get-docker.sh --dry-run
    if [ $? -ne 0 ]; then
        print_colored red "Ошибка выполнения предварительной проверки установки Docker."
        return
    fi

    # Шаг 3: Запуск скрипта установки Docker
    sudo sh ./get-docker.sh
    if [ $? -ne 0 ]; then
        print_colored red "Ошибка установки Docker."
        return
    fi

    # Шаг 4: Создание группы docker
    sudo groupadd docker
    if [ $? -ne 0 ]; then
        print_colored yellow "Группа docker уже существует или возникла ошибка при создании группы."
    else
        print_colored green "Группа docker создана успешно."
    fi

    # Шаг 5: Добавление текущего пользователя в группу docker
    sudo usermod -aG docker $USER
    if [ $? -ne 0 ]; then
        print_colored red "Ошибка добавления пользователя в группу docker."
        return
    fi

    # Шаг 6: Обновление групп для текущего сеанса
    newgrp docker
    if [ $? -ne 0 ]; then
        print_colored red "Ошибка обновления групп для текущего сеанса."
        return
    fi

    # Шаг 7: Проверка установки Docker с помощью запуска тестового контейнера
    docker run hello-world
    if [ $? -ne 0 ]; then
        print_colored red "Ошибка запуска тестового контейнера. Проверьте установку Docker вручную."
        return
    fi

    # Шаг 8: Включение сервисов Docker и containerd
    sudo systemctl enable docker.service
    sudo systemctl enable containerd.service
    if [ $? -ne 0 ]; then
        print_colored red "Ошибка включения сервисов Docker и containerd."
        return
    fi

    print_colored green "Docker успешно установлен и настроен."

    print_colored yellow "Если вы запускали команды Docker CLI с помощью sudo до добавления пользователя в группу docker, выполните следующие команды для решения проблемы с правами доступа:"
    echo 'sudo chown "$USER":"$USER" /home/"$USER"/.docker -R'
    echo 'sudo chmod g+rwx "$HOME/.docker" -R'
}

function install_make {
    print_colored blue "Установка утилиты make..."

    if command -v make &> /dev/null; then
        print_colored green "Утилита make уже установлена."
        return
    fi

    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if command -v apt-get &> /dev/null; then
            sudo apt-get update && sudo apt-get install -y make
        elif command -v yum &> /dev/null; then
            sudo yum install -y make
        elif command -v pacman &> /dev/null; then
            sudo pacman -Syu make
        else
            print_colored red "Неизвестный пакетный менеджер. Установите make вручную."
            return
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        if command -v brew &> /dev/null; then
            brew install make
        else
            print_colored red "Homebrew не установлен. Установите Homebrew или make вручную."
            return
        fi
    else
        print_colored red "Неизвестная операционная система. Установите make вручную."
        return
    fi

    if command -v make &> /dev/null; then
        print_colored green "Утилита make успешно установлена."
    else
        print_colored red "Ошибка установки утилиты make."
    fi
}

function open_gitlab {
    xdg-open "https://gitlab.efko.ru"
}

function prune_builder {
    docker builder prune -f
}

function main {
    local COMMAND=""

    if [[ "$1" == -* ]]; then
        if [[ -n "${COMMANDS_HELP[$1]}" ]]; then
            COMMAND="${COMMANDS_HELP[$1]}"
        elif [[ -n "${COMMANDS_LIST[$1]}" ]]; then
            COMMAND="${COMMANDS_LIST[$1]}"
        elif [[ -n "${COMMANDS_MANAGE[$1]}" ]];then
            COMMAND="${COMMANDS_MANAGE[$1]}"
        fi

        if [ -n "$COMMAND" ]; then
            IFS='|' read -r func desc <<< "$COMMAND"
            shift
            $func "$@"
        else
            echo -e "Неизвестная команда: $(print_colored red "$1")"
        fi
    else
        if [ -z "$1" ]; then
            stop_all_containers
        else
            stop_filtered_containers "$1"
        fi
    fi

    check_for_updates
}

main "$@"
