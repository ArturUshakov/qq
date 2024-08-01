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

  if command -v htpasswd >/dev/null 2>&1; then
    local hash
    hash=$(htpasswd -bnBC 10 "" "$password" | tr -d ':\n')
    printf "Сгенерированный хеш: %s\n" "$hash"
  elif command -v php >/dev/null 2>&1; then
    local hash
    hash=$(php -r "echo password_hash('$password', PASSWORD_DEFAULT);")
    printf "Сгенерированный хеш: %s\n" "$hash"
  elif command -v openssl >/dev/null 2>&1; then
    local hash
    hash=$(openssl passwd -6 "$password")
    printf "Сгенерированный хеш: %s\n" "$hash"
  else
    print_colored red "Команды htpasswd, PHP и OpenSSL не найдены. Установите одну из них для генерации хеша."
  fi
}

