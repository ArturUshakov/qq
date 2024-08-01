# Команды установки и удаления
function install_docker {
  print_colored blue "Установка Docker..."

  if command -v docker &>/dev/null; then
    print_colored green "Docker уже установлен."
    return
  fi

  curl -fsSL https://get.docker.com -o get-docker.sh
  if [ $? -ne 0 ]; then
    print_colored red "Ошибка загрузки установочного скрипта Docker."
    return
  fi

  sudo sh ./get-docker.sh --dry-run
  if [ $? -ne 0 ]; then
    print_colored red "Ошибка выполнения предварительной проверки установки Docker."
    return
  fi

  sudo sh ./get-docker.sh
  if [ $? -ne 0 ]; then
    print_colored red "Ошибка установки Docker."
    return
  fi

  sudo groupdel docker
  sudo systemctl disable --now docker.service docker.socket
  sudo rm /var/run/docker.sock
  sudo groupadd docker
  if [ $? -ne 0 ]; then
    print_colored yellow "Группа docker уже существует или возникла ошибка при создании группы."
  else
    print_colored green "Группа docker создана успешно."
  fi

  sudo usermod -aG docker $USER
  if [ $? -ne 0 ]; then
    print_colored red "Ошибка добавления пользователя в группу docker."
    return
  fi

  newgrp docker
  if [ $? -ne 0 ]; then
    print_colored red "Ошибка обновления групп для текущего сеанса."
    return
  fi

  docker run hello-world
  if [ $? -ne 0 ]; then
    print_colored red "Ошибка запуска тестового контейнера. Проверьте установку Docker вручную."
    return
  fi

  sudo systemctl enable docker.service
  sudo systemctl enable containerd.service
  if [ $? -ne 0 ]; then
    print_colored red "Ошибка включения сервисов Docker и containerd."
    return
  fi

  print_colored green "Docker успешно установлен и настроен."

  print_colored yellow "Если вы запускали команды Docker CLI с помощью sudo до добавления пользователя в группу docker, выполните следующие команды для решения проблемы с правами доступа:"
  echo "sudo chown "$USER":"$USER" /home/"$USER"/.docker -R"
  echo "sudo chmod g+rwx "$HOME/.docker" -R"
}

function delete_docker {
  sudo apt-get purge docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-ce-rootless-extras
  sudo groupdel docker
  sudo systemctl stop docker
  sudo systemctl stop containerd
  sudo systemctl disable --now docker.service docker.socket
  sudo rm /var/run/docker.sock

  print_colored green "Docker успешно удален."
}

function install_make {
  print_colored blue "Установка утилиты make..."

  if command -v make &>/dev/null; then
    print_colored green "Утилита make уже установлена."
    return
  fi

  if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    if command -v apt-get &>/dev/null; then
      sudo apt-get update && sudo apt-get install -y make
    elif command -v yum &>/dev/null; then
      sudo yum install -y make
    elif command -v pacman &>/dev/null; then
      sudo pacman -Syu make
    else
      print_colored red "Неизвестный пакетный менеджер. Установите make вручную."
      return
    fi
  elif [[ "$OSTYPE" == "darwin"* ]]; then
    if command -v brew &>/dev/null; then
      brew install make
    else
      print_colored red "Homebrew не установлен. Установите Homebrew или make вручную."
      return
    fi
  else
    print_colored red "Неизвестная операционная система. Установите make вручную."
    return
  fi

  if command -v make &>/dev/null; then
    print_colored green "Утилита make успешно установлена."
  else
    print_colored red "Ошибка установки утилиты make."
  fi
}

function update_script {
  INSTALL_DIR="$HOME/qq"
  REPO_URL="https://github.com/ArturUshakov/qq/archive/refs/heads/master.zip"
  TEMP_DIR="$HOME/qq_temp"

  mkdir -p "$INSTALL_DIR"
  mkdir -p "$TEMP_DIR"

  print_colored blue "Загрузка архива из GitHub..."

  curl -L -o "$TEMP_DIR/master.zip" "$REPO_URL"
  if [ $? -eq 0 ]; then
    print_colored green "Архив загружен успешно."
  else
    print_colored red "Ошибка загрузки архива."
    return
  fi

  print_colored blue "Распаковка архива..."
  unzip -q "$TEMP_DIR/master.zip" -d "$TEMP_DIR"
  if [ $? -eq 0 ]; then
    print_colored green "Архив распакован успешно."
  else
    print_colored red "Ошибка распаковки архива."
    return
  fi

  print_colored blue "Копирование файлов..."
  cp -r "$TEMP_DIR/qq-master/." "$INSTALL_DIR"
  if [ $? -eq 0 ]; then
    print_colored green "Файлы скопированы успешно."
    chmod +rx "$INSTALL_DIR"/*
  else
    print_colored red "Ошибка копирования файлов."
    return
  fi

  print_colored blue "Удаление ненужных файлов..."
  find "$INSTALL_DIR" -mindepth 1 -maxdepth 1 ! -name 'src' ! -name 'CHANGELOG.md' ! -name 'commands.sh' ! -name 'qq.config' ! -name 'qq.sh' ! -name 'qq_completions.sh' -exec rm -rf {} +
  if [ $? -eq 0 ]; then
    print_colored green "Ненужные файлы удалены успешно."
  else
    print_colored red "Ошибка удаления ненужных файлов."
    return
  fi

  print_colored green "Обновление завершено."

  print_colored blue "Последние обновления:\n"
  get_latest_tag_info

  # Очистка временной директории
  rm -rf "$TEMP_DIR"
}

function re_install {
  curl -s https://raw.githubusercontent.com/ArturUshakov/qq/master/install.sh | bash
}
