# Roadmap

What comes after v0.7.0. The working plan with dates and "Done when" checks is [plan.md](plan.md); this page is the
short public view. Nothing here is promised by a date.

## Shipped in v0.7.0

The first public release. Earlier milestones (v0.1 to v0.6 in the plan) were built but never tagged on their own; they
are all part of v0.7.0.

- The corner: rings for brightness, volume and mic, a toggle arc, the battery and power profile readout, details on
  long press, six open styles.
- The settings app (`omadials-settings`), with a live preview, following the Omarchy theme.
- New in this round: a battery ring (closed tab and open corner, red below a level you choose), a tab size setting,
  rest to open as its own setting, and fixes for every setting found dead in the settings validation
  ([settings-validation.md](settings-validation.md)).

## Next: v1.0

- **A real second monitor.** The "Screens" setting is written and unit tested, but it was never seen on two screens.
  The multi-monitor rules are in [ux.md](ux.md) section 5. It must be a real monitor, never a virtual one.
- **Two weeks of daily use on the Z13,** bugs only. v1.0 is tagged when no blocker is open.
- **Keyboard and screen reader** in the corner: tab order, arrows, Escape (plan P4.5).
- **Portrait screens** (plan P5.5) and a capture of reversing the open motion half way (plan P4.4).
- **Media players** in the corner with a running player (plan P1.8).
- **Marketplace listing** (plan P8.2), after v1.0.

## Known gaps

Small things found during the v0.7.0 checks. None blocks daily use.

- The touchpad and touchscreen toggles are in the default list but stay at "probing" on the Z13, so they never
  switch. They need a backend check.
- The `open` IPC command can open the corner on a screen that "Screens" turned off.
- An old settings file with a wrong light or dark theme name (the theme pair was removed) can raise a banner that has
  no setting left to fix it.
- Adding a "Laptop battery" display ring on the Rings page while the battery ring is on shows the battery twice.
- With a small tab size, a drag starts to open the corner a few pixels outside the tab edge.
- Some settings keys are accepted but not read yet: `readout.battery`, `readout.powerProfile`, `readout.penBattery`,
  and the fine control distances and gains (the plugin uses its own constants).
- The live test script cannot send a mouse wheel that reaches the corner, so the wheel step is checked by a unit test
  and by hand only.

## Later

These need an outside app or their own project.

- A VPN toggle (needs a VPN client).
- An on-screen keyboard toggle (needs an on-screen keyboard). It also unlocks typing a Wi-Fi password in the corner.
- omadials and OmaBar working together: when a control is in one, offer to hide it in the other. Always ask first.
- A small, documented hook for a future Shortcuts style plugin (user-made toggles and actions). omadials itself never
  runs commands from its own settings file.
