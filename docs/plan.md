# omadials plan

The single plan from today to v1.0. Written 2026-11-17, after design rounds 1 to 3. It replaces the milestone table in
`architecture.md` section 13.

## How to use this plan

- **A day goal is one line below.** Pick the next open line in the current phase. Each has an ID (for example `P2.3`),
  what to build, and **Done when**, which is how we prove it.
- **One phase at a time.** A phase starts when the one before it meets its exit check. Phases 1 and 2 may overlap: spikes
  only read and test, they change no plugin code.
- **Mark progress here.** `[ ]` open, `[x]` done (with the date), `[~]` started. Commit this file with the work.
- **Design changes go to the docs first.** If a day turns up a design change, update `ux.md` or `experience.md`, then the
  prototype, then this plan. Never only in code.
- **Standing rules on the Z13.**
  - Live input tests only after asking if Felipe is using the machine.
  - No virtual monitors.
  - Nothing private in the repo (no hostnames, home paths or IPs).
  - Every release ships at least one GIF of its features.

## Phase overview

| Phase | Name | Goal | Version | Days |
|---|---|---|---|---|
| P0 | Design close-out | No open "Your call" lines; design frozen for v0.1 to v0.3 | none | 1 to 2 |
| P1 | Z13 spikes | Every UNVERIFIED platform claim proven or replaced | none | 3 to 4 |
| P2 | Foundation | Pure logic, config, runner, registry, theme adapter, with tests | none | 4 |
| P3 | The corner | The fan opens, shows real values, closes, in one corner | v0.1 | 4 |
| P4 | Touch and feel | Every gesture and motion from `experience.md` on the Z13 | v0.2 | 4 |
| P5 | Settings panel | Every setting from the prototype, live, with Undo | v0.3 | 4 |
| P6 | Details | Wi-Fi, Bluetooth, audio per app, power, displays, theme, media | v0.4 | 5 |
| P7 | Extras and freeze | Readout rings, game mode, hardware extras, schema v1 frozen | v0.5 | 4 |
| P8 | Release and listing | Public release with GIFs; marketplace request | v0.6 | 2 |
| P9 | Settings app | Standalone C++ and Qt Quick app on the frozen config | v0.7 | 4 |
| P10 | Daily use | Two weeks on the Z13, a real second monitor, fixes only | v1.0 | 14 calendar days |
| Later | Outside apps | VPN toggle, on-screen keyboard toggle, Shortcuts plugin hook | after 1.0 | open |

Days are working sessions, not calendar days, and they are estimates.

## P0. Design close-out

Goal: answer every open question so code never waits on a decision. Source: the "Your call" lines on the review page.

- [x] **P0.1 Answer the 9 open calls.** (2026-11-17, all recommendations taken; see `architecture.md` section 14) Custom corner icons, no bounce on early release, volume above 100%, ring radii,
  size L on the Z13, very small screens, bar widgets, bar button, settings app timing. Each has a recommendation.
  Done when: each answer is written in `ux.md`, `experience.md` or `architecture.md`, and the board shows 0 "Your call".
- [x] **P0.2 Pick the defaults.** (2026-11-17: 2 rings and a knob, Normal, gear beside the chip, hardware-first toggles; `ux.md` Defaults) Corner tab (2 rings and a knob, or 3 rings), default size (Normal), default toggles at
  each size. Done when: written in `ux.md` and set as the prototype defaults.
- [x] **P0.3 Docs pass.** (2026-11-17: round notes merged, one checklist in `acceptance.md`, S1 to S9 numbered) Read the design docs end to end, consolidate topic sections, use the shared
  `acceptance.md` checklist and remove stale text. Done when: one reading order works
  (`architecture.md`, `ux.md`, `experience.md`, `controls.md`) with no contradiction.
- [x] **P0.4 Design freeze tag.** (2026-11-17, tag `design-1`) Done when: tag `design-1` pushed; the review page says "Design frozen for v0.1 to v0.3".

Exit check: 0 open calls, `design-1` tag.

## P1. Z13 spikes

Goal: prove each platform claim marked UNVERIFIED before building on it. Each spike is a tiny throwaway plugin or
script under `spikes/`, a written result in `docs/spikes.md` (how verified, result, what changes), and no change to
the real plugin. A failed spike is a good result: it changes the design in the docs.

- [x] **P1.1 S1 and S2.** S1: plugin-local `pragma Singleton`. S2: FileView sees a file created after load. Done when:
  both results in `docs/spikes.md`.
- [~] **P1.2 S3 input mask.** (all cases pass live; the 60 fps capture is still open) The 32 px zone switches to a full-screen catcher and back; the icon tab above or behind
  windows; on-approach reveal inside the zone only; outside tap does not reach the app below. Done when: each case
  recorded with a 60 fps capture.
- [~] **P1.3 Layer fade and focus (S3).** (2026-11-17: pointer opens do not take keyboard focus; no stacked compositor fade in the capture; IPC keyboard focus still open) Hyprland layer fade stacking with ours; OnDemand keyboard focus; old window keeps
  focus after close; off over fullscreen and the lock screen. Done when: recorded, design adjusted if needed.
- [x] **P1.4 S4 screen reader** on a layer surface. Done when: result recorded; fallback written if it fails.
- [x] **P1.5 S5 display writes** (refresh and scale on the Lua config, with revert) and **S6 power profile D-Bus
  events**. Done when: both recorded.
- [ ] **P1.6 S7 Wi-Fi password through stdin** (not approved; inline Wi-Fi password stays off) (`nmcli --ask`): connect, wrong password, cancel; the password never in
  argv or logs. Done when: recorded with a `/proc/<pid>/cmdline` check.
- [x] **P1.7 S8 game mode runtime writes and S9 theme command.** Hyprland runtime set and exact revert, including after a
  shell restart; `omarchy-theme-set`. Done when: both recorded.
- [~] **P1.8 Pipewire app streams and Mpris.** (audio streams pass; Mpris with a running player still open) Per-app volume nodes and media players seen from Quickshell. Done when:
  recorded.
- [x] **P1.9 Rendering budget.** Ring fill by shader and by Shape, both measured at 2560x1600 scale 1.6667. Done when:
  frame times recorded; the faster path chosen in `experience.md`.

Exit check: every spike has a result; docs updated wherever a spike failed.

## P2. Foundation

Goal: everything that can be tested without a screen exists and is tested. Follows `architecture.md` layers and
`engineering-standards.md`.

- [x] **P2.1 Repo skeleton.** `manifest.json`, plugin layout from `architecture.md` section 7, `test/run-all.sh`,
  `test/isolation.sh` (only `core/CommandRunner.qml` starts processes, only `theme/Theme.qml` reads `Commons.*`, no
  colour literals in QML). Done when: `omarchy plugin validate` passes and both test scripts run green on an empty plugin.
- [x] **P2.2 Geometry.js.** Canonical points, 4-corner mirroring, ring radii per size, sweep (rings 3 to 87, toggles 6
  to 84), label paths left to right, text boxes, the screen cap. Done when: Node tests cover all 4 corners and 3 sizes.
- [x] **P2.3 Gesture.js and Motion.js.** Tap, drag threshold 6 px, ring lock, long press 450 ms, arc scroll and snap,
  fine control gains, detents and snap window, interruption math. Done when: Node tests for each rule in
  `experience.md`.
- [x] **P2.4 Config.** Schema draft, validation that reports and never silently fixes, atomic write, live reload,
  defaults. Includes sizes, corner, icon modes, control visibility and icons, ring styles, readouts, toggle actions.
  Done when: fixture tests for valid, invalid and partial files.
- [x] **P2.5 Runner, registry and CommandMachine.** Closed sets for kind, availability, write state. One control end to
  end in tests (volume) with a fake runner. Done when: tests green, isolation check green.
- [x] **P2.6 Theme adapter.** Roles from `Commons.Color`, light or dark from background luminance, contrast fallback, no
  `muted` for text. Done when: tests with the White, Tokyo Night and Flexoki Light palettes.

Exit check: `run-all.sh` green, isolation green, validate passes.

## P3. The corner (v0.1)

Goal: open the corner on the Z13 and change real values.

- [x] **P3.1 Corner window.** Dock-pattern layer window in one corner, mask closed and open (from P1.2), IPC
  `open|close|toggle`, keybind documented. Done when: opens and closes by IPC on the Z13.
- [x] **P3.2 Rings.** Brightness, volume, mic from real backends, labels on the curve, detent marks, ring styles. Done
  when: dragging changes the real value; [acceptance.md](acceptance.md) A-DIAL-1, A-DIAL-2, A-DIAL-3 by hand.
- [x] **P3.3 Toggle arc and readout.** Six toggles with real state, pending and failure states, battery readout,
  profile chip, status line rules (wrap, give way, notice). Done when: each toggle switches real hardware; no text
  overlaps in the long-text test.
- [x] **P3.4 Corner tab and open motion.** (2026-11-17: tab live; 60 fps capture matches 180/120 ms, docs/spikes.md) Tab in all icon modes, 180 ms open with ring stagger, 120 ms close,
  reduced motion. Done when: a 60 fps capture matches `experience.md` timings.
- [ ] **P3.5 Release v0.1.** Tag, GIF, README status. Done when: pushed and the GIF is in the release.

## P4. Touch and feel (v0.2)

- [~] **P4.1 Opening gestures.** (tap open and outside close pass live; drag-open and push dwell need hands) Corner tap, drag-open past 40%, push dwell, on-approach reveal. Done when: [acceptance.md](acceptance.md)
  A-OPEN-1, A-OPEN-2, A-ICON-1, A-ICON-2, A-ICON-3, A-ICON-4 by hand.
- [~] **P4.2 Dial feel.** (drag follows the finger, fine mode seen live; detent feel needs hands) Fine control by distance, detent snap, value bubble, step ticks. Done when: the matching
  acceptance items by hand.
- [x] **P4.3 Arc scroll and long press.** (arc slide scrolls and fires no toggle; hold opens the detail, live 2026-11-17) Press and slide, snap, wheel, end fades, hold for detail. Done when: matching
  acceptance by hand.
- [~] **P4.4 Interruptions and dismissal.** (outside close passes; reversal capture open) Reverse mid-animation, every dismissal path, nothing closes during a drag.
  Done when: capture shows no jump.
- [ ] **P4.5 Keyboard and access.** Tab order, arrows, Escape, screen reader (per P1.4). Done when: [acceptance.md](acceptance.md) A-ACCESS-4 and A-ACCESS-5.
- [ ] **P4.6 Release v0.2** with GIF.

## P5. Settings panel (v0.3)

> 2026-11-17: superseded. The maintainer chose one settings surface, the app (P9); the panel was removed and the
> corner gear opens the app. P5's settings content now lives in the app.

- [x] **P5.1 Panel shell** with live preview and the problems banner. Done when: opens from IPC and the corner.
- [x] **P5.2 Layout settings.** Corner, size (Compact, Normal, Large, with the cap message), corner tab and icon modes,
  above or behind windows. Done when: each change applies live within 1 s.
- [x] **P5.3 Control settings.** (2026-11-17: every field exercised by the app sweep, 52 of 52 writes, 3 themes) Show or hide, icon, order for every toggle and ring; toggle tap and hold actions; ring
  styles. Done when: same.
- [ ] **P5.4 Undo and reset.** Done when: [acceptance.md](acceptance.md) A-SET-2.
- [~] **P5.5 All 4 corners and portrait.** (4 corners and 3 sizes checked by screenshots 2026-11-17; portrait open) Done when: [acceptance.md](acceptance.md) A-SIZE-2 on the Z13.
- [ ] **P5.6 Release v0.3** with GIF.

## P6. Details (v0.4)

- [x] **P6.1 Detail frame.** Morph in 200 ms, back, focus restore, async rows.
- [~] **P6.2 Wi-Fi.** (list, connect saved and full window live; inline password off until S7) List, connect saved, inline password through stdin (P1.6), no-keyboard fallback, full window
  action.
- [~] **P6.3 Bluetooth.** (device rows live; battery where reported needs a headset) Power, devices, battery where reported ("no data" otherwise).
- [x] **P6.4 Audio.** (outputs, inputs and app sliders seen live 2026-11-17) Output and input pickers, per-app volume (P1.8).
- [~] **P6.5 Power profile, displays** (displays detail live; confirm and revert needs hands) (brightness per monitor; refresh and scale with confirm and revert per P1.5).
- [~] **P6.6 Theme picker and media detail** (theme list and media "No media playing" live; a playing player untested) (P1.7, P1.8).
- [ ] **P6.7 Release v0.4** with GIF.

Done when (each): contract tests for the detail, plus a hand check on the Z13.

## P7. Extras and freeze (v0.5)

- [~] **P7.1 Readout rings.** (Wi-Fi signal ring live; Bluetooth device and pen need the devices) Bluetooth device battery (pick the device), Wi-Fi signal, laptop and pen battery; not
  connected shown truthfully.
- [x] **P7.2 Game mode toggle** (2026-11-17, on and off verified live, docs/spikes.md) with exact revert (P1.7).
- [~] **P7.3 Hardware extras.** (2026-11-17: touchpad, touchscreen and charge limit read live; writes and the touchscreen guard need hands) Keyboard light, charge limit, touchpad, touchscreen guard, airplane restore.
- [x] **P7.4 Schema v1 freeze.** (2026-11-17, docs/file-contract.md) `docs/file-contract.md`, migration rule for later versions.
- [ ] **P7.5 Release v0.5** with GIF.

## P8. Release and listing (v0.6)

- [x] **P8.1 README for users.** (2026-11-17; screenshots to add) What it is, install, every file it writes, uninstall, GIFs, the not-affiliated line.
- [ ] **P8.2 Marketplace request** with `preview.png`, following the OmaBar and omagnet listings. Freeze master while
  the request is open.

## P9. Settings app (v0.7)

- [x] **P9.1 App skeleton** (2026-11-17: builds with qmake6 and make, follows the theme) (C++, Qt Quick, qmake, Omarchy theme live).
- [x] **P9.2 Every setting from P5** (same pages; real config validated read-only with `check --json`) on the frozen schema, reusing the logic JS.
- [x] **P9.3 Live apply** (2026-11-18: app edits on the real file apply live; ring style and tab size seen on the Z13; see docs/settings-validation.md) to the running plugin, and a `status()` IPC check.
- [~] **P9.4 Package and release v0.7.** (2026-11-18: package built and installed on the Z13; version bump, tag and release not done)

## P10. Daily use (v1.0)

- [ ] **P10.1** A real second monitor (never a virtual one); multi-monitor rules from `ux.md` section 5.
- [ ] **P10.2** Two weeks of daily use on the Z13, bugs only. Done when: no open blocker; tag v1.0.

## Later (after v1.0, needs an outside app or its own project)

- VPN toggle (needs a VPN client).
- On-screen keyboard toggle (needs an on-screen keyboard installed; also unblocks inline Wi-Fi passwords in tablet mode).
- omadials and OmaBar coordination: when a control is enabled in one, offer to hide it in the other. Always ask.
- A small documented hook for the future Shortcuts plugin (user-made toggles and actions). omadials itself never runs
  commands from its config.
