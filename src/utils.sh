# Вспомогательные функции
function print_colored {
  local reset="\033[0m"
  local color=$1
  local text=$2
  declare -A colors=(
    [black]="\033[30m"
    [red]="\033[31m"
    [green]="\033[32m"
    [yellow]="\033[33m"
    [blue]="\033[34m"
    [magenta]="\033[35m"
    [cyan]="\033[36m"
    [white]="\033[37m"
    [bright_black]="\033[90m"
    [bright_red]="\033[91m"
    [bright_green]="\033[92m"
    [bright_yellow]="\033[93m"
    [bright_blue]="\033[94m"
    [bright_magenta]="\033[95m"
    [bright_cyan]="\033[96m"
    [bright_white]="\033[97m"
    [bg_black]="\033[40m"
    [bg_red]="\033[41m"
    [bg_green]="\033[42m"
    [bg_yellow]="\033[43m"
    [bg_blue]="\033[44m"
    [bg_magenta]="\033[45m"
    [bg_cyan]="\033[46m"
    [bg_white]="\033[47m"
    [bg_bright_black]="\033[100m"
    [bg_bright_red]="\033[101m"
    [bg_bright_green]="\033[102m"
    [bg_bright_yellow]="\033[103m"
    [bg_bright_blue]="\033[104m"
    [bg_bright_magenta]="\033[105m"
    [bg_bright_cyan]="\033[106m"
    [bg_bright_white]="\033[107m"
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

  if [[ "$(printf '%s\n' "$latest_version" "$installed_version" | sort -V | head -n1)" != "$latest_version" ]]; then
    print_colored bright_red "\nВнимание!"
    print_colored bright_yellow "Доступна новая версия qq: $latest_version. Ваша версия: $installed_version."
    print_colored bright_yellow "Используйте 'qq update' для обновления до последней версии."
  fi
}

function process_tag_line {
  local line="$1"
  if [[ $line =~ ^##\ \[([0-9]+\.[0-9]+\.[0-9]+)\]\ -\ ([0-9]{4}-[0-9]{2}-[0-9]{2})$ ]]; then
    printf "$(print_colored bright_green "## [${BASH_REMATCH[1]}]") - $(print_colored bright_yellow "${BASH_REMATCH[2]}")\n"
  elif [[ $line =~ ^-\ (.*) ]]; then
    printf "$(print_colored bright_cyan "- ${BASH_REMATCH[1]}")\n"
  elif [[ $line =~ ^\ \ -\ (.*) ]]; then
    printf "  $(print_colored bright_blue "- ${BASH_REMATCH[1]}")\n"
  else
    printf "%s\n" "$line"
  fi
}

# Утилиты
function chmod_all {
  sudo chmod 777 -R .
  print_colored bright_green "Все файлы и директории в текущей папке получили права 777."
}

function open_folder_by_name {
  local folder_name="$1"
  local folder_path
  folder_path=$(find ~ -mindepth 1 -maxdepth 3 -type d -name "$folder_name" 2>/dev/null | head -n 1)
  if [[ -z "$folder_path" ]]; then
    print_colored bright_red "Папка не найдена."
  else
    xdg-open "$folder_path"
    print_colored bright_green "Папка '$folder_name' открыта."
  fi
}

function generate_password_hash {
  local password="$1"
  if [[ -z "$password" ]]; then
    print_colored bright_red "Пожалуйста, укажите пароль для генерации хеша"
    return
  fi

  local hash
  if command -v htpasswd >/dev/null 2>&1; then
    hash=$(htpasswd -bnBC 10 "" "$password" | tr -d ':\n')
  elif command -v php >/dev/null 2>&1; then
    hash=$(php -r "echo password_hash('$password', PASSWORD_DEFAULT);")
  elif command -v openssl >/dev/null 2>&1; then
    hash=$(openssl passwd -6 "$password")
  else
    print_colored bright_red "Команды htpasswd, PHP и OpenSSL не найдены. Установите одну из них для генерации хеша."
    return
  fi

  print_colored bright_green "Сгенерированный хеш: $hash"
}
