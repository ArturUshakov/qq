#!/bin/bash

INSTALL_DIR="$HOME/qq"
REPO_URL="https://raw.githubusercontent.com/ArturUshakov/qq/master"
FILES=("qq.sh" "qq_completions.sh" "CHANGELOG.md" "commands.sh")
QQ_SCRIPT="$INSTALL_DIR/qq.sh"
COMPLETION_SCRIPT="$INSTALL_DIR/qq_completions.sh"
ALIAS_CMD="alias qq='$QQ_SCRIPT'"
COMPLETION_CMD="source $COMPLETION_SCRIPT"

print_colored() {
  local color_code
  case "$1" in
  red) color_code="31" ;;
  green) color_code="32" ;;
  yellow) color_code="33" ;;
  blue) color_code="34" ;;
  *) color_code="0" ;;
  esac
  shift
  echo -e "\e[${color_code}m$*\e[0m"
}

download_file() {
  curl -s "$REPO_URL/$1" -o "$INSTALL_DIR/$1"
  if [ $? -eq 0 ]; then
    print_colored green "$1 загружен успешно."
    chmod +rx "$INSTALL_DIR/$1"
  else
    print_colored red "Ошибка загрузки $1."
  fi
}

update_file() {
  grep -q "$2" "$1" || echo "$2" >>"$1"
}

mkdir -p "$INSTALL_DIR"
print_colored blue "Загрузка необходимых файлов из GitHub..."

for file in "${FILES[@]}"; do
  download_file "$file"
done

if [ -f "$HOME/.bash_aliases" ]; then
  ALIAS_FILE="$HOME/.bash_aliases"
else
  ALIAS_FILE="$HOME/.bashrc"
fi

update_file "$ALIAS_FILE" "$ALIAS_CMD"
update_file "$ALIAS_FILE" "$COMPLETION_CMD"

source "$HOME/.bashrc"
[ -f "$HOME/.bash_aliases" ] && source "$HOME/.bash_aliases"

print_colored green "Установка завершена."
