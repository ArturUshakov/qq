# Changelog

В этом файле ведется учет изменений проекта

Формат основан на [стандарте формата CHANGELOG](https://keepachangelog.com/en/1.0.0/),
и придерживается [правил версионирования](https://semver.org/spec/v2.0.0.html).

## [1.3.5] - 2024-11-04

- Исправлено:
  - Фиксы

## [1.3.4] - 2024-10-07

- Изменено:
  - Команда -clr не удаляет остановленные сети

## [1.3.3] - 2024-10-07

- Исправлено:
  - Фиксы релиза

## [1.3.2] - 2024-10-07

- Изменено:
  - Обновление и установка

- Исправлено:
  - Ошибка когда при вызове qq без команды не вызывалась проверка версии

## [1.3.1] - 2024-10-07

- Изменено:
  - Фикс асинхронного вызова остановки контейнеров и правильный учёт времени выполнения команды
  - -clc была с русскими буквами

## [1.3.0] - 2024-10-06

- Реализовано:
  - Команда exec для выполнения команд внутри контейнера или входа в контейнер

- Изменено:
  - Удалена команда git-prune-merged

## [1.2.0] - 2024-10-05

- Реализовано:
  - -сlс, clear-last-commit Отменяет последний коммит, но оставляет изменения
  - -pmb, git-prune-merged Удаляет локальные ветки, которые уже слиты с master
  - -c, clear Выполняет очистку Docker: images <none>, builder cache, volumes, networks

## [1.1.1] - 2024-08-12

- Исправлено
  - Установка через install.sh

## [1.1.0] - 2024-08-12

- Реализовано
  - Улучшен внешний вид всех сообщений
  - Команды перемещены по функциональным группам

## [1.0.0] - 2024-08-09

- Реализовано
    - Работа скрипта переведена на использование Python
    - Добавлена паралельная обработка остановки контейнеров
    - Новый список с командами для очистки

- Удалено
    - Неиспользуемые команды

## [0.14.0] - 2024-08-01

- Реализовано
    - Все команды разнесены по файлам
    - Новый способ установки и обновления скриптов
    - Улучшен цветной вывод всех сообщений

## [0.13.0] - 2024-07-30

- Реализовано
    - Команда для отключения отслеживания гитом изменения прав файлов (-gi, git-ignore-file-mode)

## [0.12.2] - 2024-07-25

- Исправлено
    - Исправлена ошибка остановки контейнеров по фильтру
    - Исправлена ошибка генерации хэш ключа, добавлены разные варианты генерации

## [0.12.1] - 2024-07-19

- Изменено
    - Генерация хэша обрабатывается через php

## [0.12.0] - 2024-07-19

- Реализовано
    - Добавлена команда -projup,up-project для поднятия проекта по частичному названию
    - Добавлена команда -spc,stop-project-con для остановки контейнеров по частичному названию проекта

## [0.11.1] - 2024-07-18

- Реализовано
    - Вывод списков контейнеров разбит на группы проектов

## [0.11.0] - 2024-07-18

- Реализовано
    - Команды разбиты на логические блоки

## [0.10.2] - 2024-07-18

- Исправлено
    - Исправлен процесс обновления

## [0.10.1] - 2024-07-18

- Реализовано
    - Добавлена команда re-install для полной переустановки QQ
    - Сделал код более стабильным

## [0.10.0] - 2024-07-18

- Реализовано
    - Команда -ch,chmod для рекурсивного проставления прав 777 из текущей директории (требуется sudo)
    - Команда -eip,external-ip для получения ip для внешнего доступа
    - Команда -of,open-folder открывает указаную папку (поиск осуществляется от домашней директории пользователя и
      учитывает только название папки, без указания полного пути, например ".../projects/.../hr.efko.ru" будет ошибочно,
      нужно
      указывать именно hr.efko.ru)
    - Работа генерации хэша переведена на использование htpasswd

## [0.9.1] - 2024-07-17

- Реализовано
    - Добавлена проверка форматирования

## [0.9.0] - 2024-07-17

- Реализовано
    - Добавлен скрипт для автоматического создания релизов

## [0.8.3] - 2024-07-17

- Исправлено
    - Исправлен механизм обновления

## [0.8.2] - 2024-07-17

- Исправлено
    - Автодополнение работает более корректно

## [0.8.1] - 2024-07-17

- Реализовано
    - Улучшено автодополнение, теперь при наборе qq down,-d при нажатии на tab будет подсказывать имена поднятых
      контейнеров
    - При наборе qq -ri и нажатии на tab будет подсказывать все доступные версии тэгов
    - Добавлена команда для удаления докера
    - Команда для установки докера обновлена

## [0.8.0] - 2024-07-16

- Исправлено
    - Метод для остановки всех контейнеров
    - -sc переименовано в up
    - qq без параметров выводит список доступных команд
    - qq down или -d выполняет отключение всех контейнеров
    - qq down <имя> или -d <имя> выключает с фильтрацией

## [0.7.3] - 2024-07-16

- Исправлено
    - Метод остановки контейнеров изменён

## [0.7.2] - 2024-07-16

- Реализовано
    - Похожие команды выводятся через запятую для qq -h
    - Добавлена более умная проверка версии

## [0.7.1] - 2024-07-16

- Реализовано
    - Команда -dni удаляет все <none> images

## [0.7.0] - 2024-07-15

- Реализовано
    - Автодополнение команд
    - Переписанный вывод в консоль и работа всех функций

## [0.6.0] - 2024-07-15

- Реализовано
    - Много новых команд и возможностей

## [0.5.2] - 2024-07-15

- Реализовано
    - Добавлены новые команды и возможности

## [0.5.1] - 2024-07-15

- Исправлено
    - Исправлены консольные выводы

## [0.5.0] - 2024-07-15

- Реализовано
    - Команда -gph [пароль] для создания хэш пароля

## [0.4.0] - 2024-07-15

- Исправлено
    - Исправлено получение версии
- Реализовано
    - Создание директории для скрипта

## [0.3.2] - 2024-07-15

- Исправлено:
    - Исправлен вывод информации об обновлении

## [0.3.1] - 2024-07-15

- Исправлено:
    - Исправлен вывод в консоль процесса установки
    - Исправлена проверка на обновления

## [0.3.0] - 2024-07-15

- Реализовано:
    - Добавлена команда для обновления
    - Добавлена проверка на актуальность версии скрипта

## [0.2.1] - 2024-07-15

- Реализовано:
    - Улучшен процесс вывода всех контейнеров

## [0.2.0] - 2024-07-15

- Реализовано:
    - Улучшен процесс установки

## [0.1.0] - 2024-07-15

- Реализовано:
    - Начальная версия скрипта `qq.sh` для управления Docker-контейнерами
    - Скрипт установки `install-qq.sh`, который добавляет алиас `qq` для выполнения `qq.sh`
    - Команды для помощи, списка контейнеров и остановки контейнеров
