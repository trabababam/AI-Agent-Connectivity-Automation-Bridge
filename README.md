# AI Agent Connectivity Automation Bridge

**Version:** 0.1.0

A local connectivity bridge that connects AI-assisted browser workflows
with a terminal running on your computer.

The system consists of two components:

1. **ChatGPT Terminal Bridge** — a Firefox browser extension.
2. **AI Agent Connectivity Automation Bridge** — the local Python server
   included in this repository.

Both components are required.

## 1. Install the Firefox extension

Install **ChatGPT Terminal Bridge** from the official Mozilla Add-ons store:

[Install ChatGPT Terminal Bridge for Firefox](https://addons.mozilla.org/ru/firefox/addon/chatgpt-terminal-bridge/)

After installation, open ChatGPT in Firefox.

Allow the extension to access the local address `127.0.0.1:8765`
if Firefox requests this permission.

## 2. Install the local server

Requirements:

- Debian or Ubuntu with `apt-get`
- Python 3
- GNOME desktop environment and GNOME Terminal
- A regular user account with permission to run `sudo`

**Tested environment:** Debian 13 with GNOME. This is the primary tested configuration.

### System packages

The installer updates the APT package index and installs:

| Package | Purpose |
|---|---|
| `ca-certificates` | Trusted certificates for secure HTTPS downloads |
| `python3` | Python runtime |
| `python3-venv` | Python virtual environment support |
| `python3-pip` | Python package installer |
| `gnome-terminal` | Separate server window and GNOME autostart |

### Python dependencies

The `requirements.txt` file contains:

| Package | Version | Purpose |
|---|---|---|
| `Flask` | `3.1.3` | HTTP server and REST API |

Flask automatically installs its required dependencies, including Werkzeug, Jinja2, Click, ItsDangerous, Blinker and MarkupSafe. These packages do not need to be installed separately.

### Installation

Download or clone this repository, open its directory in a terminal, and run:

    ./install.sh

Run the installer as your regular user, **not** with `sudo` and not as `root`. The installer requests `sudo` only when installing system packages.

The installer performs the following steps:

1. Updates the APT package index.
2. Installs the required system packages.
3. Creates the `.venv` Python virtual environment.
4. Installs Python dependencies from `requirements.txt`.
5. Preserves the existing authentication token and its permissions, if present.
6. Configures GNOME autostart for the current user.
7. Starts the server in a separate GNOME Terminal window.

The server starts immediately after installation. At subsequent GNOME logins, it is started automatically.

## 3. Configure the connection

The server generates an authentication token and stores it in:

    .bridge-token

Copy the token into the corresponding token field in the
ChatGPT Terminal Bridge extension settings.

Keep this token private. Do not publish it or share it with anyone.

## 4. Start the server

To start the server manually, run:

    ./start-ai-agent-connectivity-automation-bridge.sh

The server listens on:

    http://127.0.0.1:8765

### GNOME autostart and server control

On GNOME, the installer configures autostart for the current user. The server opens in a separate terminal window after installation and at subsequent GNOME logins. Keep this window open while using the extension. Press `Ctrl+C` in that window to stop the server. To start it manually, use the launcher above. Do not start a second instance if the server is already running: port `8765` may already be occupied.

The server itself should run as your regular user. Do not launch it with `sudo` or as `root`.


## 5. macOS installation (Homebrew + LaunchAgent)

macOS is supported via a separate set of files. Linux (Debian/Ubuntu, GNOME) setup is unchanged.

### Files added for macOS

| File | Purpose |
|---|---|
| `install-mac.sh` | Installer: checks/installs Homebrew, creates `.venv`, installs `Flask`, sets up LaunchAgent, removes Gatekeeper quarantine, prints a colored management cheatsheet. |
| `start-ai-agent-connectivity-automation-bridge-mac.sh` | Launcher: runs `.venv/bin/python ai-agent-connectivity-automation-bridge-mac.py`. |
| `ai-agent-connectivity-automation-bridge-mac.py` | Same server code as the Linux version (already cross-platform; listens on `127.0.0.1:8765`, no conflict with AirPlay on port `5000`). |

### Requirements (macOS)

- macOS (tested on Apple Silicon and Intel)
- Homebrew (the installer offers to install it if missing)
- Python 3 (installed via Homebrew if missing)
- A regular user account (no `sudo` needed for the bridge itself)

### Installation (macOS)

```bash
git clone <repo-url> ~/soft/AI-Agent-Connectivity-Automation-Bridge
cd ~/soft/AI-Agent-Connectivity-Automation-Bridge
chmod +x install-mac.sh start-ai-agent-connectivity-automation-bridge-mac.sh
./install-mac.sh
```

The installer will:

1. Check for Homebrew; if missing — offer to install it (`[y/N]` prompt).
2. Create `.venv` and install `Flask==3.1.3`.
3. Create and load `~/Library/LaunchAgents/com.ai-agent-connectivity-automation-bridge.plist`.
4. Remove Gatekeeper quarantine (`xattr -dr com.apple.quarantine`) from the project folder if needed.
5. Open Terminal.app with the running server.

### Managing the server on macOS

```bash
launchctl unload ~/Library/LaunchAgents/com.ai-agent-connectivity-automation-bridge.plist
launchctl load ~/Library/LaunchAgents/com.ai-agent-connectivity-automation-bridge.plist
tail -f ~/Library/Logs/ai-agent-connectivity-automation-bridge.log
./start-ai-agent-connectivity-automation-bridge-mac.sh
curl -s http://127.0.0.1:8765/api/jobs -H "X-Bridge-Token: $(cat .bridge-token)"
```

### Gatekeeper note

`.sh` and `.py` files downloaded from the internet may carry the `com.apple.quarantine` attribute. `install-mac.sh` removes it automatically. If something is still blocked, run inside the project folder:

```bash
xattr -dr com.apple.quarantine .
```

### Ports

macOS Monterey and later reserve port `5000` for the AirPlay Receiver. This bridge uses port `8765`, so there is no conflict. Do not change `port=` to `5000` on macOS.

### Linux (Debian/Ubuntu, GNOME) — unchanged

Linux setup is unchanged: `./install.sh` (uses `apt-get`, `gnome-terminal`, GNOME autostart, main script `ai-agent-connectivity-automation-bridge.py`).



## 6. Windows installation (10/11; 7 with caveats)

Windows is supported via a separate set of files. Linux and macOS setups are unchanged.

### Files added for Windows

| File | Purpose |
|---|---|
| `install-win.bat` | Installer: checks/installs Python via `winget`, creates `.venv`, installs `Flask`, creates a Startup shortcut, starts the server. |
| `start-ai-agent-connectivity-automation-bridge-win.bat` | Launcher: runs `.venv\Scripts\python.exe ai-agent-connectivity-automation-bridge-win.py`. |
| `ai-agent-connectivity-automation-bridge-win.py` | Same server code, with a cross-platform `executable` (`None` on Windows -> uses `cmd.exe`; `/bin/bash` on Linux/macOS). Listens on `127.0.0.1:8765`. |

### Requirements (Windows)

- Windows 10 or Windows 11 (Windows 7: see note below)
- Python 3.9+ (the installer tries to install Python 3.12 via `winget` if missing)
- A regular user account

### Installation (Windows)

1. Copy or clone this repository to a folder, e.g. `C:\Users\<you>\soft\AI-Agent-Connectivity-Automation-Bridge`.
2. Double-click `install-win.bat`.

The installer will:

1. Check required files.
2. Warn if Windows 7 is detected.
3. Check Python; if missing -- install Python 3.12 via `winget install --id Python.Python.3.12`.
4. Create `.venv` and install `Flask==3.1.3`.
5. Set permissions on `.bridge-token` via `icacls` (if it exists).
6. Create a Startup shortcut: `%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\ai-agent-connectivity-automation-bridge.lnk`.
7. Start the server in a new window.

### Managing the server on Windows

Manual run:

    start-ai-agent-connectivity-automation-bridge-win.bat

Health check:

    curl http://127.0.0.1:8765/api/jobs

Remove autostart shortcut:

    del "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\ai-agent-connectivity-automation-bridge.lnk"

To stop the server -- press `Ctrl+C` in its console window.

### Windows 7 note

Official Python 3.9+ does not support Windows 7. The last working combination is **Python 3.8.16 + Flask 2.3.x**. If you need Windows 7, edit `requirements.txt` to `Flask==2.3.3` and install Python 3.8 manually from python.org. The installer will warn you about this.

### Ports

The bridge uses port `8765` (same as on Linux/macOS). No conflicts with system services.


## Features

- Connects the Firefox extension to a local terminal service.
- Receives commands from ChatGPT through the browser extension.
- Supports command approval and rejection.
- Returns execution results to the browser.
- Uses token-based authentication.
- Runs locally without a remote command execution server.

## API

- `GET /api/jobs`
- `POST /api/jobs`
- `GET /api/jobs/<job_id>`
- `POST /api/jobs/<job_id>/approve`
- `POST /api/jobs/<job_id>/reject`

Requests require the `X-Bridge-Token` header.

## Security

[Restricted sudo permissions](docs/SUDO_SETUP.md)

The server listens only on localhost (`127.0.0.1`).
Commands are executed under the current operating system user account.

Only approve commands you understand and trust.
Review commands before allowing their execution.
Never expose your authentication token.

## Demo

[Watch the demonstration video](docs/media/test.mp4)

## Support the project

If this project is useful to you, you can support its development:

[Support the project via CloudTips](https://pay.cloudtips.ru/p/db22b3a4)

---

# AI Agent Connectivity Automation Bridge

**Версия:** 0.1.0

Локальный связующий компонент для интеграции браузерных сценариев
с ИИ и терминалом на вашем компьютере.

Система состоит из двух компонентов:

1. **ChatGPT Terminal Bridge** — расширение для браузера Firefox.
2. **AI Agent Connectivity Automation Bridge** — локальный Python-сервер
   из этого репозитория.

Для работы системы необходимы оба компонента.

## 1. Установка расширения Firefox

Установите **ChatGPT Terminal Bridge** из официального каталога Mozilla:

[Установить ChatGPT Terminal Bridge для Firefox](https://addons.mozilla.org/ru/firefox/addon/chatgpt-terminal-bridge/)

После установки откройте ChatGPT в Firefox.

Если Firefox запросит разрешение на доступ к локальному адресу
`127.0.0.1:8765`, разрешите его.

## 2. Установка локального сервера

Требования:

- Debian или Ubuntu с `apt-get`
- Python 3
- Графическая среда GNOME и GNOME Terminal
- Обычная учётная запись пользователя с правом использования `sudo`

**Проверенная среда:** Debian 13 с GNOME. Это основная конфигурация, на которой проверялась работа проекта.

### Системные пакеты

Установщик обновляет индекс APT и устанавливает следующие пакеты:

| Пакет | Назначение |
|---|---|
| `ca-certificates` | Доверенные сертификаты для безопасной загрузки по HTTPS |
| `python3` | Среда выполнения Python |
| `python3-venv` | Поддержка виртуальных окружений Python |
| `python3-pip` | Установщик Python-пакетов |
| `gnome-terminal` | Отдельное окно сервера и автозапуск GNOME |

### Зависимости Python

Файл `requirements.txt` содержит:

| Пакет | Версия | Назначение |
|---|---|---|
| `Flask` | `3.1.3` | HTTP-сервер и REST API |

Flask автоматически устанавливает необходимые зависимости, включая Werkzeug, Jinja2, Click, ItsDangerous, Blinker и MarkupSafe. Устанавливать эти пакеты отдельно не требуется.

### Установка

Скачайте или клонируйте этот репозиторий, откройте его каталог в терминале и выполните:

    ./install.sh

Запускайте установщик от имени обычного пользователя, **не через `sudo` и не от имени `root`**. `sudo` запрашивается только для установки системных пакетов.

Установщик выполняет следующие действия:

1. Обновляет индекс пакетов APT.
2. Устанавливает необходимые системные пакеты.
3. Создаёт виртуальное окружение Python `.venv`.
4. Устанавливает Python-зависимости из `requirements.txt`.
5. Сохраняет существующий токен авторизации и его права доступа, если токен уже создан.
6. Настраивает автозапуск GNOME для текущего пользователя.
7. Запускает сервер в отдельном окне GNOME Terminal.

Сервер запускается сразу после установки. При последующих входах в GNOME он запускается автоматически.

## 3. Настройка соединения

Сервер автоматически создаёт токен авторизации и сохраняет его
в файле:

    .bridge-token

Скопируйте токен в соответствующее поле настроек расширения
ChatGPT Terminal Bridge.

Храните токен в секрете. Не публикуйте его и не передавайте посторонним.

## 4. Запуск сервера

Для ручного запуска выполните:

    ./start-ai-agent-connectivity-automation-bridge.sh

Сервер принимает подключения по адресу:

    http://127.0.0.1:8765

### Автозапуск GNOME и управление сервером

В GNOME установщик настраивает автозапуск для текущего пользователя. После установки и при последующих входах в GNOME сервер открывается в отдельном окне терминала. Не закрывайте это окно, пока используете расширение. Чтобы остановить сервер, нажмите `Ctrl+C` в этом окне. Для ручного запуска используйте команду из предыдущего раздела. Не запускайте второй экземпляр, если сервер уже работает: порт `8765` может быть занят.

Сам сервер должен работать от имени обычного пользователя. Не запускайте его через `sudo` или от имени `root`.


## 5. Установка на macOS (Homebrew + LaunchAgent)

macOS поддерживается через отдельный набор файлов. Установка на Linux (Debian/Ubuntu, GNOME) не изменилась.

### Файлы, добавленные для macOS

| Файл | Назначение |
|---|---|
| `install-mac.sh` | Установщик: проверяет/ставит Homebrew, создаёт `.venv`, ставит `Flask`, настраивает LaunchAgent, снимает карантин Gatekeeper, выводит цветную шпаргалку по управлению. |
| `start-ai-agent-connectivity-automation-bridge-mac.sh` | Запуск: `.venv/bin/python ai-agent-connectivity-automation-bridge-mac.py`. |
| `ai-agent-connectivity-automation-bridge-mac.py` | Тот же код сервера, что и для Linux (уже кроссплатформенный; слушает `127.0.0.1:8765`, конфликта с AirPlay на порту `5000` нет). |

### Требования (macOS)

- macOS (проверено на Apple Silicon и Intel)
- Homebrew (установщик предложит установить, если его нет)
- Python 3 (ставится через Homebrew, если отсутствует)
- Обычная учётная запись пользователя (`sudo` для самого моста не нужен)

### Установка (macOS)

```bash
git clone <repo-url> ~/soft/AI-Agent-Connectivity-Automation-Bridge
cd ~/soft/AI-Agent-Connectivity-Automation-Bridge
chmod +x install-mac.sh start-ai-agent-connectivity-automation-bridge-mac.sh
./install-mac.sh
```

Установщик:

1. Проверит Homebrew; если нет — предложит установить (запрос `[y/N]`).
2. Создаст `.venv` и поставит `Flask==3.1.3`.
3. Создаст и загрузит `~/Library/LaunchAgents/com.ai-agent-connectivity-automation-bridge.plist`.
4. Снимет карантин Gatekeeper (`xattr -dr com.apple.quarantine`) с папки проекта, если нужно.
5. Откроет Terminal.app с запущенным сервером.

### Управление сервером на macOS

```bash
launchctl unload ~/Library/LaunchAgents/com.ai-agent-connectivity-automation-bridge.plist
launchctl load ~/Library/LaunchAgents/com.ai-agent-connectivity-automation-bridge.plist
tail -f ~/Library/Logs/ai-agent-connectivity-automation-bridge.log
./start-ai-agent-connectivity-automation-bridge-mac.sh
curl -s http://127.0.0.1:8765/api/jobs -H "X-Bridge-Token: $(cat .bridge-token)"
```

### Примечание про Gatekeeper

Файлы `.sh` и `.py`, скачанные из интернета, могут быть помечены атрибутом `com.apple.quarantine`. `install-mac.sh` снимает его автоматически. Если что-то всё равно блокируется — выполни в папке проекта:

```bash
xattr -dr com.apple.quarantine .
```

### Порты

macOS Monterey и новее занимают порт `5000` под AirPlay Receiver. Этот мост использует порт `8765`, поэтому конфликта нет. Не меняй `port=` на `5000` на macOS.

### Linux (Debian/Ubuntu, GNOME) — без изменений

Установка на Linux не изменилась: `./install.sh` (использует `apt-get`, `gnome-terminal`, автозапуск GNOME, основной скрипт `ai-agent-connectivity-automation-bridge.py`).



## 6. Установка на Windows (10/11; 7 -- с оговорками)

Windows поддерживается через отдельный набор файлов. Установка на Linux и macOS не изменилась.

### Файлы, добавленные для Windows

| Файл | Назначение |
|---|---|
| `install-win.bat` | Установщик: проверяет/ставит Python через `winget`, создаёт `.venv`, ставит `Flask`, создаёт ярлык в автозагрузке, запускает сервер. |
| `start-ai-agent-connectivity-automation-bridge-win.bat` | Запуск: `.venv\Scripts\python.exe ai-agent-connectivity-automation-bridge-win.py`. |
| `ai-agent-connectivity-automation-bridge-win.py` | Тот же код сервера, с кроссплатформенным `executable` (`None` на Windows -> используется `cmd.exe`; `/bin/bash` на Linux/macOS). Слушает `127.0.0.1:8765`. |

### Требования (Windows)

- Windows 10 или Windows 11 (Windows 7 -- см. примечание ниже)
- Python 3.9+ (установщик попытается поставить Python 3.12 через `winget`, если его нет)
- Обычная учётная запись пользователя

### Установка (Windows)

1. Скопируй или склонируй репозиторий в папку, например `C:\Users\<you>\soft\AI-Agent-Connectivity-Automation-Bridge`.
2. Дважды кликни по `install-win.bat`.

Установщик:

1. Проверит обязательные файлы.
2. Предупредит, если обнаружена Windows 7.
3. Проверит Python; если нет -- поставит Python 3.12 через `winget install --id Python.Python.3.12`.
4. Создаст `.venv` и поставит `Flask==3.1.3`.
5. Выставит права на `.bridge-token` через `icacls` (если файл есть).
6. Создаст ярлык в автозагрузке: `%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\ai-agent-connectivity-automation-bridge.lnk`.
7. Запустит сервер в новом окне.

### Управление сервером на Windows

Ручной запуск:

    start-ai-agent-connectivity-automation-bridge-win.bat

Проверка, что сервер отвечает:

    curl http://127.0.0.1:8765/api/jobs

Удалить ярлык из автозагрузки:

    del "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\ai-agent-connectivity-automation-bridge.lnk"

Чтобы остановить сервер -- нажми `Ctrl+C` в его окне консоли.

### Примечание про Windows 7

Официально Python 3.9+ не поддерживает Windows 7. Последняя рабочая связка -- **Python 3.8.16 + Flask 2.3.x**. Если нужна Windows 7: измени `requirements.txt` на `Flask==2.3.3` и поставь Python 3.8 вручную с python.org. Установщик об этом предупредит.

### Порты

Мост использует порт `8765` (как и на Linux/macOS). Конфликтов с системными службами нет.


## Возможности

- Соединение расширения Firefox с локальным терминальным сервером.
- Получение команд из ChatGPT через браузерное расширение.
- Подтверждение или отклонение выполнения команд.
- Возврат результатов выполнения в браузер.
- Авторизация с помощью токена.
- Локальное выполнение команд без удалённого сервера исполнения.

## API

- `GET /api/jobs`
- `POST /api/jobs`
- `GET /api/jobs/<job_id>`
- `POST /api/jobs/<job_id>/approve`
- `POST /api/jobs/<job_id>/reject`

Для запросов необходим заголовок `X-Bridge-Token`.

## Безопасность

[«Ограниченные права sudo»](docs/SUDO_SETUP.md)

Сервер принимает подключения только на localhost (`127.0.0.1`).
Команды выполняются от имени текущего пользователя операционной системы.

Подтверждайте только те команды, содержание которых вы понимаете
и которым доверяете. Всегда проверяйте команды перед выполнением.
Не раскрывайте токен авторизации.

## Демонстрация

[Посмотреть демонстрационное видео](docs/media/test.mp4)

## Поддержать проект

Если проект оказался полезен, вы можете поддержать его развитие:

[Поддержать проект через CloudTips](https://pay.cloudtips.ru/p/db22b3a4)
