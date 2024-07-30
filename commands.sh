#!/bin/bash

init_commands() {
  # Команды справки и информации
  declare -gA COMMANDS_HELP=(
    ["-h,help,qq"]="print_help|Выводит это сообщение"
    ["-i,info"]="script_info|Выводит информацию о скрипте"
  )

  # Команды для работы с контейнерами
  declare -gA COMMANDS_LIST=(
    ["-l,list"]="list_running_containers|Выводит список запущенных контейнеров докера"
    ["-la,list-all"]="list_all_containers|Выводит список всех контейнеров"
    ["-li,list-images"]="list_images|Выводит список всех образов"
    ["-eip,external-ip"]="get_external_ip|Выводит ip для внешнего доступа"
    ["-spc,stop-project-con"]="stop_project_containers|Останавливает контейнеры по названию проекта"
  )

  # Команды для управления контейнерами и докером
  declare -gA COMMANDS_MANAGE=(
    ["-d,down"]="stop_all_containers|Останавливает все запущенные контейнеры"
    ["-dni"]="cleanup_docker_images|Удаляет <none> images"
    ["-pb,prune-builder"]="prune_builder|Удаляет неиспользуемые объекты сборки"
    ["-gph,generate-password-hash"]="generate_password_hash|Генерирует хэш пароля"
    ["-ri"]="remove_image|Удаляет образ по <версии>"
    ["-ch,chmod"]="chmod_all|Рекурсивно выставляет права 777 с директории выполнения"
    ["up"]="start_filtered_containers|Запускает контейнеры по фильтру <имя>"
    ["-projup,up-project"]="start_project_containers|Запускает контейнеры по фильтру <проекта>"
  )

  # Команды для обновления и установки
  declare -gA COMMANDS_UPDATE=(
    ["update"]="update_script|Выполняет обновление qq до актуальной версии"
    ["re-install"]="re_install|Заново устанавливает QQ"
  )

  # Команды для работы с файловой системой и GitLab
  declare -gA COMMANDS_MISC=(
    ["-of,open-folder"]="open_folder_by_name|Открывает указаную папку"
    ["-gl,gitlab"]="open_gitlab|Открывает страницу gitlab.efko.ru"
    ["-gi,git-ignore-file-mode"]="git_ignore_file_mode|Выключает отслеживание изменения прав гитом"
  )

  # Команды для установки и удаления Docker и утилит
  declare -gA COMMANDS_INSTALL=(
    ["-dd,delete-docker"]="delete_docker|Удаляет докер"
    ["-id,install-docker"]="install_docker|Выполняет полную установку докера"
    ["-im,install-make"]="install_make|Выполняет установку утилиты make"
  )
}

init_commands
