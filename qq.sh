#!/bin/bash

source $HOME/qq/commands.sh

#COMMANDS_HELP
function print_help {
  for group in $(compgen -A variable); do
    if declare -p "$group" 2>/dev/null | grep -q 'declare -A'; then
      declare -n cmd_group="$group"
      case $group in
        "COMMANDS_HELP") print_colored blue "\nСправка:" ;;
        "COMMANDS_LIST") print_colored blue "\nСписки:" ;;
        "COMMANDS_MANAGE") print_colored blue "\nУправление:" ;;
        "COMMANDS_UPDATE") print_colored blue "\nОбновление и установка:" ;;
        "COMMANDS_MISC") print_colored blue "\nФайловая система и GitLab:" ;;
        "COMMANDS_INSTALL") print_colored blue "\nУстановка и удаление Docker и утилит:" ;;
      esac

      for key in "${!cmd_group[@]}"; do
        IFS='|' read -r func desc <<<"${cmd_group[$key]}"
        printf "    $(print_colored green "%-30s") $(print_colored yellow "%s")\n" "$key" "$desc"
      done
    fi
  done
}

function print_colored {
  local color=$1
  local text=$2
  case $color in
    red) echo -e "\033[31m$text\033[0m" ;;
    green) echo -e "\033[32m$text\033[0m" ;;
    yellow) echo -e "\033[33m$text\033[0m" ;;
    blue) echo -e "\033[34m$text\033[0m" ;;
    cyan) echo -e "\033[36m$text\033[0m" ;;
    *) echo "$text" ;;
  esac
}

function get_version {
  grep -m 1 -oP '(?<=## \[)\d+\.\d+\.\d+(?=\])' "$HOME/qq/CHANGELOG.md"
}

function script_info {
  print_colored blue "QQ Script Information"
  printf "Repository: %s\n" "$(print_colored green "https://github.com/ArturUshakov/qq")"
  printf "Creator: %s\n" "$(print_colored green "https://t.me/Mariores")"
  printf "Version: %s\n" "$(print_colored yellow "$(get_version)")"
  printf "\n"
  get_latest_tag_info
}

function get_latest_version {
  curl -s "https://raw.githubusercontent.com/ArturUshakov/qq/master/CHANGELOG.md" | grep -m 1 -oP '(?<=## \[)\d+\.\d+\.\d+(?=\])'
}

function get_latest_tag_info {
  local changelog_file="$HOME/qq/CHANGELOG.md"
  if [[ ! -f "$changelog_file" ]]; then
    print_colored red "Файл CHANGELOG.md не найден."
    return
  fi

  local latest_tag_line
  latest_tag_line=$(grep -m 1 -oP '^## \[\d+\.\d+\.\d+\] - \d{4}-\d{2}-\d{2}' "$changelog_file")
  if [[ -z "$latest_tag_line" ]]; then
    print_colored red "Тэги не найдены в файле CHANGELOG.md."
    return
  fi

  local latest_tag_index
  latest_tag_index=$(grep -n -m 1 -oP '^## \[\d+\.\d+\.\d+\] - \d{4}-\d{2}-\d{2}' "$changelog_file" | cut -d: -f1)

  local output
  output=$(sed -n "${latest_tag_index},/^## \[/p" "$changelog_file" | sed '$d')
  while IFS= read -r line; do
    if [[ $line =~ ^##\ \[([0-9]+\.[0-9]+\.[0-9]+)\]\ -\ ([0-9]{4}-[0-9]{2}-[0-9]{2})$ ]]; then
      printf "$(print_colored green "## [${BASH_REMATCH[1]}]") - $(print_colored yellow "${BASH_REMATCH[2]}")\n"
    elif [[ $line =~ ^-\ (.*) ]]; then
      printf "$(print_colored cyan "- ${BASH_REMATCH[1]}")\n"
    elif [[ $line =~ ^\ \ -\ (.*) ]]; then
      printf "  $(print_colored blue "- ${BASH_REMATCH[1]}")\n"
    else
      printf "%s\n" "$line"
    fi
  done <<< "$output"
}

function check_for_updates {
  local installed_version
  installed_version=$(get_version)
  local latest_version
  latest_version=$(get_latest_version)

  if [[ "$(printf '%s\n' "$latest_version" "$installed_version" | sort -V | head -n1)" != "$latest_version" ]]; then
    print_colored red "\nВнимание!"
    print_colored yellow "Доступна новая версия qq: $latest_version. Ваша версия: $installed_version."
    print_colored yellow "Используйте 'qq update' для обновления до последней версии."
  fi
}

function get_external_ip() {
    ifconfig | awk '/inet / && $2 !~ /^127/ {ip=$2} END {print ip}'
}


#COMMANDS_LIST
function start_filtered_containers {
  local filter="$1"
  if [[ -z "$filter" ]]; then
    print_colored red "Пожалуйста, укажите фильтр для запуска контейнеров."
    return
  fi

  local container_ids
  IFS=$'\n' read -d '' -r -a container_ids < <(docker ps -a --filter "name=$filter" --format "{{.ID}}" && printf '\0')

  if [[ ${#container_ids[@]} -eq 0 ]]; then
    print_colored red "Контейнеры, соответствующие фильтру '$filter', не найдены."
    return
  fi

  print_colored blue "Запуск контейнеров, соответствующих фильтру '$filter':"
  for container_id in "${container_ids[@]}"; do
    local container_name
    container_name=$(docker ps -a --filter "id=$container_id" --format "{{.Names}}")
    docker start "$container_id" >/dev/null
    printf "%s %s\n" "$(print_colored green "$container_name")" "$(print_colored red "Запущен")"
  done
}

function chmod_all {
  sudo chmod 777 -R .
}

function open_folder_by_name {
  local folder_name="$1"
  local folder_path
  folder_path=$(find ~ -mindepth 1 -maxdepth 3 -type d -name "$folder_name" 2>/dev/null | head -n 1)
  if [[ -z "$folder_path" ]]; then
    print_colored red "Папка не найдена."
  else
    xdg-open "$folder_path"
  fi
}

function list_running_containers {
  print_colored red "Запущенные контейнеры:"
  docker ps --format "{{.Names}}\t{{.Status}}" | while IFS=$'\t' read -r name status; do
    printf "%-55s %s\n" "$(print_colored green "$name")" "$(print_colored red "$status")"
  done
}

function list_all_containers {
  print_colored red "Все контейнеры:"
  docker ps -a --format "{{.Names}}\t{{.Status}}" | while IFS=$'\t' read -r name status; do
    printf "%-55s %s\n" "$(print_colored green "$name")" "$(print_colored red "$status")"
  done
}

function list_images {
  print_colored blue "Список образов:"
  printf "%-25s %-60s %-27s %-15s\n" "$(print_colored blue "ID")" "$(print_colored blue "РЕПОЗИТОРИЙ")" "$(print_colored blue "ТЕГ")" "$(print_colored blue "РАЗМЕР")"
  docker images --format "{{.ID}}\t{{.Repository}}\t{{.Tag}}\t{{.Size}}" | while IFS=$'\t' read -r id repository tag size; do
    printf "%-20s %-50s %-25s %-15s\n" "$(print_colored green "$id")" "$(print_colored yellow "$repository")" "$(print_colored cyan "$tag")" "$(print_colored red "$size")"
  done
}

function remove_image {
  local version="$1"
  if [[ -z "$version" ]]; then
    print_colored red "Ой! Пожалуйста, укажите версию для удаления."
    return
  fi

  if [[ "$version" == "<none>" ]]; then
    cleanup_docker_images
    return
  fi

  local images_to_remove=()
  while IFS=$'\t' read -r repository tag id; do
    if [[ "$tag" == "$version" ]]; then
      images_to_remove+=("$id")
    fi
  done < <(docker images --format "{{.Repository}}\t{{.Tag}}\t{{.ID}}")

  if [[ ${#images_to_remove[@]} -eq 0 ]]; then
    print_colored red "Образы с версией '$version' не найдены."
    return
  fi

  for image_id in "${images_to_remove[@]}"; do
    docker rmi "$image_id"
    print_colored green "Удален образ с ID: $image_id"
  done
}

function generate_password_hash {
  local password="$1"
  if [[ -z "$password" ]]; then
    print_colored red "Пожалуйста, укажите пароль для генерации хеша"
    return
  fi

  local hash
  hash=$(htpasswd -bnBC 10 "" "$password" | tr -d ':\n')
  printf "Сгенерированный хеш: %s\n" "$hash"
}

function stop_filtered_containers {
  local filter="$1"
  if [[ -z "$filter" ]]; then
    print_colored red "Пожалуйста, укажите фильтр для остановки контейнеров"
    return
  fi

  local container_ids
  IFS=$'\n' read -d '' -r -a container_ids < <(docker ps --filter "name=$filter" -q && printf '\0')

  if [[ ${#container_ids[@]} -eq 0 ]]; then
    print_colored red "Контейнеры, соответствующие фильтру '$filter', не найдены"
    return
  fi

  print_colored blue "Остановка контейнеров, соответствующих фильтру '$filter':"
  for container_id in "${container_ids[@]}"; do
    local container_name
    container_name=$(docker ps --filter "id=$container_id" --format "{{.Names}}")
    docker stop "$container_id" >/dev/null
    printf "%s %s\n" "$(print_colored green "$container_name")" "$(print_colored red "Остановлен")"
  done
}

function cleanup_docker_images {
  docker images -f "dangling=true" -q | xargs -r docker rmi
  print_colored green "Все images <none> очищены!"
}

function stop_all_containers {
  local container_ids
  IFS=$'\n' read -d '' -r -a container_ids < <(docker ps -q && printf '\0')

  if [[ ${#container_ids[@]} -eq 0 ]]; then
    print_colored red "Нет запущенных контейнеров для остановки."
    return
  fi

  print_colored blue "Остановка всех запущенных контейнеров:"
  for container_id in "${container_ids[@]}"; do
    local container_name
    container_name=$(docker ps --filter "id=$container_id" --format "{{.Names}}")
    docker stop "$container_id" >/dev/null
    printf "%s %s\n" "$(print_colored green "$container_name")" "$(print_colored red "Остановлен")"
  done
}

function update_script {
  INSTALL_DIR="$HOME/qq"
  REPO_URL="https://raw.githubusercontent.com/ArturUshakov/qq/master"

  mkdir -p "$INSTALL_DIR"

  print_colored blue "Загрузка необходимых файлов из GitHub..."

  # Список файлов для загрузки
  files=("qq.sh" "qq_completions.sh" "CHANGELOG.md" "commands.sh")

  for file in "${files[@]}"; do
    curl -s "$REPO_URL/$file" -o "$INSTALL_DIR/$file"
    if [ $? -eq 0 ]; then
      print_colored green "$file загружен успешно."
      chmod +rx "$INSTALL_DIR/$file"
    else
      print_colored red "Ошибка загрузки $file."
    fi
  done

  print_colored green "Обновление завершено."

  print_colored blue "Последние обновления:\n"
  get_latest_tag_info
}

function install_docker {
  print_colored blue "Установка Docker..."

  if command -v docker &>/dev/null; then
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
  sudo groupdel docker
  sudo systemctl disable --now docker.service docker.socket
  sudo rm /var/run/docker.sock
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
  echo "sudo chown "$USER":"$USER" /home/"$USER"/.docker -R"
  echo "sudo chmod g+rwx "$HOME/.docker" -R"
}

function delete_docker {
  sudo apt-get purge docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-ce-rootless-extras
  sudo groupdel docker
  sudo systemctl stop docker
  sudo systemctl stop containerd
  sudo systemctl disable --now docker.service docker.socket
  sudo rm /var/run/docker.sock

  print_colored green "Docker успешно удален."
}

function install_make {
  print_colored blue "Установка утилиты make..."

  if command -v make &>/dev/null; then
    print_colored green "Утилита make уже установлена."
    return
  fi

  if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    if command -v apt-get &>/dev/null; then
      sudo apt-get update && sudo apt-get install -y make
    elif command -v yum &>/dev/null; then
      sudo yum install -y make
    elif command -v pacman &>/dev/null; then
      sudo pacman -Syu make
    else
      print_colored red "Неизвестный пакетный менеджер. Установите make вручную."
      return
    fi
  elif [[ "$OSTYPE" == "darwin"* ]]; then
    if command -v brew &>/dev/null; then
      brew install make
    else
      print_colored red "Homebrew не установлен. Установите Homebrew или make вручную."
      return
    fi
  else
    print_colored red "Неизвестная операционная система. Установите make вручную."
    return
  fi

  if command -v make &>/dev/null; then
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

function re_install {
  curl -s https://raw.githubusercontent.com/ArturUshakov/qq/master/install.sh | bash
}

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
