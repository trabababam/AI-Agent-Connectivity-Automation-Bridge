#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
cd "$SCRIPT_DIR"

if [[ $EUID -eq 0 ]]; then
    echo "Не запускай установщик от root или через sudo." >&2
    echo "Запусти ./install.sh от обычного пользователя." >&2
    exit 1
fi

for file in ai-agent-connectivity-automation-bridge.py requirements.txt start-ai-agent-connectivity-automation-bridge.sh; do
    if [[ ! -f "$SCRIPT_DIR/$file" ]]; then
        echo "Не найден обязательный файл: $file" >&2
        exit 1
    fi
done

command -v sudo >/dev/null 2>&1 || {
    echo "Для установки системных пакетов необходим sudo." >&2
    exit 1
}

command -v apt-get >/dev/null 2>&1 || {
    echo "Требуется Debian или Ubuntu с apt-get." >&2
    exit 1
}

echo "=== Обновление списка пакетов ==="
sudo apt-get update

echo
echo "=== Установка системных зависимостей ==="
sudo apt-get install -y ca-certificates python3 python3-venv python3-pip gnome-terminal

echo
echo "=== Создание виртуального окружения ==="
if [[ ! -x .venv/bin/python ]]; then
    python3 -m venv .venv
fi

echo
echo "=== Установка Python-зависимостей ==="
.venv/bin/python -m pip install -r requirements.txt

if [[ -f .bridge-token ]]; then
    chmod 600 .bridge-token
fi

chmod +x "$SCRIPT_DIR/start-ai-agent-connectivity-automation-bridge.sh"

echo
echo "=== Настройка автозапуска GNOME ==="
AUTOSTART_DIR="$HOME/.config/autostart"
mkdir -p "$AUTOSTART_DIR"

cat > "$AUTOSTART_DIR/ai-agent-connectivity-automation-bridge.desktop" <<DESKTOP
[Desktop Entry]
Type=Application
Name=AI Agent Connectivity Automation Bridge
Comment=Local AI tools connectivity server
Exec=gnome-terminal -- "$SCRIPT_DIR/start-ai-agent-connectivity-automation-bridge.sh"
Terminal=false
X-GNOME-Autostart-enabled=true
DESKTOP

chmod 644 "$AUTOSTART_DIR/ai-agent-connectivity-automation-bridge.desktop"

echo
echo "Установка завершена."
echo "Автозапуск GNOME настроен."
echo "Сервер запускается в отдельном окне терминала."
echo
echo "Для остановки сервера нажми Ctrl+C в его окне."
echo "Для ручного запуска используй:"
echo "$SCRIPT_DIR/start-ai-agent-connectivity-automation-bridge.sh"

gnome-terminal -- "$SCRIPT_DIR/start-ai-agent-connectivity-automation-bridge.sh"
