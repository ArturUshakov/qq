#!/bin/bash

REPO_URL="https://github.com/ArturUshakov/qq.git"
INSTALL_DIR="$HOME/qq"
EXECUTABLE="$INSTALL_DIR/qq"
COMPLETIONS_SCRIPT="$INSTALL_DIR/qq_completions.sh"
BASHRC="$HOME/.bashrc"
BASH_ALIASES="$HOME/.bash_aliases"

add_or_update_alias() {
    local alias_file="$1"
    local alias_name="qq"
    local alias_cmd="alias $alias_name='$EXECUTABLE'"

    if grep -q "alias $alias_name=" "$alias_file"; then
        sed -i "s|alias $alias_name=.*|$alias_cmd|" "$alias_file"
        echo "Алиас '$alias_name' обновлен в $alias_file."
    else
        echo "$alias_cmd" >> "$alias_file"
        echo "Алиас '$alias_name' добавлен в $alias_file."
    fi
}

add_completion() {
    local completion_file="$1"

    if ! grep -q "$COMPLETIONS_SCRIPT" "$completion_file"; then
        echo "source $COMPLETIONS_SCRIPT" >> "$completion_file"
        echo "Автодополнение добавлено в $completion_file."
    fi
}

if [ -d "$INSTALL_DIR" ]; then
    echo "Папка $INSTALL_DIR уже существует. Обновляем существующую версию..."
    cd "$INSTALL_DIR"
    git fetch origin
    git checkout master
    git reset --hard origin/master
else
    echo "Клонирование репозитория..."
     git clone --branch feature/QQ-2024 "$REPO_URL" "$INSTALL_DIR"
fi

cd "$INSTALL_DIR"

if [ -f "$BASH_ALIASES" ]; then
    add_or_update_alias "$BASH_ALIASES"
    add_completion "$BASH_ALIASES"
else
    add_or_update_alias "$BASHRC"
    add_completion "$BASHRC"
fi

source "$BASHRC"

echo "Установка завершена! Вы можете использовать команду 'qq' для запуска приложения."
