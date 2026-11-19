from flask import Flask, request, jsonify
from pathlib import Path
from threading import Lock
import subprocess
import secrets
import time
import uuid

# ---------- ANSI-цвета (только если stdout — TTY) ----------
import sys as _sys
_USE_COLOR = _sys.stdout.isatty()

class C:
    RESET = "\033[0m" if _USE_COLOR else ""
    BOLD  = "\033[1m"  if _USE_COLOR else ""
    DIM   = "\033[2m"  if _USE_COLOR else ""
    RED   = "\033[31m" if _USE_COLOR else ""
    GREEN = "\033[32m" if _USE_COLOR else ""
    YELLOW= "\033[33m" if _USE_COLOR else ""
    BLUE  = "\033[34m" if _USE_COLOR else ""
    MAGENTA="\033[35m" if _USE_COLOR else ""
    CYAN  = "\033[36m" if _USE_COLOR else ""
    WHITE = "\033[37m" if _USE_COLOR else ""
    GRAY  = "\033[90m" if _USE_COLOR else ""

def _c(color, text, bold=False):
    if not _USE_COLOR:
        return text
    return (C.BOLD if bold else "") + color + text + C.RESET

app = Flask(__name__)
TOKEN_FILE = Path(__file__).with_name(".bridge-token")
if TOKEN_FILE.exists():
    TOKEN = TOKEN_FILE.read_text().strip()
else:
    TOKEN = secrets.token_urlsafe(32)
    TOKEN_FILE.write_text(TOKEN)
    TOKEN_FILE.chmod(0o600)
lock = Lock()
MAX_JOBS = 20
jobs = {}

def terminal_log(message):
    ts = time.strftime("%H:%M:%S")
    print(f"{_c(C.GRAY, '[' + ts + ']')} {_c(C.BLUE, '[Bridge]')} {message}", flush=True)


def log_block_header(job_id, title, color=C.CYAN):
    print("", flush=True)
    print(_c(color, "=" * 64), flush=True)
    print(_c(color, f"  {title}  |  job={_c(C.MAGENTA, job_id, bold=True)}", bold=True), flush=True)
    print(_c(color, "=" * 64), flush=True)


def log_block_footer(job_id, status, rc, duration):
    if status == "done":
        status_txt = _c(C.GREEN, status, bold=True)
    elif status == "error":
        status_txt = _c(C.RED, status, bold=True)
    else:
        status_txt = _c(C.YELLOW, status, bold=True)

    rc_txt = _c(C.GREEN if rc == 0 else C.RED, str(rc), bold=True)
    print(_c(C.CYAN, "-" * 64), flush=True)
    print(
        f"  job={_c(C.MAGENTA, job_id, bold=True)}  "
        f"status={status_txt}  "
        f"rc={rc_txt}  "
        f"{_c(C.GRAY, f'{duration:.2f}s')}",
        flush=True,
    )
    print(_c(C.CYAN, "=" * 64), flush=True)
    print("", flush=True)


def prune_old_jobs():
    """Оставляет не более MAX_JOBS, не удаляя выполняющиеся команды."""
    while len(jobs) >= MAX_JOBS:
        removable = [
            job for job in jobs.values()
            if job["status"] != "running"
        ]
        if not removable:
            break
        oldest = min(removable, key=lambda job: job.get("created", 0))
        jobs.pop(oldest["id"], None)


def authorized():
    supplied_token = request.headers.get("X-Bridge-Token", "")

    if not isinstance(TOKEN, str) or not TOKEN:
        return False

    if not isinstance(supplied_token, str) or not supplied_token:
        return False

    return secrets.compare_digest(supplied_token, TOKEN)

@app.after_request
def cors(response):
    origin = request.headers.get("Origin", "")
    allowed = (
        origin == "https://chatgpt.com"
        or origin.startswith("moz-extension://")
        or origin.startswith("chrome-extension://")
    )
    if allowed:
        response.headers["Access-Control-Allow-Origin"] = origin
        response.headers["Vary"] = "Origin"
        response.headers["Access-Control-Allow-Headers"] = (
            "Content-Type, X-Bridge-Token"
        )
        response.headers["Access-Control-Allow-Methods"] = (
            "GET, POST, OPTIONS"
        )
        # Разрешаем доступ из публичной сети к локальному серверу (Chrome PNA)
        response.headers["Access-Control-Allow-Private-Network"] = "true"
    return response

@app.route("/api/<path:path>", methods=["OPTIONS"])
def options(path):
    return ("", 204)

@app.get("/api/jobs")
def list_jobs():
    if not authorized():
        return jsonify(error="Unauthorized"), 401
    with lock:
        return jsonify(jobs=list(jobs.values()))

@app.post("/api/jobs")
def create_job():
    if not authorized():
        return jsonify(error="Unauthorized"), 401
    data = request.get_json(silent=True) or {}
    command = data.get("command", "")
    if not isinstance(command, str) or not command.strip():
        return jsonify(error="Пустая команда"), 400
    if len(command) > 100000:
        return jsonify(error="Команда слишком длинная"), 400
    log_block_header("?", ">>> COMMAND FROM PLUGIN", C.YELLOW)
    print(_c(C.WHITE, command, bold=True), flush=True)
    print(_c(C.YELLOW, "=" * 64), flush=True)
    job = {
        "id": uuid.uuid4().hex[:12],
        "command": command,
        "status": "pending",
        "output": "",
        "created": time.time()
    }
    with lock:
        for existing in jobs.values():
            if existing["status"] == "pending":
                existing["status"] = "rejected"
                existing["output"] = "Автоматически отменена: поступила новая команда."
                terminal_log("ОТКЛОНЕНО: " + existing["id"] + " — поступила новая команда")
        prune_old_jobs()
        jobs[job["id"]] = job
    return jsonify(job=job), 201

@app.post("/api/jobs/<job_id>/approve")
def approve_job(job_id):
    if not authorized():
        return jsonify(error="Unauthorized"), 401
    with lock:
        job = jobs.get(job_id)
        if not job or job["status"] != "pending":
            return jsonify(error="Задача не ожидает подтверждения"), 409
        job["status"] = "running"
        command = job["command"]

    log_block_header(job["id"], ">>> RUN COMMAND", C.BLUE)
    print(_c(C.WHITE, command, bold=True), flush=True)
    print(_c(C.BLUE, "=" * 64), flush=True)

    t0 = time.time()
    rc = None
    try:
        result = subprocess.run(
            command,
            shell=True,
            executable="/bin/bash",
            capture_output=True,
            text=True,
            timeout=60,
            cwd=str(Path.home()),
        )
        output = result.stdout + result.stderr
        rc = result.returncode
        status = "done" if result.returncode == 0 else "error"
        if not output.strip():
            output = "(Команда не вывела текст)"
    except subprocess.TimeoutExpired:
        output = "Остановлено: превышен лимит 60 секунд."
        status = "error"
        rc = "timeout"
    except Exception as exc:
        output = str(exc)
        status = "error"
        rc = "exception"

    duration = time.time() - t0
    out_color = C.GREEN if status == "done" else C.RED
    log_block_header(job["id"], "<<< OUTPUT TO PLUGIN  (" + status + ")", out_color)
    print(_c(C.WHITE, output), flush=True)
    log_block_footer(job["id"], status, rc, duration)

    with lock:
        job["output"] = output[-30000:]
        job["status"] = status
    return jsonify(job=job)

@app.post("/api/jobs/<job_id>/reject")
def reject_job(job_id):
    if not authorized():
        return jsonify(error="Unauthorized"), 401
    with lock:
        job = jobs.get(job_id)
        if not job or job["status"] != "pending":
            return jsonify(error="Задача не ожидает подтверждения"), 409
        job["status"] = "rejected"
        log_block_header(job["id"], ">>> COMMAND REJECTED", C.YELLOW)
        print(_c(C.WHITE, job["command"]), flush=True)
        print(_c(C.YELLOW, "=" * 64), flush=True)
    return jsonify(job=job)

@app.get("/api/jobs/<job_id>")
def get_job(job_id):
    if not authorized():
        return jsonify(error="Unauthorized"), 401
    with lock:
        job = jobs.get(job_id)
        if not job:
            return jsonify(error="Не найдено"), 404
        return jsonify(job=job)

if __name__ == "__main__":
    app.run(host="127.0.0.1", port=8765, debug=False)
