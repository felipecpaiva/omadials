# Hand checks

What only a person on the Z13 can confirm. Automated and pointer checks already passed are listed in `plan.md` and
`spikes.md`; nothing here is ticked by a simulated pointer. Do each line once, mark it with the date, and note anything
that felt wrong. Takes about 10 minutes.

## Touch (v0.1 and v0.2)

- [ ] Tap the bottom-left corner with a finger: the corner opens. Tap it again: it closes.
- [ ] Press in the corner and drag outward: the corner grows with the finger. Let go past about 40%: it stays open.
  Let go early: it slides back closed, no bounce.
- [ ] Drag the volume ring: the knob stays under your finger. Slide the finger outward past the ring while dragging:
  it slows down ("Fine"). Back on the ring: normal speed, no jump.
- [ ] Drag slowly past 25, 50, 75 percent: you see a small tick and a light snap at each.
- [ ] Tap a ring without moving: nothing changes.
- [ ] Tap Wi-Fi, Bluetooth, night light: each switches, with a dashed outline while it waits.
- [ ] Press and slide along the toggle arc: the toggles scroll and snap to a slot; nothing switches.
- [ ] Hold a toggle about half a second: its detail opens. The back arrow returns.
- [ ] Hold the volume label: the volume detail (outputs and app sliders) opens.
- [ ] Tap outside the corner: it closes, and the app under your finger does not react.
- [ ] Leave it open and untouched: it closes by itself after 10 s.

## Mouse and keyboard

- [ ] Push the pointer into the corner and wait: it opens. Move away: it closes after about half a second.
- [ ] Bind `omarchy-shell omadials toggle` to a key. Press it: the corner opens and arrow keys and Escape work.
- [ ] In "On approach" icon mode, the tab appears only when the pointer reaches the corner, and never opens by itself.

## Screens and states

- [ ] Make a window fullscreen (Super+F): the tab and the corner zone go away. Leave fullscreen: they return.
- [ ] Lock the screen: no corner on the lock screen.
- [ ] Rotate the tablet to portrait (if you use rotation): the corner stays in the visual corner and fits.
- [ ] Switch theme to Flexoki Light and back: the corner follows the colours live and text stays readable.

## Settings

- [ ] Open Settings from the gear. Change the corner, the size and the tab style: the corner updates within a second.
- [ ] Hide a ring and a toggle, change an icon, move a toggle up: the corner follows.
- [ ] Press Reset, then Undo within 10 s: everything comes back exactly.
