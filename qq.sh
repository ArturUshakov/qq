#!/usr/bin/env bash

set -Eeuo pipefail

VERSION=0.6.0

# Цвета для вывода
NOANSI="\033[0m"
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
BLUE="\033[34m"
CIAN="\033[36m"
WHITE="\033[37m"

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
  ["--install-docker"]="install_docker"
  ["--install-make"]="install_make"
  ["--gitlab"]="open_gitlab"
  ["--update"]="update"
  ["-li"]="list_images"
  ["--list-images"]="list_images"
  ["-ri"]="remove_image_with_version"
  ["--remove-image"]="remove_image_with_version"
  ["--prune-builder"]="prune_builder"
  ["-pb"]="prune_builder"
)

trap 'echo -e "$RED[ERROR] Произошла ошибка$NOANSI"' ERR

stderr() {
  local message=$*
  echo -e "$message" >&2
  exit 1
}

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
    stdout "$RED\nВНИМАНИЕ!$NOANSI\n$WHITEДоступна новая версия скрипта ($latest_version)$NOANSI\n$WHITEПожалуйста, обновите скрипт командой:$NOANSI\n$CIAN qq --update$NOANSI"
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
  echo "$version" >"$HOME/qq/version.txt"
  stdout "$YELLOW\nДля обновления скрипта запустите новый терминал или выполните команду:$NOANSI\n$CIAN source ~/.bashrc$NOANSI"
}

show_help() {
  local cmd_descriptions=(
    "qq -h, --help            Выводит это сообщение"
    "qq -l, --list            Выводит список запущенных контейнеров"
    "qq -la, --list-all       Выводит список всех контейнеров"
    "qq -li, --list-images    Выводит список всех образов"
    "qq -ri [image] [version] Удаляет образ с версией"
    "qq -i, --info            Выводит информацию о скрипте"
    "qq -gph [password]       Генерирует хэш пароля"
    "qq [фильтр]              Останавливает все контейнеры, соответствующие фильтру"
    "qq                       Останавливает все запущенные контейнеры"
    "qq --update              Выполняет обновление qq до актуальной версии"
    "qq --install-docker      Выполняет полную установку докера"
    "qq --install-make        Выполняет установку утилиты make"
    "qq --gitlab              Открывает страницу gitlab.efko.ru"
    "qq -pb, --prune-builder  Удаляет неиспользуемые объекты сборки"
  )

  local max_length=0
  for cmd in "${cmd_descriptions[@]}"; do
    local length=${#cmd}
    ((length > max_length)) && max_length=$length
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
    mapfile -t container_ids <<<"$containers"
    mapfile -t names < <(docker inspect --format "{{.Name}}" "${container_ids[@]}" | cut -c2-)
    for i in "${!container_ids[@]}"; do
      local container=${container_ids[$i]}
      if [[ -z "$filter" || "${names[$i]}" == *"$filter"* ]]; then
        docker "$action" "$container" >/dev/null 2>&1 &
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

list_images() {
  local images=$(docker images -q)
  if [ -n "$images" ]; then
    mapfile -t image_ids <<<"$images"
    mapfile -t names < <(docker inspect --format "{{.RepoTags}}" "${image_ids[@]}" | cut -c2-)
    for name in "${names[@]}"; do
      stdout "$GREEN[INFO] Образ: $CIAN${name}$NOANSI"
    done
  else
    stdout "$RED[END] Нет образов$NOANSI"
  fi
}

remove_image_with_version() {
  local image_name=$1
  local version=$2
  local full_image_name="${image_name}:${version}"

  if docker images "$full_image_name" | grep -q "$version"; then
    docker rmi "$full_image_name"
    stdout "$GREEN[INFO] Образ $CIAN$full_image_name$NOANSI успешно удален$NOANSI"
  else
    stdout "$RED[ERROR] Образ $CIAN$full_image_name$NOANSI не найден$NOANSI"
  fi
}

prune_builder() {
  stdout "$YELLOW[WARNING] Это удалит все неиспользуемые объекты сборки. Продолжить? (y/N)$NOANSI"
  read -r confirmation
  case "$confirmation" in
    [yY][eE][sS]|[yY])
      docker builder prune -f
      stdout "$GREEN[INFO] Неиспользуемые объекты сборки удалены$NOANSI"
      ;;
    *)
      stdout "$RED[INFO] Отменено пользователем$NOANSI"
      ;;
  esac
}

stop_containers() {
  docker_action "stop"
}

list_containers() {
  local containers=$(docker ps -q)
  if [ -n "$containers" ]; then
    mapfile -t container_ids <<<"$containers"
    mapfile -t names < <(docker inspect --format "{{.Name}}" "${container_ids[@]}" | cut -c2-)
    for name in "${names[@]}"; do
      stdout "$GREEN[ACTIVE] Контейнер: $CIAN${name}$NOANSI"
    done
  else
    stdout "$RED[END] Нет запущенных контейнеров$NOANSI"
    stdout "Для просмотра всех контейнеров выполните $YELLOW qq -la$NOANSI"
  fi
}

install_docker() {
  if ! command -v docker >/dev/null; then
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh ./get-docker.sh --dry-run
    sudo groupadd docker
    sudo usermod -aG docker $USER
    newgrp docker
    sudo chown "$USER":"$USER" /home/"$USER"/.docker -R
    sudo chmod g+rwx "$HOME/.docker" -R
    docker run hello-world
    sudo systemctl enable docker.service
    sudo systemctl enable containerd.service

  fi
}

install_make() {
  sudo apt update
  sudo apt install make
  make --version
}

open_gitlab() {
  xdg-open https://gitlab.efko.ru
}

list_all_containers() {
  local containers=$(docker ps -a -q)
  if [ -n "$containers" ]; then
    mapfile -t container_ids <<<"$containers"
    mapfile -t names < <(docker inspect --format "{{.Name}}" "${container_ids[@]}" | cut -c2-)

    printf "%-55s\n" "---------------------------------------------------------"
    printf "| %-40s | %-10s |\n" "Container Name" "Status"
    printf "%-55s\n" "---------------------------------------------------------"

    for i in "${!container_ids[@]}"; do
      local status=$(docker inspect --format "{{.State.Status}}" "${container_ids[$i]}")
      local status_text="STOP"
      local status_color="\033[31m" # Red for STOP
      if [[ "$status" == "running" ]]; then
        status_text="ACTIVE"
        status_color="\033[32m" # Green for ACTIVE
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
  local opts="-h --help -l --list -la --list-all -gph --generate-password-hash -i --info --update --install-docker --install-make --gitlab"
  COMPREPLY=($(compgen -W "${opts}" -- ${curr_arg}))
}

complete -F _qq_completions qq

main() {
  declare -A container_names
  pids=()
  filter=""

  if [[ "${1}" == "--update" ]]; then
  update
  exit 0;
  fi

  if [[ "$#" -eq 0 ]]; then
    stdout "$BLUE[START] Начинаем остановку всех контейнеров...$NOANSI"
    stop_containers
    check_containers
    stdout "$BLUE[FINISH] Процесс завершен$NOANSI"
    check_version
    exit 0
  elif [[ "${1:-}" =~ ^- ]]; then
    if [[ -n "${commands["${1:-}"]+isset}" ]]; then
      ${commands["${1:-}"]} "${2:-}"
      check_version
      exit 0
    else
      stdout "$RED[ERROR] Неизвестный флаг или опция. Выполните 'qq -h' для помощи.$NOANSI"
      exit 1
    fi
  else
    filter="$1"
    stdout "$BLUE[START] Начинаем остановку контейнеров с фильтром: $CIAN$filter$NOANSI"
    stop_containers
    check_containers
    stdout "$BLUE[FINISH] Процесс завершен$NOANSI"
    check_version
    exit 0
  fi
}

main "$@"
