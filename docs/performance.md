# Performance

How much omadials costs inside the Omarchy shell. Measured with `test/perf/measure.sh` (shell CPU over a window,
resident memory, child processes the shell starts in that window). Run it again after any change that adds a
control, a timer or an animation.

## Budget

- Closed: no measurable CPU over the shell alone, and no processes started.
- Open at rest: no animation clock running; reads only for the controls on screen.
- Frames: within the 180 Hz panel's frame time while dragging (spike P1.9: 5.56 ms average, 6.88 ms worst).

## Results

2026-11-17, Z13, Omarchy 4.5, 30 s windows after a 25 s settle (a shorter settle measures start-up compile, not use):

| State | Shell CPU | Shell memory | Processes started |
|---|---|---|---|
| omadials off | 1.03 % | 670 MB | 3, all the shell's own |
| on, closed | 1.07 % | 703 MB | 3, none from omadials |
| on, open (reopened every 8 s) | 2.87 % | 712 MB | 20 |

Reading: closed costs nothing measurable in CPU (within noise) and starts nothing. Loading the plugin adds about
33 MB of memory. Open costs about 1.8 % CPU, almost all from the reads each open triggers (one process per read).

## After sysfs reads (2026-11-17, 45 s settle)

Brightness, keyboard light and charge limit now read a watched sysfs file (no process, no polling, live while
closed). Closed: 1.17 % against 1.47 % with the plugin off (noise), no processes. Open (reopened every 8 s): 3.40 %,
22 processes in 30 s, now only from reads that still start a process on each open: power profile
(`omarchy-powerprofiles` and `powerprofilesctl`), airplane (`rfkill`), night light and do not disturb. A settle under
about 40 s measures start-up probes, not use.

## Next savings

1. Power profile from Quickshell's UPower PowerProfiles service, airplane from `/sys/class/rfkill/*/soft`, do not
   disturb from the notifications state file, night light from its state: no process on open.
2. Measure memory per part (views, controls, settings) and load details and rarely used controls only when needed.

## Settings (2026-11-17)

**Panel freeze found and fixed.** Opening the shell panel took 1 to 5 s and blocked the whole shell (other commands
answered "omarchy-shell is not responding"). Cause: on open it listed every installed icon file (about 33 000 on
the Z13), then built an icon dropdown holding that whole list for every control, on the shell's main thread. Fix: no
icon scan; pickers offer "Default" plus the built-in glyphs and accept any typed icon name, resolved when drawn.
After the fix, five opens: visible in 75 to 111 ms, the shell answering other commands in 10 to 40 ms.

**Standalone app**, three cold starts: window in 266 to 272 ms, 179 MB resident, 0 to 1 % CPU when idle.

Rule kept for the future: never build a list from the file system or a service on the shell thread without a
bound; anything that can be large is searched on demand.

## With the new motion (2026-11-17)

Six open styles on a FrameAnimation spring (Tab morph default). 45 s settle, 30 s windows: off 1.07 %, closed 1.00 %
(no clock runs at rest, no processes), open (reopened every 8 s) 3.07 %. The spike measured 5.55 to 5.56 ms average
frame time while moving for every style at 180 Hz. A 60 fps capture of Tab morph showed the disc growing out of the
tab and folding back into it with no element disappearing.
