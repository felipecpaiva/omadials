#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
for file in logic/*.js; do
    lines=$(wc -l < "$file")
    if (( lines > 250 )); then
        echo "FAIL $file: $lines lines exceeds 250"
        exit 1
    fi
done
wc -l logic/*.js
for file in test/*.test.mjs controls/*/*.test.mjs; do
    node "$file"
done
if command -v shellcheck >/dev/null 2>&1; then
    shellcheck test/run-all.sh
else
    echo 'SKIP shellcheck'
fi
bash "$(dirname "$0")/isolation.sh"
