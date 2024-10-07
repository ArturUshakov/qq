#!/bin/bash

USER_HOME=$(eval echo ~${SUDO_USER:-$USER})
INSTALL_DIR="$USER_HOME/qq"
EXECUTABLE="$INSTALL_DIR/qq"
COMPLETIONS_SCRIPT="$INSTALL_DIR/qq_completions.sh"
BASHRC="$USER_HOME/.bashrc"
BASH_ALIASES="$USER_HOME/.bash_aliases"
RELEASE_URL="https://api.github.com/repos/ArturUshakov/qq/releases/latest"

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

{
    if [ ! -d "$INSTALL_DIR" ]; then
        mkdir -p "$INSTALL_DIR"
        echo "Папка $INSTALL_DIR создана."
    else
        echo "Папка $INSTALL_DIR уже существует. Удаляем старую версию..."
        rm -rf "$INSTALL_DIR"
        mkdir -p "$INSTALL_DIR"
    fi

    echo "Получение информации о последнем релизе..."
    latest_release=$(curl -s $RELEASE_URL | grep zipball_url | cut -d '"' -f 4)
    archive_name=$(basename "$latest_release")

    echo "Скачивание последнего релиза..."
    curl -L "$latest_release" -o "$INSTALL_DIR/$archive_name"

    echo "Распаковка релиза..."
    if unzip "$INSTALL_DIR/$archive_name" -d "$INSTALL_DIR"; then
        rm "$INSTALL_DIR/$archive_name"

        temp_dir=$(find "$INSTALL_DIR" -mindepth 1 -maxdepth 1 -type d -name "ArturUshakov-qq-*")
        if [ -d "$temp_dir" ]; then
            mv "$temp_dir"/* "$INSTALL_DIR/"
            rm -rf "$temp_dir"
        else
            echo "Ошибка: временная папка не найдена."
            exit 1
        fi
    else
        echo "Ошибка при распаковке архива."
        exit 1
    fi

    echo "Выставление прав на папку $INSTALL_DIR..."
    sudo chmod 777 -R "$INSTALL_DIR"

    echo "Удаление ненужных файлов..."
    rm -rf "$INSTALL_DIR/.github" "$INSTALL_DIR/README.md" "$INSTALL_DIR/.gitignore"

} || {
    echo "Ошибка при установке."
    exit 1
}

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
