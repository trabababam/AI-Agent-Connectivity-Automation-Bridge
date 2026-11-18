#!/usr/bin/env bash
set -u
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
cd "$SCRIPT_DIR" || exit 1

if [[ ! -x .venv/bin/python ]]; then
    echo "Виртуальное окружение не найдено. Сначала запусти install.sh."
    exit 1
fi

.venv/bin/python ai-agent-connectivity-automation-bridge.py
status=$?
printf '\nСервер остановлен (код %s). Нажми Enter для закрытия окна...' "$status"
read -r
exit "$status"
