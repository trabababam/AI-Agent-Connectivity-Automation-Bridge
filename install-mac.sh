#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
cd "$SCRIPT_DIR"

# ---------- Цвета (только если stdout — TTY) ----------
if [[ -t 1 ]]; then
    C_RESET="\033[0m"; C_BOLD="\033[1m"; C_DIM="\033[2m"
    C_RED="\033[31m"; C_GREEN="\033[32m"; C_YELLOW="\033[33m"
    C_BLUE="\033[34m"; C_MAGENTA="\033[35m"; C_CYAN="\033[36m"; C_GRAY="\033[90m"
else
    C_RESET=""; C_BOLD=""; C_DIM=""
    C_RED=""; C_GREEN=""; C_YELLOW=""
    C_BLUE=""; C_MAGENTA=""; C_CYAN=""; C_GRAY=""
fi

info()  { echo -e "${C_BLUE}[INFO]${C_RESET} $*"; }
ok()    { echo -e "${C_GREEN}[ OK ]${C_RESET} $*"; }
warn()  { echo -e "${C_YELLOW}[WARN]${C_RESET} $*"; }
err()   { echo -e "${C_RED}[FAIL]${C_RESET} $*" >&2; }
step()  { echo; echo -e "${C_CYAN}${C_BOLD}=== $* ===${C_RESET}"; }

# ---------- Проверка: не root ----------
if [[ $EUID -eq 0 ]]; then
    err "Не запускай установщик от root или через sudo."
    err "Запусти ./install-mac.sh от обычного пользователя."
    exit 1
fi

# ---------- Проверка обязательных файлов ----------
for file in ai-agent-connectivity-automation-bridge-mac.py requirements.txt start-ai-agent-connectivity-automation-bridge-mac.sh; do
    if [[ ! -f "$SCRIPT_DIR/$file" ]]; then
        err "Не найден обязательный файл: $file"
        err "Сначала создай его (см. инструкцию)."
        exit 1
    fi
done
ok "Обязательные файлы на месте."

# ---------- Проверка: мы на macOS ----------
if [[ "$(uname -s)" != "Darwin" ]]; then
    err "Этот установщик предназначен для macOS."
    err "Для Linux используй ./install.sh"
    exit 1
fi
ok "Обнаружена macOS: $(sw_vers -productVersion 2>/dev/null || echo '?')"

# ---------- Homebrew ----------
step "Проверка Homebrew"
if ! command -v brew >/dev/null 2>&1; then
    warn "Homebrew не найден."
    echo
    echo -e "${C_YELLOW}Homebrew нужен для установки Python и системных зависимостей.${C_RESET}"
    echo -e "Официальный установщик: ${C_CYAN}https://brew.sh${C_RESET}"
    echo
    read -r -p "Установить Homebrew сейчас? [y/N] " answer
    case "$answer" in
        [yY][eE][sS]|[yY])
            info "Запускаю официальный установщик Homebrew..."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            # Добавляем brew в PATH для текущей сессии (для Apple Silicon и Intel)
            if [[ -x /opt/homebrew/bin/brew ]]; then
                eval "$(/opt/homebrew/bin/brew shellenv)"
            elif [[ -x /usr/local/bin/brew ]]; then
                eval "$(/usr/local/bin/brew shellenv)"
            fi
            if ! command -v brew >/dev/null 2>&1; then
                err "Homebrew установлен, но не найден в PATH."
                err "Выполни вручную и перезапусти установщик:"
                echo '  echo '\''eval "$(/opt/homebrew/bin/brew shellenv)"'\'' >> ~/.zprofile'
                echo '  eval "$(/opt/homebrew/bin/brew shellenv)"'
                exit 1
            fi
            ok "Homebrew установлен: $(brew --version | head -n1)"
            ;;
        *)
            err "Без Homebrew установка невозможна. Прерываю."
            err "Установи вручную: https://brew.sh"
            exit 1
            ;;
    esac
else
    ok "Homebrew уже установлен: $(brew --version | head -n1)"
fi

# ---------- Python 3 ----------
step "Проверка Python 3"
if ! command -v python3 >/dev/null 2>&1; then
    warn "Python 3 не найден. Устанавливаю через brew..."
    brew install python
fi
ok "Python 3: $(python3 --version 2>&1)"

# ---------- Виртуальное окружение ----------
step "Создание виртуального окружения"
if [[ ! -x .venv/bin/python ]]; then
    python3 -m venv .venv
    ok "Виртуальное окружение создано."
else
    ok "Виртуальное окружение уже существует."
fi

# ---------- Python-зависимости ----------
step "Установка Python-зависимостей"
.venv/bin/python -m pip install --upgrade pip
.venv/bin/python -m pip install -r requirements.txt
ok "Python-зависимости установлены."

# ---------- Права и токен ----------
step "Права доступа"
if [[ -f .bridge-token ]]; then
    chmod 600 .bridge-token
    ok "Права на .bridge-token выставлены (600)."
fi
chmod +x "$SCRIPT_DIR/start-ai-agent-connectivity-automation-bridge-mac.sh"
chmod +x "$SCRIPT_DIR/install-mac.sh"
ok "Скрипты сделаны исполняемыми."

# ---------- Снятие карантина Gatekeeper (если нужно) ----------
step "Проверка карантина Gatekeeper"
QUARANTINED=$(xattr -r -p com.apple.quarantine "$SCRIPT_DIR" 2>/dev/null | wc -l | tr -d ' ')
if [[ "$QUARANTINED" -gt 0 ]]; then
    warn "Обнаружены файлы с атрибутом карантина: $QUARANTINED"
    info "Снимаю карантин с папки проекта (это безопасно, файлы локальные)..."
    xattr -dr com.apple.quarantine "$SCRIPT_DIR" 2>/dev/null || true
    ok "Карантин снят."
else
    ok "Файлы без карантина — ничего делать не нужно."
fi

# ---------- LaunchAgent (автозапуск) ----------
step "Настройка автозапуска macOS (LaunchAgent)"
LAUNCH_AGENTS_DIR="$HOME/Library/LaunchAgents"
mkdir -p "$LAUNCH_AGENTS_DIR"
PLIST_PATH="$LAUNCH_AGENTS_DIR/com.ai-agent-connectivity-automation-bridge.plist"

cat > "$PLIST_PATH" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.ai-agent-connectivity-automation-bridge</string>
    <key>ProgramArguments</key>
    <array>
        <string>$SCRIPT_DIR/start-ai-agent-connectivity-automation-bridge-mac.sh</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <false/>
    <key>StandardOutPath</key>
    <string>$HOME/Library/Logs/ai-agent-connectivity-automation-bridge.log</string>
    <key>StandardErrorPath</key>
    <string>$HOME/Library/Logs/ai-agent-connectivity-automation-bridge.log</string>
    <key>WorkingDirectory</key>
    <string>$SCRIPT_DIR</string>
</dict>
</plist>
PLIST

chmod 644 "$PLIST_PATH"
launchctl unload "$PLIST_PATH" 2>/dev/null || true
launchctl load "$PLIST_PATH"
ok "LaunchAgent создан и загружен: $PLIST_PATH"

# ---------- Итоговая информация ----------
echo
echo -e "${C_GREEN}${C_BOLD}════════════════════════════════════════════════════════════════${C_RESET}"
echo -e "${C_GREEN}${C_BOLD}  ✅ УСТАНОВКА ЗАВЕРШЕНА                                       ${C_RESET}"
echo -e "${C_GREEN}${C_BOLD}════════════════════════════════════════════════════════════════${C_RESET}"
echo
echo -e "${C_BOLD}Что установлено:${C_RESET}"
echo -e "  • Homebrew:   ${C_GREEN}$(brew --version | head -n1)${C_RESET}"
echo -e "  • Python 3:   ${C_GREEN}$(python3 --version 2>&1)${C_RESET}"
echo -e "  • Flask:      ${C_GREEN}$(.venv/bin/python -c 'import flask; print(flask.__version__)')${C_RESET}"
echo -e "  • Автозапуск: ${C_GREEN}~/Library/LaunchAgents/com.ai-agent-connectivity-automation-bridge.plist${C_RESET}"
echo -e "  • Лог-файл:   ${C_GREEN}~/Library/Logs/ai-agent-connectivity-automation-bridge.log${C_RESET}"
echo
echo -e "${C_CYAN}${C_BOLD}────────────────────────────────────────────────────────────────${C_RESET}"
echo -e "${C_CYAN}${C_BOLD}  УПРАВЛЕНИЕ СЕРВЕРОМ НА MAC                                    ${C_RESET}"
echo -e "${C_CYAN}${C_BOLD}────────────────────────────────────────────────────────────────${C_RESET}"
echo
echo -e "${C_BOLD}Остановить автозапуск:${C_RESET}"
echo -e "  ${C_YELLOW}launchctl unload ~/Library/LaunchAgents/com.ai-agent-connectivity-automation-bridge.plist${C_RESET}"
echo
echo -e "${C_BOLD}Запустить снова:${C_RESET}"
echo -e "  ${C_YELLOW}launchctl load ~/Library/LaunchAgents/com.ai-agent-connectivity-automation-bridge.plist${C_RESET}"
echo
echo -e "${C_BOLD}Посмотреть логи в реальном времени:${C_RESET}"
echo -e "  ${C_YELLOW}tail -f ~/Library/Logs/ai-agent-connectivity-automation-bridge.log${C_RESET}"
echo
echo -e "${C_BOLD}Ручной запуск в текущем терминале:${C_RESET}"
echo -e "  ${C_YELLOW}cd \"$SCRIPT_DIR\" && ./start-ai-agent-connectivity-automation-bridge-mac.sh${C_RESET}"
echo
echo -e "${C_BOLD}Проверить, что сервер отвечает:${C_RESET}"
echo -e "  ${C_YELLOW}curl -s http://127.0.0.1:8765/api/jobs -H \"X-Bridge-Token: \$(cat .bridge-token)\"${C_RESET}"
echo
echo -e "${C_CYAN}${C_BOLD}────────────────────────────────────────────────────────────────${C_RESET}"
echo -e "${C_CYAN}${C_BOLD}  ЕСЛИ macOS БЛОКИРУЕТ ЗАПУСК (Gatekeeper)                      ${C_RESET}"
echo -e "${C_CYAN}${C_BOLD}────────────────────────────────────────────────────────────────${C_RESET}"
echo
echo -e "Скрипты .sh и .py, скачанные из интернета, могут быть помечены карантином."
echo -e "Установщик уже снял карантин с папки проекта автоматически,"
echo -e "но если что-то блокируется — выполни в папке проекта:"
echo
echo -e "  ${C_YELLOW}xattr -dr com.apple.quarantine \"$SCRIPT_DIR\"${C_RESET}"
echo
echo -e "${C_GREEN}${C_BOLD}════════════════════════════════════════════════════════════════${C_RESET}"
echo

# ---------- Запуск сервера в Terminal.app ----------
info "Открываю Terminal.app с сервером..."
open -a Terminal "$SCRIPT_DIR/start-ai-agent-connectivity-automation-bridge-mac.sh"
ok "Готово. Сервер запускается в отдельном окне Terminal."
