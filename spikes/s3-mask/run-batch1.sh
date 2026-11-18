#!/usr/bin/env bash
# Input batch 1 for spike S3: clicks the bottom-left corner, presses Escape, clicks outside, checks focus.
# Moves the real pointer for about 30 s. Hands off the machine while it runs.
# Usage: bash spikes/s3-mask/run-batch1.sh
here=$(cd "$(dirname "$0")" && pwd)
test_py="$here/batch1.py"

spike_pids() { for p in $(pgrep -x qs); do case "$(readlink /proc/$p/cwd)" in */omadials/spikes/*) echo "$p" ;; esac; done; }
stop_spikes() { for p in $(spike_pids); do kill "$p"; done; }

if [ -n "$(spike_pids)" ]; then echo "Another spike copy is running. Stop it first."; exit 1; fi
trap stop_spikes EXIT

echo "Starting in 10 s. Hands off the keyboard, mouse and screen."
sleep 10
cd "$here" && (timeout 90 qs -p . >/dev/null 2>&1 &)
sleep 2.5
out="${TMPDIR:-/tmp}/omadials-s3-batch1.out"
timeout 60 python3 -u "$test_py" > "$out" 2>&1
echo "exit $?" >> "$out"
tail -14 "$out"
qs -p "$here" ipc call s3 close 2>/dev/null
echo "Done. You can use the machine again."
