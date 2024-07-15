#!/usr/bin/env bash

set -Eeuo pipefail

# Функция для вывода цветного текста
print_colored() {
    echo -e "\033[${1}m${2}\033[0m"
}

# Проверка наличия Docker
if ! command -v docker &> /dev/null; then
    print_colored "31" "Docker не найден. Установите Docker и повторите попытку."
    exit 1
fi

# Цвета для вывода
RED="31"
GREEN="32"
YELLOW="33"
BLUE="34"
CIAN="36"
WHITE="37"

# Путь к скрипту и файлу версии
script_dir="$HOME/qq"
script_path="$script_dir/qq.sh"
alias_file="$HOME/.bash_aliases"
[ ! -f "$alias_file" ] && alias_file="$HOME/.bashrc"

# Создание папки для скрипта, если она не существует
mkdir -p "$script_dir"

# Удаление существующего алиаса и создание нового
if grep -q "alias qq=" "$alias_file"; then
    sed -i '/alias qq=/d' "$alias_file"
fi

# Создание скрипта qq.sh
curl -o "$script_path" "https://raw.githubusercontent.com/ArturUshakov/qq/master/qq.sh"

chmod u+x "$script_path"

echo "alias qq='$script_path'" >> "$alias_file"

print_colored "$GREEN" "Установка завершена\n"
print_colored "$YELLOW" "Если вы скачали скрипт впервые, то выполните команду:"
print_colored "$BLUE" "source ~/.bashrc\n"
print_colored "$YELLOW" "Для получения помощи по qq выполните:"
print_colored "$BLUE" "qq -h"
