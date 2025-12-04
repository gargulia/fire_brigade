#!/bin/bash

# Цвета ANSI Escape Codes
GREEN_TEXT="\e[32m"   # Зеленый текст
YELLOW_TEXT="\e[33m"  # Желтый текст (для предупреждений)
BLUE_TEXT="\e[34m"    # Синий текст (для системных сообщений)
RED_TEXT="\e[31m"     # Красный текст (для ошибок)
RESET="\e[0m"         # Сброс цветов

# Настройки
# UUID="F45E33F75E33B16A" # Замените на реальный UUID вашего диска /dev/sdc1
MOUNT_POINT="$HOME/external_drive"
# DEVICE="/dev/sdc1"

# --- Функции для форматирования ---

# Функция для вычисления длины строки (работает с UTF-8)
string_length() {
  echo -n "$1" | wc -m
}

# Функция для центрирования текста в терминале
# Принимает текст и максимальную длину контента для центрирования
center_text() {
  local text="$1"
  local content_max_length="$2" # Максимальная длина строки, вокруг которой центрируем
  local terminal_width=$(tput cols)

  # Если ширина терминала меньше максимальной длины контента, не центрируем
  if [[ "$terminal_width" -lt "$content_max_length" ]]; then
    echo "$text"
    return
  fi

  local text_len=$(string_length "$text")
  local dynamic_padding_left=$(( (terminal_width - content_max_length) / 2 ))

  # Корректируем отступ для самого текста, чтобы он был центрован относительно _точки_ где должен быть контент
  local final_padding_left=$(( dynamic_padding_left + (content_max_length - text_len) / 2 ))

  printf "%*s%s\n" "$final_padding_left" "" "$text"
}

# Функция для вывода отформатированного текста с цветом и переносом строки
print_formatted() {
  local color="$1"
  local text="$2"
  echo -e "${color}${text}${RESET}"
}

# Функция для вывода текста с переносом строки, но без цвета
print_plain() {
  echo "$1"  # Просто выводит текст с переносом строки
}

# --- Конец функций для форматирования ---


# --- ОСНОВНАЯ ЛОГИКА СКРИПТА ---

# ASCII арт
ascii_art=(
"db   db  d888888b                d888b     d8b    d8888b    d888b   db    db  db       d888888b    d8b"
"  88   88     88                  88  Y8b  d8   8b  88   8D  88  Y8b  88    88  88          88     d8   8b"
"  88ooo88     88                  88       88ooo88  88oobY   88       88    88  88          88     88ooo88"
"  88   88     88                  88  ooo  88~~~88  88 8b    88  ooo  88    88  88          88     88~~~88"
"  88   88     88         db       88   8   88   88  88  88   88   8   88b  d88  88booo      88     88   88"
"  YP   YP  Y888888P       V8       Y888P   YP   YP  88   YD   Y888P    Y8888P   Y88888P  Y888888P  YP   YP"
""
"               Note: This time I did it at 00:39 on Sunday, October 19, 2025"
)
# Находим максимальную длину строки в ASCII-арте
max_length=0
for line in "${ascii_art[@]}"; do
  line_length=$(string_length "$line")
  if [ "$line_length" -gt "$max_length" ]; then
    max_length="$line_length"
  fi
done


# Определяем ASCII-арт котика
cat_art=(
"      /\\_/\\"
"     ( o.o )"
"      > v < "
)

# Находим максимальную длину строки в ASCII-арте котика
CAT_MAX_LENGTH=0
for line in "${cat_art[@]}"; do
  line_length=$(string_length "$line")
  if [ "$line_length" -gt "$CAT_MAX_LENGTH" ]; then
    CAT_MAX_LENGTH="$line_length"
  fi
done


# Проверка и создание точки монтирования, если она не существует
if [ ! -d "$MOUNT_POINT" ]; then
  print_formatted "$YELLOW_TEXT" "Точка монтирования ${MOUNT_POINT} не существует. Создаю..."
  mkdir -p "$MOUNT_POINT"
  if [ $? -ne 0 ]; then
    print_formatted "$RED_TEXT" "Ошибка: Не удалось создать точку монтирования ${MOUNT_POINT}. Проверьте права."
    exit 1
  fi
fi

# Функция для монтирования диска
mount_disk() {
    if mountpoint -q "$MOUNT_POINT"; then
        print_formatted "$BLUE_TEXT" "Диск уже смонтирован в ${MOUNT_POINT}"
        return 0
    else
        mount -t ntfs "$DEVICE" "$MOUNT_POINT" 2>/dev/null # Монтируем выбранное устройство
        if [ $? -eq 0 ]; then
            print_formatted "$GREEN_TEXT" "Диск успешно смонтирован в ${MOUNT_POINT}"
            print_plain "" # Добавляем пустой echo для переноса строки перед котом
            for line in "${cat_art[@]}"; do
                center_text "$line" "$CAT_MAX_LENGTH"
            done
            return 0
        else
            print_formatted "$RED_TEXT" "Ошибка при монтировании диска. Проверьте права доступа и тип файловой системы (ntfs)."
            return 1
        fi
    fi
}


# Функция для демонтирования диска
umount_disk() {
  if ! mountpoint -q "$MOUNT_POINT"; then
    print_formatted "$BLUE_TEXT" "Диск не смонтирован в ${MOUNT_POINT}"
    return 0
  else
    umount "$MOUNT_POINT" 2>/dev/null # Перенаправляем stderr
    if [ $? -eq 0 ]; then
      print_formatted "$GREEN_TEXT" "Диск успешно демонтирован из ${MOUNT_POINT}"
      return 0
    else
      print_formatted "$YELLOW_TEXT" "Ошибка при демонтировании диска. Возможно, диск занят."
      print_formatted "$YELLOW_TEXT" "Попытка принудительного демонтирования..."
      fuser -km "$MOUNT_POINT" >/dev/null 2>&1 # Убить процессы, использующие точку монтирования
      sleep 1 # Дать время процессам завершиться
      umount -l "$MOUNT_POINT" >/dev/null 2>&1 # Lazy unmount
      if [ $? -eq 0 ]; then
         print_formatted "$GREEN_TEXT" "Диск успешно демонтирован из ${MOUNT_POINT} (принудительно)."
         return 0
      else
         print_formatted "$RED_TEXT" "Ошибка: Не удалось демонтировать диск даже принудительно."
         return 1
      fi
    fi
  fi
}

# Очистка экрана для начала работы, если терминал поддерживает
clear >/dev/null 2>&1

# Вывод каждой строки ASCII-арта с центрированием и зеленым цветом
# Выводим его перед основными функциями
for line in "${ascii_art[@]}"; do
  centered_text=$(center_text "$line" "$max_length")  # Передаем также max_length
  print_formatted "$GREEN_TEXT" "$centered_text"
done

# Вывод информации о блочных устройствах
print_formatted "$BLUE_TEXT" "Доступные блочные устройства:"
lsblk -f

# Запрос у пользователя имени устройства
read -p "$(print_formatted "$YELLOW_TEXT" "Введите имя устройства (например, /dev/sdb1): ")" DEVICE

# Проверка, что устройство указано
if [ -z "$DEVICE" ]; then
    print_formatted "$RED_TEXT" "Ошибка: Имя устройства не указано. Скрипт завершен."
    exit 1
fi

if [ ! -b "$DEVICE" ]; then
    print_formatted "$RED_TEXT" "Ошибка: Указанное устройство ${DEVICE} не является блочным устройством или не существует. Скрипт завершен."
    exit 1
fi


# Запрос действия у пользователя: монтировать или демонтировать
PS3=$'\e[33mВыберите действие: \e[0m'
select ACTION in "Смонтировать диск" "Демонтировать диск" "Выйти"; do
    case $ACTION in
        "Смонтировать диск")
            print_formatted "$BLUE_TEXT" "Вы уверены, что хотите смонтировать диск ${DEVICE} в ${MOUNT_POINT}?"
            read -n 1 -s -r -p "$(print_formatted "$YELLOW_TEXT" "Нажмите любую клавишу для продолжения или Ctrl+C для отмены...")"
            print_plain ""  # Добавляем перенос строки после нажатия клавиши
            mount_disk
            break
            ;;
        "Демонтировать диск")
            print_formatted "$BLUE_TEXT" "Вы уверены, что хотите демонтировать диск из ${MOUNT_POINT}?"
            read -n 1 -s -r -p "$(print_formatted "$YELLOW_TEXT" "Нажмите любую клавишу для продолжения или Ctrl+C для отмены...")"
            print_plain ""  # Добавляем перенос строки после нажатия клавиши
            umount_disk
            break
            ;;
        "Выйти")
            print_formatted "$BLUE_TEXT" "Выход."
            exit 0
            ;;
        *) print_formatted "$YELLOW_TEXT" "Неверный выбор. Пожалуйста, выберите один из предложенных вариантов.";;
    esac
done
