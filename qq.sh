#!/bin/bash

source $HOME/qq/commands.sh

# Вспомогательные функции
function print_colored {
  local reset="\033[0m"
  local color=$1
  local text=$2
  declare -A colors=(
    [red]="\033[31m"
    [green]="\033[32m"
    [yellow]="\033[33m"
    [blue]="\033[34m"
    [cyan]="\033[36m"
  )
  echo -e "${colors[$color]:-}$text$reset"
}

function get_version {
  grep -m 1 -Po '(?<=## \[)\d+\.\d+\.\d+(?=\])' "$HOME/qq/CHANGELOG.md"
}

function get_latest_version {
  curl -s "https://raw.githubusercontent.com/ArturUshakov/qq/master/CHANGELOG.md" | grep -m 1 -Po '(?<=## \[)\d+\.\d+\.\d+(?=\])'
}

function check_for_updates {
  local installed_version
  installed_version=$(get_version)
  local latest_version
  latest_version=$(get_latest_version)

  [[ "$(printf '%s\n' "$latest_version" "$installed_version" | sort -V | head -n1)" == "$latest_version" ]] && return

  print_colored red "\nВнимание!"
  print_colored yellow "Доступна новая версия qq: $latest_version. Ваша версия: $installed_version."
  print_colored yellow "Используйте 'qq update' для обновления до последней версии."
}

function process_tag_line {
  local line="$1"
  if [[ $line =~ ^##\ \[([0-9]+\.[0-9]+\.[0-9]+)\]\ -\ ([0-9]{4}-[0-9]{2}-[0-9]{2})$ ]]; then
    printf "$(print_colored green "## [${BASH_REMATCH[1]}]") - $(print_colored yellow "${BASH_REMATCH[2]}")\n"
  elif [[ $line =~ ^-\ (.*) ]]; then
    printf "$(print_colored cyan "- ${BASH_REMATCH[1]}")\n"
  elif [[ $line =~ ^\ \ -\ (.*) ]]; then
    printf "  $(print_colored blue "- ${BASH_REMATCH[1]}")\n"
  else
    printf "%s\n" "$line"
  fi
}

function get_latest_tag_info {
  local changelog_file="$HOME/qq/CHANGELOG.md"
  [[ ! -f "$changelog_file" ]] && { print_colored red "Файл CHANGELOG.md не найден."; return; }

  local latest_tag_line
  latest_tag_line=$(grep -m 1 -oP '^## \[\d+\.\d+\.\d+\] - \d{4}-\d{2}-\d{2}' "$changelog_file")
  [[ -z "$latest_tag_line" ]] && { print_colored red "Тэги не найдены в файле CHANGELOG.md."; return; }

  local latest_tag_index
  latest_tag_index=$(grep -n -m 1 -oP '^## \[\d+\.\d+\.\d+\] - \d{4}-\d{2}-\d{2}' "$changelog_file" | cut -d: -f1)

  local output
  output=$(sed -n "${latest_tag_index},/^## \[/p" "$changelog_file" | sed '$d')
  while IFS= read -r line; do
    process_tag_line "$line"
  done <<< "$output"
}

# Команды справки
function print_help {
  for group in $(compgen -A variable); do
    declare -p "$group" 2>/dev/null | grep -q 'declare -A' || continue
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
  done
}

# Команды информации
function script_info {
  local version
  version=$(get_version)

  print_colored blue "==================== QQ Script Information ===================="
  printf "Repository: %s\n" "$(print_colored green "https://github.com/ArturUshakov/qq")"
  printf "Creator: %s\n" "$(print_colored green "https://t.me/Mariores")"
  printf "Version: %s\n" "$(print_colored yellow "$version")"
  print_colored red "Latest Changes:\n"
  get_latest_tag_info
  print_colored blue "===============================================================\n"
}

function get_external_ip {
  ifconfig | awk '/inet / && $2 !~ /^127/ {ip=$2} END {print ip}'
}

# Команды управления контейнерами
function stop_project_containers {
  local partial_name="$1"
  if [[ -z "$partial_name" ]]; then
    print_colored red "Пожалуйста, укажите часть имени проекта для остановки контейнеров."
    return
  fi

  local projects
  projects=$(docker compose ls --format json | jq -r --arg partial_name "$partial_name" '.[] | select(.Name | contains($partial_name)) | .Name')

  if [[ -z "$projects" ]]; then
    print_colored red "Проекты, содержащие '$partial_name', не найдены."
    return
  fi

  for project in $projects; do
    print_colored blue "Остановка контейнеров для проекта '$project'..."
    if ! docker compose -p "$project" down; then
      print_colored red "Ошибка остановки контейнеров для проекта '$project'."
    else
      print_colored green "Контейнеры для проекта '$project' успешно остановлены."
    fi
  done
}

function start_project_containers {
  local partial_name="$1"
  if [[ -z "$partial_name" ]]; then
    print_colored red "Пожалуйста, укажите часть имени проекта для запуска контейнеров."
    return
  fi

  local projects
  projects=$(docker compose ls --format json | jq -r --arg partial_name "$partial_name" '.[] | select(.Name | contains($partial_name)) | .Name')

  if [[ -z "$projects" ]]; then
    print_colored red "Проекты, содержащие '$partial_name', не найдены. Ищем в папке projects..."
    local project_dir
    project_dir=$(find ~/projects -maxdepth 1 -type d -name "*$partial_name*" -print -quit)

    if [[ -z "$project_dir" ]]; then
      print_colored red "Папка проекта, содержащая '$partial_name', не найдена."
      return
    fi

    print_colored blue "Папка проекта найдена: $project_dir. Выполнение 'make up'..."
    (cd "$project_dir" && make up)

    if [[ $? -ne 0 ]]; then
      print_colored red "Ошибка выполнения 'make up' в папке '$project_dir'."
    else
      print_colored green "'make up' выполнено успешно в папке '$project_dir'."
    fi

    return
  fi

  for project in $projects; do
    print_colored blue "Запуск контейнеров для проекта '$project'..."
    if ! docker compose -p "$project" up -d; then
      print_colored red "Ошибка запуска контейнеров для проекта '$project'."
    else
      print_colored green "Контейнеры для проекта '$project' успешно запущены."
    fi
  done
}

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

function list_containers {
  local filter="$1"
  local title="$2"
  local format="$3"

  declare -A compose_projects

  while IFS=$'\t' read -r name status project; do
    compose_projects["$project"]+="${name}\t${status}\n"
  done < <(docker ps $filter --format "$format")

  for project in "${!compose_projects[@]}"; do
    print_colored blue "\nПроект: $project"
    while IFS=$'\t' read -r name status; do
      printf "%-55s %s\n" "$(print_colored green "$name")" "$(print_colored red "$status")"
    done <<< "${compose_projects["$project"]}"
  done
}

function list_running_containers {
  list_containers "" "Запущенные контейнеры" "{{.Names}}\t{{.Status}}\t{{.Label \"com.docker.compose.project\"}}"
}

function list_all_containers {
  list_containers "-a" "Все контейнеры" "{{.Names}}\t{{.Status}}\t{{.Label \"com.docker.compose.project\"}}"
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

function cleanup_docker_images {
  docker images -f "dangling=true" -q | xargs -r docker rmi
  print_colored green "Все images <none> очищены!"
}

# Утилиты
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

# Команды установки и удаления
function install_docker {
  print_colored blue "Установка Docker..."

  if command -v docker &>/dev/null; then
    print_colored green "Docker уже установлен."
    return
  fi

  curl -fsSL https://get.docker.com -o get-docker.sh
  if [ $? -ne 0 ]; then
    print_colored red "Ошибка загрузки установочного скрипта Docker."
    return
  fi

  sudo sh ./get-docker.sh --dry-run
  if [ $? -ne 0 ]; then
    print_colored red "Ошибка выполнения предварительной проверки установки Docker."
    return
  fi

  sudo sh ./get-docker.sh
  if [ $? -ne 0 ]; then
    print_colored red "Ошибка установки Docker."
    return
  fi

  sudo groupdel docker
  sudo systemctl disable --now docker.service docker.socket
  sudo rm /var/run/docker.sock
  sudo groupadd docker
  if [ $? -ne 0 ]; then
    print_colored yellow "Группа docker уже существует или возникла ошибка при создании группы."
  else
    print_colored green "Группа docker создана успешно."
  fi

  sudo usermod -aG docker $USER
  if [ $? -ne 0 ]; then
    print_colored red "Ошибка добавления пользователя в группу docker."
    return
  fi

  newgrp docker
  if [ $? -ne 0 ]; then
    print_colored red "Ошибка обновления групп для текущего сеанса."
    return
  fi

  docker run hello-world
  if [ $? -ne 0 ]; then
    print_colored red "Ошибка запуска тестового контейнера. Проверьте установку Docker вручную."
    return
  fi

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

function update_script {
  INSTALL_DIR="$HOME/qq"
  REPO_URL="https://raw.githubusercontent.com/ArturUshakov/qq/master"

  mkdir -p "$INSTALL_DIR"

  print_colored blue "Загрузка необходимых файлов из GitHub..."

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

function re_install {
  curl -s https://raw.githubusercontent.com/ArturUshakov/qq/master/install.sh | bash
}

function prune_builder {
  docker builder prune -f
}

function open_gitlab {
  xdg-open "https://gitlab.efko.ru"
}

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
