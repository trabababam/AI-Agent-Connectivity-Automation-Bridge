#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
cd "$SCRIPT_DIR"

# На macOS порт 5000 занят AirPlay — у нас 8765, конфликта нет.
exec .venv/bin/python ai-agent-connectivity-automation-bridge-mac.py
