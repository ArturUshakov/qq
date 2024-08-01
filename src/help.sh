# Команды справки
function print_help {
  for group in $(compgen -A variable); do
    declare -p "$group" 2>/dev/null | grep -q 'declare -A' || continue
    declare -n cmd_group="$group"
    case $group in
      "COMMANDS_HELP") print_colored bright_blue "\n==================== Справка ====================" ;;
      "COMMANDS_LIST") print_colored bright_blue "\n==================== Списки =====================" ;;
      "COMMANDS_MANAGE") print_colored bright_blue "\n================== Управление ===================" ;;
      "COMMANDS_UPDATE") print_colored bright_blue "\n========== Обновление и установка ==============" ;;
      "COMMANDS_MISC") print_colored bright_blue "\n========= Файловая система и GitLab ============" ;;
      "COMMANDS_INSTALL") print_colored bright_blue "\n==== Установка и удаление Docker и утилит ======" ;;
    esac

    for key in "${!cmd_group[@]}"; do
      IFS='|' read -r func desc <<<"${cmd_group[$key]}"
      printf "    $(print_colored bright_green "%-30s") $(print_colored bright_yellow "%s")\n" "$key" "$desc"
    done
  done
}

function stop_filtered_containers {
    if [ -z "$1" ]; then
        print_colored bright_red "Пожалуйста, укажите фильтр для остановки контейнеров."
        return
    fi

    local filter="$1"
    local container_ids=($(docker ps --filter "name=$filter" -q))

    if [ ${#container_ids[@]} -eq 0 ]; then
        print_colored bright_red "Контейнеры, соответствующие фильтру '$filter', не найдены."
        return
    fi

    print_colored bright_blue "Остановка контейнеров, соответствующих фильтру $(print_colored bright_yellow "$filter"):"
    print_colored bright_blue "-----------------------------------------------------------"

    for container_id in "${container_ids[@]}"; do
        local container_name=$(docker ps --filter "id=$container_id" --format "{{.Names}}")
        docker stop "$container_id" > /dev/null
        printf "%s %s\n" "$(print_colored bright_green "$container_name")" "$(print_colored bright_red "остановлен")"
    done
    print_colored bright_blue "-----------------------------------------------------------"
}

function open_gitlab {
  xdg-open "https://gitlab.efko.ru"
}

function git_ignore_file_mode {
    git config core.fileMode false
}
