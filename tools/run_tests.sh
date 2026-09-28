#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
PC_TEST_PYTHON="${PC_PYTHON:-../codex-build/.venv/bin/python}"
export PYTHONDONTWRITEBYTECODE=1
"$PC_TEST_PYTHON" -B tests/harness.py
"$PC_TEST_PYTHON" -B -m unittest discover -s tests -v
