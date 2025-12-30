#!/bin/bash

# Проверяем, запущен ли скрипт от root или через sudo
if [ "$EUID" -ne 0 ]; then
    echo "Ошибка: запустите скрипт с sudo или как root."
    exit 1
fi

# 1. Создаём папку temp
TEMP_DIR="/tmp/mac-tahoe-setup"
echo "Создаём временную папку: $TEMP_DIR"
mkdir -p "$TEMP_DIR"

# 2. Скачиваем проекты с GitHub
echo "Скачиваем темы с GitHub..."
git clone https://github.com/vinceliuice/MacTahoe-icon-theme "$TEMP_DIR/MacTahoe-icon-theme"
git clone https://github.com/vinceliuice/MacTahoe-gtk-theme "$TEMP_DIR/MacTahoe-gtk-theme"

if [ ! -d "$TEMP_DIR/MacTahoe-icon-theme" ] || [ ! -d "$TEMP_DIR/MacTahoe-gtk-theme" ]; then
    echo "Ошибка: не удалось скачать проекты с GitHub."
    exit 1
fi

# 3. Устанавливаем тему и иконки
echo "Устанавливаем GTK-тему..."
cd "$TEMP_DIR/MacTahoe-gtk-theme" && ./install.sh


echo "Устанавливаем иконки..."
cd "$TEMP_DIR/MacTahoe-icon-theme" && ./install.sh

# Если скрипты установки требуют аргументов (например, --dest), уточните их в документации проекта


# 4. Включаем иконки (через gsettings)
echo "Применяем тему и иконки..."
gsettings set org.gnome.desktop.interface gtk-theme "MacTahoe"
gsettings set org.gnome.desktop.interface icon-theme "MacTahoe"

# Для GNOME Shell (если используется)
gsettings set org.gnome.shell.extensions.user-theme.name "MacTahoe"


# 5. Копируем дополнительные иконки в /usr/share/icons/MacTahoe
echo "Копируем дополнительные иконки..."
if [ -d "icons" ]; then
    cp -r "$TEMP_DIR/icons/"* /usr/share/icons/MacTahoe/ 2>/dev/null || \
        echo "Предупреждение: папка icons не найдена или не скопирована."
else
    echo "Папка icons не найдена в $TEMP_DIR. Пропускаем копирование."
fi

# 6. Копируем .desktop-файлы в локальную папку приложений
DESKTOP_DIR="desktops"
LOCAL_APPS="/home/vladislav/.local/share/applications"

echo "Копируем .desktop-файлы в $LOCAL_APPS..."
if [ -d "$DESKTOP_DIR" ]; then
    cp -r "$DESKTOP_DIR/"*.desktop "$LOCAL_APPS" 2>/dev/null || \
        echo "Ошибка: не удалось скопировать .desktop-файлы."
else
    echo "Папка desktops не найдена в $TEMP_DIR. Пропускаем копирование."
fi

# 7. Перемещаем док-панель вниз и отключаем режим панели (для GNOME/Dash to Dock)
echo "Настраиваем док-панель..."

# Устанавливаем Dash to Dock, если не установлен
if ! dpkg -l | grep -q dash-to-dock; then
    echo "Dash to Dock не установлен. Устанавливаем..."
    sudo apt update
    sudo apt install -y gnome-shell-extension-dash-to-dock
fi

# Включаем расширение
gnome-extensions enable dash-to-dock@micxgx.gmail.com

# Настройки док-панели через gsettings
gsettings set org.gnome.shell.extensions.dash-to-dock dock-position 'BOTTOM'
gsettings set org.gnome.shell.extensions.dash-to-dock dock-fixed false
gsettings set org.gnome.shell.extensions.dash-to-dock autohide false

echo "Настройка завершена!"
echo "Перезагрузите GNOME (Alt+F2 → r → Enter) или систему для применения изменений."

