#!/bin/bash

INSTALL_DIR="$HOME/qq"
REPO_URL="https://raw.githubusercontent.com/ArturUshakov/qq/master"

function print_colored {
  local color_code
  case "$1" in
  red)
    color_code="31"
    ;;
  green)
    color_code="32"
    ;;
  yellow)
    color_code="33"
    ;;
  blue)
    color_code="34"
    ;;
  *)
    color_code="0" # default color
    ;;
  esac
  shift
  echo -e "\e[${color_code}m$*\e[0m"
}

# Создаем директорию для установки, если она не существует
mkdir -p "$INSTALL_DIR"

print_colored blue "Загрузка необходимых файлов из GitHub..."

# Список файлов для загрузки
files=("qq.sh" "qq_completions.sh" "CHANGELOG.md" "commands.sh")

for file in "${files[@]}"; do
  curl -s "$REPO_URL/$file" -o "$INSTALL_DIR/$file"
  if [ $? -eq 0 ]; then
    print_colored green "$file загружен успешно."
    chmod +rx "$INSTALL_DIR/$file"
  else
    print_colored red "Ошибка загрузки $file."
  fi
done

# Определяем абсолютный путь к скрипту
QQ_SCRIPT="$INSTALL_DIR/qq.sh"
COMPLETION_SCRIPT="$INSTALL_DIR/qq_completions.sh"

# Функция для добавления alias
add_alias() {
  ALIAS_FILE="$1"
  ALIAS_CMD="alias qq='$QQ_SCRIPT'"

  if grep -q "alias qq=" "$ALIAS_FILE"; then
    sed -i "/alias qq=/c\\$ALIAS_CMD" "$ALIAS_FILE"
  else
    echo "$ALIAS_CMD" >>"$ALIAS_FILE"
  fi
}

# Функция для добавления автодополнения
add_completion() {
  COMPLETION_CMD="source $COMPLETION_SCRIPT"

  if grep -q "$COMPLETION_CMD" "$1"; then
    echo ""
  else
    echo "$COMPLETION_CMD" >>"$1"
  fi
}

# Основной процесс установки
if [ -f "$HOME/.bash_aliases" ]; then
  add_alias "$HOME/.bash_aliases"
  add_completion "$HOME/.bash_aliases"
else
  add_alias "$HOME/.bashrc"
  add_completion "$HOME/.bashrc"
fi

# Перезагрузка настроек
source "$HOME/.bashrc"
[ -f "$HOME/.bash_aliases" ] && source "$HOME/.bash_aliases"

print_colored green "Установка завершена."
