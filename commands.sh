#!/bin/bash

declare -A COMMANDS_HELP=(
  ["-h,help,qq"]="print_help|Выводит это сообщение"
  ["-i,info"]="script_info|Выводит информацию о скрипте"
  ["re-intall"]="re_install|Заново устанавливает QQ"
)

declare -A COMMANDS_LIST=(
  ["-l,list"]="list_running_containers|Выводит список запущенных контейнеров докера"
  ["-la,list-all"]="list_all_containers|Выводит список всех контейнеров"
  ["-li,list-images"]="list_images|Выводит список всех образов"
  ["-eip,external-ip"]="get_external_ip|Выводит ip для внешнего доступа"
)

declare -A COMMANDS_MANAGE=(
  ["-ri"]="remove_image|Удаляет образ по <версии>"
  ["-of,open-folder"]="open_folder_by_name|Открывает указаную папку"
  ["-ch,chmod"]="chmod_all|Рекурсивно выставляет права 777 с места выполнения"
  ["-gph,generate-password-hash"]="generate_password_hash|Генерирует хэш пароля"
  ["-d,down"]="stop_all_containers|Останавливает все запущенные контейнеры"
  ["update"]="update_script|Выполняет обновление qq до актуальной версии"
  ["-id,install-docker"]="install_docker|Выполняет полную установку докера"
  ["-im,install-make"]="install_make|Выполняет установку утилиты make"
  ["-gl,gitlab"]="open_gitlab|Открывает страницу gitlab.efko.ru"
  ["-pb,prune-builder"]="prune_builder|Удаляет неиспользуемые объекты сборки"
  ["up"]="start_filtered_containers|Запускает контейнеры по фильтру <имя>"
  ["-dni"]="cleanup_docker_images|Удаляет <none> images"
  ["-dd,delete-docker"]="delete_docker|Удаляет докер"
)
