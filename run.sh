#!/usr/bin/env bash
# The one command we run:  ./run.sh <input_dir> <output.json>
# Change what it calls, not how it is called. It must finish in 30 minutes.
set -euo pipefail
if [ "$#" -ne 2 ]; then
  echo "usage: ./run.sh <input_dir> <output.json>" >&2
  exit 2
fi

if [ -x "/usr/bin/python3" ]; then
  PY="/usr/bin/python3"
elif command -v python3 >/dev/null 2>&1; then
  PY="python3"
else
  PY="python"
fi

"$PY" "$(dirname "$0")/solution.py" "$1" "$2"
