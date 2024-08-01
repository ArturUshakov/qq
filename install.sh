#!/bin/bash

INSTALL_DIR="$HOME/qq"
TEMP_DIR="$HOME/qq_temp"
REPO_URL="https://github.com/ArturUshakov/qq/archive/refs/heads/master.zip"
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

update_file() {
  grep -q "$2" "$1" || echo "$2" >>"$1"
}

# Скачивание и распаковка архива
mkdir -p "$INSTALL_DIR"
mkdir -p "$TEMP_DIR"

print_colored blue "Загрузка архива из GitHub..."
curl -L -o "$TEMP_DIR/master.zip" "$REPO_URL"
if [ $? -eq 0 ]; then
  print_colored green "Архив загружен успешно."
else
  print_colored red "Ошибка загрузки архива."
  exit 1
fi

print_colored blue "Распаковка архива..."
unzip -q "$TEMP_DIR/master.zip" -d "$TEMP_DIR"
if [ $? -eq 0 ]; then
  print_colored green "Архив распакован успешно."
else
  print_colored red "Ошибка распаковки архива."
  exit 1
fi

print_colored blue "Копирование файлов..."
cp -r "$TEMP_DIR/qq-master/." "$INSTALL_DIR"
if [ $? -eq 0 ]; then
  print_colored green "Файлы скопированы успешно."
  chmod +rx "$INSTALL_DIR"/*
else
  print_colored red "Ошибка копирования файлов."
  exit 1
fi

print_colored blue "Удаление ненужных файлов..."
find "$INSTALL_DIR" -mindepth 1 -maxdepth 1 ! -name 'src' ! -name 'CHANGELOG.md' ! -name 'commands.sh' ! -name 'qq.config' ! -name 'qq.sh' ! -name 'qq_completions.sh' -exec rm -rf {} +
if [ $? -eq 0 ]; then
  print_colored green "Ненужные файлы удалены успешно."
else
  print_colored red "Ошибка удаления ненужных файлов."
  exit 1
fi

# Обновление алиасов
if [ -f "$HOME/.bash_aliases" ]; then
  ALIAS_FILE="$HOME/.bash_aliases"
else
  ALIAS_FILE="$HOME/.bashrc"
fi

update_file "$ALIAS_FILE" "$ALIAS_CMD"
update_file "$ALIAS_FILE" "$COMPLETION_CMD"

source "$HOME/.bashrc"
[ -f "$HOME/.bash_aliases" ] && source "$HOME/.bash_aliases"

# Очистка временной директории
rm -rf "$TEMP_DIR"

print_colored green "Установка завершена."
