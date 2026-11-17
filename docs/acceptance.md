# omadials acceptance checklist

This is the shared checklist for [UX](ux.md) and [experience](experience.md). IDs remain stable when items move. E is the shared settling curve in experience.md.

## Opening

- [ ] **A-OPEN-1** A corner tap opens the fan. A drag past 40% opens; released before 40% it returns closed in 120 ms on E without overshoot.
- [ ] **A-OPEN-2** Pointer push never opens during a window drag.
- [ ] **A-OPEN-3** At normal speed, new entry surface reaches scale 1 and opacity 1 at 180 ms within one 60 Hz frame. Ring starts are 0, 20, 40 ms at M, and all finish by 220 ms within one frame.
- [ ] **A-OPEN-4** Reverse entry at 60 ms and reverse exit at 60 ms. Compare the frame before and after retarget: scale, opacity, reveal and radius start at the same presentation values. No stale completion hides the reopened fan.

## Dials

- [ ] **A-DIAL-1** Tapping any ring without moving changes no value.
- [ ] **A-DIAL-2** A drag that drifts into another band keeps adjusting the first ring.
- [ ] **A-DIAL-3** Brightness never goes below 1%. Input never writes volume above the configured cap, 100% by default or up to 150%. Existing over-cap readings stay truthful.
- [ ] **A-DIAL-4** The value bubble is never under the contact point.
- [ ] **A-DIAL-5** Press and release at five positions on each ring with movement below 6 px. No backend write occurs. After crossing 6 px in normal mode, knob and fill match the clamped pointer angle in the next rendered frame. Fine mode follows the specified relative gain.
- [ ] **A-DIAL-6** Cross ring bands while captured. Only the original dial changes. Every dial writes live while dragged (at most one write in flight, newest value, about every 50 ms), and the released value is always the last one written. A cancelled drag writes nothing more.
- [ ] **A-DIAL-7** A stepped-level crossing produces one 40 ms attack and 80 ms recovery. Holding an endpoint for 1 s causes no repeated tick. Re-entering after one step produces one new tick.
- [ ] **A-DIAL-8** External updates glide for 120 ms, with text truthful immediately. An update during a drag cannot pull the knob away from the pointer. Over-cap readings are not falsified.
- [ ] **A-DIAL-9** Exercise every track, knob and thickness globally and per ring. Bands remain 44 px, targets 48 px, theme-only colours; dash changes update shader uniforms without path rebuilds.
- [ ] **A-DIAL-10** Selected readouts show real source values or explicit unknown/not connected. No knob or drag writes; tap opens related detail. Adding a readout at the cap is refused with a size hint.
- [ ] **A-DIAL-11** In every corner, normal drag has no easing. Cross outward 22 and 66 px to get 0.25 and 0.1 gain. The Fine bubble shows. Return across both thresholds with no value jump. Pointer capture keeps the original ring.
- [ ] **A-DIAL-12** Marks show 0/25/50/75/100. Snap within 2 points, escape using the unsnapped draft, one visual tick per detent entry. Disable snap in settings. Brightness still floors at 1%. No haptics.

## Toggles

- [ ] **A-TOGGLE-1** Enabling a 7th toggle at M makes it reachable by arc scroll; a 4th ring at M is refused with a size hint.
- [ ] **A-TOGGLE-2** Missing hardware hides its control in the corner and greys it in settings. A selected readout that disconnects keeps its slot with explicit not connected state.
- [ ] **A-TOGGLE-3** Toggle press reaches 0.92 in 80 ms; fill reaches proposed state in 120 ms. A pending command leaves other controls and dismissal usable. A failed command restores last confirmed fill in 120 ms and shows a reason.
- [ ] **A-TOGGLE-4** Arc release snaps in 160 ms with E and no overshoot. Capture interrupts snap from its current offset. Wheel advances one slot. Off-arc targets cannot receive input.
- [ ] **A-TOGGLE-5** At 5 px a toggle can still tap or hold; at 6 px hold cancels and arc scroll owns capture. At 449 ms no hold action; at 450 ms one hold action, release never taps. Drag tracks tangential distance 1:1, snaps in 160 ms with E, wheel moves one slot, end fades match available direction. Repeat at both ends, all corners, touch, mouse, reduced and slow motion.
- [ ] **A-TOGGLE-6** Toggle enable/order and every allowed tap/hold action apply live. Unknown actions report validation errors. Wi-Fi quick detail supports inline connect; no keyboard shows a reason and full-window action. S7 must prove no credential in argv or logs before real secured connections ship.
- [ ] **A-TOGGLE-7** Usage never reorders rings or toggles. Settings alone changes order. Close and reopen after scrolling: the first toggle is visible.
- [ ] **A-TOGGLE-8** Game mode applies only selected runtime options. Off, logout and shell restart restore exact typed baseline values. Failed partial applies roll back. S8 gates release.
- [ ] **A-TOGGLE-9** Theme tap alternates the configured light/dark pair. Hold opens the theme picker. Only a successful stock command read-back confirms the selection. S9 gates release.

## Details

- [ ] **A-DETAIL-1** Long-press at 450 ms opens the detail, and 6 px of toggle movement cancels it.
- [ ] **A-DETAIL-2** Hold at 449 ms does not open detail. At 450 ms it does. A 6 px toggle move cancels. Release after a completed hold never toggles.
- [ ] **A-DETAIL-3** Detail keeps the same anchor and R x R bounds. Radius reaches theme.radius in 200 ms. Fan content is gone by 80 ms; detail is fully visible by 200 ms. Back restores arc offset and focus.
- [ ] **A-DETAIL-4** Volume detail lists playing apps with separate named sliders and the output picker. Removing a stream removes its row safely. Holding Volume opens Media; Shift+Enter follows the same path. Media detail shows title, progress and previous/play/next with 48 px targets.

## Closing

- [ ] **A-CLOSE-1** Every trigger, dismissal and timeout in ux.md section 2 behaves as written.
- [ ] **A-CLOSE-2** An outside tap closes, and the app under it gets no click. The old window keeps focus after close.
- [ ] **A-CLOSE-3** Close completes in 120 ms within one frame from rest. No frame shows scale below 0.8 on ordinary close. No text rotates.
- [ ] **A-CLOSE-4** All dismissal paths retain the outside catcher through close and release it on completion. Forced hide is immediate. Verify layer focus and first-map compositor timing by hand.

## Theme

- [ ] **A-THEME-1** A live switch White to Tokyo Night to Flexoki Light recolors with no reload and passes the contrast rules.
- [ ] **A-THEME-2** No hard-coded color exists in QML (grep for `#` color literals outside tests).
- [ ] **A-THEME-3** With animations off, open, close and drill-down are instant.
- [ ] **A-THEME-4** Reduced motion switches every active animation to its semantic endpoint in one frame. Pending remains dashed and static. Gesture deadlines stay unchanged.
- [ ] **A-THEME-5** Switch themes twice during a drag. Geometry and capture stay unchanged. Colour targets retarget within one frame and settle in 160 ms. Check text and control contrast at intermediate colours.

## Corners and sizes

- [ ] **A-SIZE-1** Every target measures 48 px or more; every ring band 44 px or more.
- [ ] **A-SIZE-2** All 4 corners mirror correctly; portrait rotation keeps R within 45% of the short side.
- [ ] **A-SIZE-3** Repeat entry, drag, arc scrolling and detail in four corners. Text stays upright, minimum stays at the side edge, and order remains unchanged.
- [ ] **A-SIZE-4** In all four corners, test all text boxes together with a 32-byte SSID, a long network name, a 64-character Bluetooth name and labels expanded to 1.4x. At M and L, status uses a 120 px box with up to two 18 px lines. Longer status hides the battery number and line and uses a 144 px box with up to four lines above the profile chip. If it still does not fit, show the whole text in a 260 px notice beside the fan. Compact always uses the notice for 2.5 s after an action; errors remain until the next action. Short status restores battery copy. No clipping, ellipsis, overlap or font below 12 px. Detail rows grow and remain scrollable.
- [ ] **A-SIZE-5** At M in all four corners, test long Wi-Fi status. At M and L, status uses a 120 px box with up to two 18 px lines. Longer status hides the battery number and line and uses a 144 px box with up to four lines above the profile chip. If it still does not fit, show the whole text in a 260 px notice beside the fan. Compact always uses the notice for 2.5 s after an action; errors remain until the next action. Short status restores battery copy. No clipping, ellipsis, overlap or font below 12 px.

## Settings

- [ ] **A-SET-1** Settings changes show in the preview and in the open corner within 1 s.
- [ ] **A-SET-2** Reset all, then Undo, restores the old config exactly.

## Access

- [ ] **A-ACCESS-1** Keybind and IPC opens get keyboard focus; Escape goes back, then closes (verify by hand).
- [ ] **A-ACCESS-2** 3-finger and 4-finger swipes behave the same with omadials on and off.
- [ ] **A-ACCESS-3** No trigger zone with a fullscreen window or on the lock screen.
- [ ] **A-ACCESS-4** Tab reaches every control in the documented order; arrows, Page keys, Home and End work.
- [ ] **A-ACCESS-5** A screen reader reads names and values on the layer surface (verify by hand).

## Performance

- [ ] **A-PERF-1** In the stated 30 s Z13 performance run, capture frame intervals and UI/render work. Meet the budgets above with both normal and reduced motion. Record shader and Shape fallback results separately.
- [ ] **A-PERF-2** Closed and resting open views have no visual frame callbacks. Pending-only motion is confined to pending controls. Dismissal never waits for a command.

## Corner icon

- [ ] **A-ICON-1** In each icon mode a tap in the 32 px zone opens, also with a window covering the corner and the icon behind it.
- [ ] **A-ICON-2** In `onApproach`, a pointer that rests in the zone for 2 s shows the icon and never opens the fan by itself.
- [ ] **A-ICON-3** The icon never appears over a fullscreen window or on the lock screen.
- [ ] **A-ICON-4** An invalid custom icon falls back to the default icon and is reported in settings, never silently.

## Previous numbering

| Old number | Stable ID |
|---|---|
| 1 | A-OPEN-1 |
| 2 | A-CLOSE-1 |
| 3 | A-OPEN-2 |
| 4 | A-ACCESS-1 |
| 5 | A-CLOSE-2 |
| 6 | A-ACCESS-2 |
| 7 | A-ACCESS-3 |
| 8 | A-DIAL-1 |
| 9 | A-DIAL-2 |
| 10 | A-DIAL-3 |
| 11 | A-SIZE-1 |
| 12 | A-DETAIL-1 |
| 13 | A-DIAL-4 |
| 14 | A-ACCESS-4 |
| 15 | A-ACCESS-5 |
| 16 | A-SIZE-2 |
| 17 | A-THEME-1 |
| 18 | A-THEME-2 |
| 19 | A-THEME-3 |
| 20 | A-TOGGLE-1 |
| 21 | A-TOGGLE-2 |
| 22 | A-SET-1 |
| 23 | A-SET-2 |
| 24 | A-OPEN-3 |
| 25 | A-CLOSE-3 |
| 26 | A-OPEN-4 |
| 27 | A-DIAL-5 |
| 28 | A-DIAL-6 |
| 29 | A-DIAL-7 |
| 30 | A-TOGGLE-3 |
| 31 | A-DETAIL-2 |
| 32 | A-TOGGLE-4 |
| 33 | A-DETAIL-3 |
| 34 | A-DIAL-8 |
| 35 | A-THEME-4 |
| 36 | A-THEME-5 |
| 37 | A-SIZE-3 |
| 38 | A-PERF-1 |
| 39 | A-PERF-2 |
| 40 | A-CLOSE-4 |
| 41 | A-SIZE-4 |
| 42 | A-TOGGLE-5 |
| 43 | A-TOGGLE-6 |
| 44 | A-DIAL-9 |
| 45 | A-DIAL-10 |
| 46 | A-DIAL-11 |
| 47 | A-DIAL-12 |
| 48 | A-TOGGLE-7 |
| 49 | A-DETAIL-4 |
| 50 | A-TOGGLE-8 |
| 51 | A-TOGGLE-9 |
| 52 | A-SIZE-5 |
| 53 | A-ICON-1 |
| 54 | A-ICON-2 |
| 55 | A-ICON-3 |
| 56 | A-ICON-4 |
