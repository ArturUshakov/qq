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

function open_gitlab {
  xdg-open "https://gitlab.efko.ru"
}

function git_ignore_file_mode {
    git config core.fileMode false
}
