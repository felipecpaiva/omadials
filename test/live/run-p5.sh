#!/usr/bin/env bash
# Live check of 4 omadials settings (mouse only, no clicks, about 40 s). Moves the pointer, edits the config and
# the volume for a moment and restores them exactly. Hands off the machine from "Starting" to "Done".
# Usage: bash test/live/run-p5.sh
here=$(cd "$(dirname "$0")" && pwd)
out="${TMPDIR:-/tmp}/omadials-p5"
mkdir -p "$out"
omarchy-shell omadials status >/dev/null 2>&1 || { echo "omadials is not running in the shell"; exit 1; }
echo "Close the omadials settings app first. Starting in 10 s. Hands off the keyboard, mouse and screen."
sleep 10
OUT="$out" timeout 90 python3 -u "$here/p5_settings.py" 2>&1 | tee "$out/result.txt"
omarchy-shell omadials close >/dev/null 2>&1
echo "Done. You can use the machine again."
