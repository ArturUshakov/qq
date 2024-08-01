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
