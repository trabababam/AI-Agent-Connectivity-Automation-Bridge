# Restricted sudo permissions

This is an optional example of granting permission to run one specific hardware diagnostic command without a password prompt.

The AI Agent Connectivity Automation Bridge server does not require permanent sudo access. Do not grant it unrestricted administrator privileges.

## Example: allow lshw -C display

1. Check your username and the command path:

   `whoami`

   `command -v lshw`

2. If lshw is not installed:

   `sudo apt-get install lshw`

3. Open a separate sudoers file:

   `sudo visudo -f /etc/sudoers.d/ai-bridge`

4. Add this rule, replacing YOUR_USERNAME with the result of whoami:

   `YOUR_USERNAME ALL=(root) NOPASSWD: /usr/bin/lshw -C display`

   Use the actual command path reported by command -v lshw.

5. Validate the rule:

   `sudo visudo -cf /etc/sudoers.d/ai-bridge`

6. Test the exact command:

   `sudo -n /usr/bin/lshw -C display`

## Security rules

- This rule permits only the specified command and arguments.
- Add separate, narrowly scoped rules only when needed.
- Never use NOPASSWD: ALL.
- Never pass a sudo password through the browser extension, API, or source code.
- Do not run the bridge server as root.
- Review every command before approving its execution.

---

# Ограниченные права sudo

Это необязательный пример настройки разрешения на запуск одной конкретной диагностической команды без запроса пароля.

Сервер AI Agent Connectivity Automation Bridge не требует постоянных прав sudo. Не предоставляйте ему неограниченные права администратора.

## Пример: разрешение команды lshw -C display

1. Узнайте имя пользователя и путь к команде:

   `whoami`

   `command -v lshw`

2. Если lshw не установлен:

   `sudo apt-get install lshw`

3. Откройте отдельный файл правил sudo:

   `sudo visudo -f /etc/sudoers.d/ai-bridge`

4. Добавьте правило, заменив ИМЯ_ПОЛЬЗОВАТЕЛЯ результатом команды whoami:

   `ИМЯ_ПОЛЬЗОВАТЕЛЯ ALL=(root) NOPASSWD: /usr/bin/lshw -C display`

   Используйте фактический путь к команде, который показывает command -v lshw.

5. Проверьте синтаксис:

   `sudo visudo -cf /etc/sudoers.d/ai-bridge`

6. Проверьте выполнение команды:

   `sudo -n /usr/bin/lshw -C display`

## Правила безопасности

- Правило разрешает только указанную команду с указанными аргументами.
- Добавляйте отдельные точечные разрешения только при необходимости.
- Никогда не используйте NOPASSWD: ALL.
- Не передавайте пароль sudo через расширение браузера, API или исходный код.
- Не запускайте сервер моста от имени root.
- Проверяйте каждую команду перед подтверждением выполнения.
