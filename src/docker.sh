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

function prune_builder {
  docker builder prune -f
}
