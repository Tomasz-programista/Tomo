#!/bin/bash
# Starts TOMO-TV. The first start sets everything up (downloads ~300 MB once).
cd "$(dirname "$0")" || exit 1

pause_and_exit() {
    read -r -p "Press Enter to close." _
    exit 1
}

find_python() {
    for v in 3.14 3.13 3.12 3.11 3.10; do
        if command -v "python$v" >/dev/null 2>&1; then
            echo "python$v"
            return
        fi
    done
    if command -v python3 >/dev/null 2>&1 &&
        python3 -c 'import sys; sys.exit(0 if (3, 10) <= sys.version_info[:2] <= (3, 14) else 1)'; then
        echo python3
    fi
}

if [ ! -x .venv/bin/python ]; then
    echo "*** TOMO-TV first-time setup: downloading the video engine (~300 MB, only once) ***"
    PY=$(find_python)
    if [ -z "$PY" ]; then
        echo "Python 3.10 - 3.14 was not found."
        echo "Install Python 3.10 - 3.14 with your package manager, e.g. on Ubuntu:  sudo apt install python3 python3-venv"
        pause_and_exit
    fi
    echo "Using $PY"
    if ! "$PY" -m venv .venv; then
        echo "Couldn't create the Python environment. On Ubuntu/Debian run:  sudo apt install python3-venv"
        rm -rf .venv
        pause_and_exit
    fi
    if ! .venv/bin/python -m pip install --upgrade pip || ! .venv/bin/python -m pip install -r requirements.txt; then
        echo "Setup failed. Check your internet connection and try again."
        rm -rf .venv
        pause_and_exit
    fi
    cp requirements.txt .venv/requirements.txt
elif ! cmp -s requirements.txt .venv/requirements.txt; then
    echo "Updating TOMO-TV's components..."
    .venv/bin/python -m pip install -r requirements.txt && cp requirements.txt .venv/requirements.txt
fi

exec .venv/bin/python tomotv.py
