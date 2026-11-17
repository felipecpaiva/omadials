#!/usr/bin/env bash
# Resource use of omadials inside the Omarchy shell, in three states: plugin off, on but closed, and open.
# Per state: shell CPU percent over a window, resident memory, and child processes the shell started in that window.
# No input; restarts the shell twice; ends with the plugin enabled. Usage: bash test/perf/measure.sh [seconds]
set -u
win=${1:-20}
id=io.github.felipecpaiva.omadials
hz=$(getconf CLK_TCK)

shell_pid() { pgrep -xo quickshell; }
cpu_ticks() { awk '{print $14+$15+$16+$17}' "/proc/$1/stat"; }
rss_mb() { awk '/VmRSS/ {printf "%.1f", $2/1024}' "/proc/$1/status"; }

# Children started by the shell during the window (polled every 50 ms), as "count: names".
watch_children() {
  local pid=$1 end=$((SECONDS + win)) seen=""
  while [ $SECONDS -lt $end ]; do
    for c in $(cat /proc/"$pid"/task/*/children 2>/dev/null); do
      case " $seen " in *" $c "*) ;; *) seen="$seen $c"; echo "$(cat /proc/$c/comm 2>/dev/null || echo gone)" ;; esac
    done
    sleep 0.05
  done
}

measure() {   # label, then an optional command to keep running each 8 s (to hold the fan open)
  local label=$1 keep=${2:-} pid t0 t1 kids
  pid=$(shell_pid); sleep 2
  [ -n "$keep" ] && $keep
  t0=$(cpu_ticks "$pid")
  kids=$(watch_children "$pid" & k=$!
         if [ -n "$keep" ]; then for _ in $(seq 8 8 "$win"); do sleep 8; $keep; done; fi
         wait $k)
  t1=$(cpu_ticks "$pid")
  local cpu; cpu=$(awk -v a="$t0" -v b="$t1" -v w="$win" -v hz="$hz" 'BEGIN{printf "%.2f", (b-a)/hz/w*100}')
  local n; n=$(printf '%s\n' "$kids" | grep -c . || true)
  printf '%-16s cpu %6s %%   rss %7s MB   children %3s  %s\n' "$label" "$cpu" "$(rss_mb "$pid")" "$n" \
    "$(printf '%s\n' "$kids" | sort | uniq -c | awk '{printf "%s x%s ", $2, $1}')"
}

echo "window ${win}s per state, $(date '+%F %T')"
omarchy plugin disable "$id" >/dev/null; omarchy-restart-shell >/dev/null 2>&1; sleep "${SETTLE:-25}"
measure "plugin off"
omarchy plugin enable "$id" >/dev/null; omarchy-restart-shell >/dev/null 2>&1; sleep "${SETTLE:-25}"
measure "on, closed"
measure "on, open" "omarchy-shell omadials open"
omarchy-shell omadials close >/dev/null
