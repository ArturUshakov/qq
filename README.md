### README (Russian)

# Проект: `qq.sh` - Скрипт для управления Docker-контейнерами

## Обзор

`qq.sh` - это скрипт, предназначенный для упрощения управления Docker-контейнерами. Он предоставляет набор команд,
которые помогают пользователям запускать, останавливать и управлять контейнерами Docker. Скрипт также включает функции
автодополнения для улучшения пользовательского опыта.

## Особенности

- Автодополнение команд
- Запуск, остановка и управление Docker-контейнерами
- Улучшенный вывод в консоль
- Проверка версий и обновления
- Команда для создания хэшированных паролей

## Установка

Для установки скрипта выполните следующую команду:

```bash
curl -s https://raw.githubusercontent.com/ArturUshakov/qq/master/install.sh | bash
```

или после скачивания файла `install.sh`

```bash
bash install.sh
```

Это создаст алиас `qq` для скрипта, что позволит вам использовать команду `qq` в терминале.

## Использование

Вот некоторые из основных доступных команд:

- `qq -h`: Показать справку со списком доступных команд
- `qq up`: Запустить все контейнеры
- `qq down`: Остановить все контейнеры
- `qq down <имя>`: Остановить конкретный контейнер или контейнеры по фильтру
- `qq -li`: Показать список images
- `qq -l`:  Показать список запущенных контейнеров
- `qq -gph <пароль>`: Создать хэш пароля

Для более подробного использования обратитесь к команде помощи:

```bash
qq -h
```

## Список изменений

Список изменений и обновлений см. в файле `CHANGELOG.md`.

### README (English)

# Project: `qq.sh` - Docker Container Management Script

## Overview

`qq.sh` is a script designed for managing Docker containers with ease. It provides a set of commands to help users
start, stop, and manage their Docker containers efficiently. The script also includes auto-completion features to
enhance the user experience.

## Features

- Auto-completion for commands
- Starting, stopping, and managing Docker containers
- Enhanced console output
- Version checking and updates
- Command to generate hashed passwords

## Installation

To install the script, run the following command:

```bash
curl -s https://raw.githubusercontent.com/ArturUshakov/qq/master/install.sh | bash
```

or

```bash
bash install.sh
```

This will create an alias `qq` for the script, enabling you to use the `qq` command in your terminal.

## Usage

Here are some of the main commands available:

- `qq -h`: Display help with a list of available commands
- `qq up`: Start all containers
- `qq down`: Stop all containers
- `qq down <name>`: Stop a specific container
- `qq -rmi`: Display available tag versions
- `qq -gph <password>`: Generate a hashed password

For more detailed usage, refer to the help command:

```bash
qq -h
```

## Changelog

Refer to the `CHANGELOG.md` file for a detailed list of changes and updates.

---
