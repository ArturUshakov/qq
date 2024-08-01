# Команды информации
function script_info {
  local version
  version=$(get_version)

  print_colored bright_blue "==============================================================="
  print_colored bright_blue "                       QQ Script Information                    "
  print_colored bright_blue "==============================================================="
  printf "%-15s %s\n" "$(print_colored bright_white "Repository:")" "$(print_colored bright_green "https://github.com/ArturUshakov/qq")"
  printf "%-15s %s\n" "$(print_colored bright_white "Creator:")" "$(print_colored bright_green "https://t.me/Mariores")"
  printf "%-15s %s\n" "$(print_colored bright_white "Version:")" "$(print_colored bright_yellow "$version")"
  print_colored bright_red "Latest Changes:"
  get_latest_tag_info
  print_colored bright_blue "===============================================================\n"
}

function get_external_ip {
  ifconfig | awk '/inet / && $2 !~ /^127/ {ip=$2} END {print ip}'
}

function get_latest_tag_info {
  local changelog_file="$HOME/qq/CHANGELOG.md"
  [[ ! -f "$changelog_file" ]] && { print_colored bright_red "Файл CHANGELOG.md не найден."; return; }

  local latest_tag_line
  latest_tag_line=$(grep -m 1 -oP '^## \[\d+\.\d+\.\d+\] - \d{4}-\d{2}-\d{2}' "$changelog_file")
  [[ -z "$latest_tag_line" ]] && { print_colored bright_red "Тэги не найдены в файле CHANGELOG.md."; return; }

  local latest_tag_index
  latest_tag_index=$(grep -n -m 1 -oP '^## \[\d+\.\d+\.\d+\] - \d{4}-\d{2}-\d{2}' "$changelog_file" | cut -d: -f1)

  local output
  output=$(sed -n "${latest_tag_index},/^## \[/p" "$changelog_file" | sed '$d')
  print_colored bright_blue "Последние изменения:"
  while IFS= read -r line; do
    process_tag_line "$line"
  done <<< "$output"
}

function process_tag_line {
  local line="$1"
  if [[ $line =~ ^##\ \[([0-9]+\.[0-9]+\.[0-9]+)\]\ -\ ([0-9]{4}-[0-9]{2}-[0-9]{2})$ ]]; then
    printf "%s %s\n" "$(print_colored bright_green "## [${BASH_REMATCH[1]}]")" "$(print_colored bright_yellow "${BASH_REMATCH[2]}")"
  elif [[ $line =~ ^-\ (.*) ]]; then
    printf "  %s\n" "$(print_colored bright_blue "- ${BASH_REMATCH[1]}")"
  elif [[ $line =~ ^\ \ -\ (.*) ]]; then
    printf "    %s\n" "$(print_colored bright_blue "- ${BASH_REMATCH[1]}")"
  else
    printf "%s\n" "$line"
  fi
}

