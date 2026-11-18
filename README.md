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
