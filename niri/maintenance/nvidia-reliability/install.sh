#!/usr/bin/bash
set -euo pipefail
task_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
exec /usr/bin/python3 "$task_dir/install.py" "$@"
