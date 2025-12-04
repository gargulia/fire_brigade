#!/bin/bash

# Цвета ANSI Escape Codes
GREEN_TEXT="\e[32m"   # Зеленый текст
RESET="\e[0m"         # Сброс цветов

# Функция для вычисления длины строки
string_length() {
  echo -n "$1" | wc -m
}

# Функция для центрирования текста в терминале
center_text() {
  local text="$1"
  local terminal_width=$(tput cols)
  local padding=$(( (terminal_width - max_length) / 2 ))
  printf "%*s%s%*s" "$padding" "" "$text" "$((terminal_width - padding - ${#text}))" ""
}

# Функция для вывода отформатированного текста
print_formatted() {
  local text="$1"
  echo -e "${GREEN_TEXT}${text}${RESET}"
}

# Очистка экрана
clear

# ASCII арт
ascii_art=(
"db   db  d888888b                d888b     d8b    d8888b    d888b   db    db  db       d888888b    d8b"
"88   88     88                  88  Y8b  d8   8b  88   8D  88  Y8b  88    88  88          88     d8   8b"
"88ooo88     88                  88       88ooo88  88oobY   88       88    88  88          88     88ooo88"
"88   88     88                  88  ooo  88~~~88  88 8b    88  ooo  88    88  88          88     88~~~88"
"88   88     88         db       88   8   88   88  88  88   88   8   88b  d88  88booo      88     88   88"
"YP   YP  Y888888P       V8       Y888P   YP   YP  88   YD   Y888P    Y8888P   Y88888P  Y888888P  YP   YP"
""
"                                                    Maintainer: Gargulia"
""
"                                 Note: Ok, is my work to 02:30 a.m. next day it ASCII-grafic"
)

# Находим максимальную длину строки в ASCII-арте
max_length=0
for line in "${ascii_art[@]}"; do
  line_length=$(string_length "$line")
  if [ "$line_length" -gt "$max_length" ]; then
    max_length="$line_length"
  fi
done

# Вывод каждой строки ASCII-арта с центрированием и зеленым цветом
for line in "${ascii_art[@]}"; do
  centered_text=$(center_text "$line")
  print_formatted "$centered_text"
done

# Вывод фиксированного текста после ASCII-графики
echo "Упс! Мышь снова умерла. Давай допуск на работу."

# Попытка перезапустить диспетчер отображения
systemctl restart display-manager 2>/dev/null

if [ $? -eq 0 ]; then
  echo "Диспетчер отображения успешно перезапущен."
else
  echo "Не удалось перезапустить диспетчер отображения. Проверьте права и журнал ошибок."
  echo "Возможно, потребуется войти в систему через TTY (Ctrl+Alt+F1) и выполнить перезапуск вручную."
fi

exit 0
