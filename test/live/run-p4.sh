#!/usr/bin/env bash
# Live pointer check of omadials (mouse only, about 30 s). Moves the real pointer, changes the volume and do not
# disturb for a moment and restores both. Hands off the machine from "Starting" to "Done".
# Usage: bash test/live/run-p4.sh
here=$(cd "$(dirname "$0")" && pwd)
out=/tmp/claude-1000/-home-felipe-Work/06fd7e45-c5c2-4364-af0e-d1d4d4c39fdd/scratchpad/p4
mkdir -p "$out"
omarchy-shell omadials status >/dev/null 2>&1 || { echo "omadials is not running in the shell"; exit 1; }
echo "Starting in 10 s. Hands off the keyboard, mouse and screen."
sleep 10
OUT="$out" timeout 90 python3 -u "$here/p4_pointer.py" 2>&1 | tee "$out/result.txt"
omarchy-shell omadials close >/dev/null 2>&1
echo "Done. You can use the machine again."
