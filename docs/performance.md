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

## Next savings

1. Read sysfs values with a watched file instead of a process where the value lives in a file: internal panel
   brightness, keyboard light, charge limit. Fewer processes per open.
2. Measure memory per part (views, controls, settings) and load details and rarely used controls only when needed.
