# Settings experience

The settings app (`app/`) and the shell panel (`settings/`) share one information design. Review of v0.7 on
2026-11-17 (maintainer: "it works but looks a bit confusing"): a long flat form, config-key labels, a controls wall
with per-control style blocks, backwards game mode wording, empty theme pair, raw JSON on About, Reset at the top,
the preview on one page only.

## Layout

- Window: navigation on the left, content in the middle, a **live preview on the right on every page** (the real
  corner drawing at 60 %, updating within a second). Narrow window: the preview moves above the content.
- Navigation (one active item clearly highlighted with the accent): **Corner, Rings, Toggles, Behavior, About**.
- No repeated banner. Errors show only when there are some, as a banner at the top of the page they belong to,
  naming the setting in words and offering a fix ("Use the default").
- Every setting is a row: a plain-language label, one line of help under it in the secondary colour, the control on
  the right. Rows are grouped in cards with a short heading.

## Pages

**Corner**
- Card "Where": Corner (four picture buttons, one per corner), Screens ("All screens" / "Focused screen" /
  "Choose screens" which then shows screen checkboxes by name, never a comma field).
- Card "Size": Compact / Normal / Large as three cards with a one-line description each and the cap note when the
  screen limits it ("Large is limited to 450 px on this screen").
- Card "Corner tab": style as picture buttons (2 rings and a knob, 3 rings, 3 rings and a knob, your own icon),
  "Show the tab" (Always / When the pointer is near / Never), "Above windows" switch with help
  ("Off: the tab hides behind windows; the corner still opens").
- Card "Opening": "Open when the pointer rests in the corner" switch with the delay as a small slider (0 to 500 ms),
  shown only when on. The tap zone switch moves to Advanced (About page) with a warning.

**Rings**
- A compact ordered list of ring controls (Brightness, Volume, Mic, readout rings). Each row: drag handle (and
  up/down buttons for keyboard), icon, name, value now, Show switch. Capacity line on top: "3 of 4 rings fit at Large".
- Tap a row to expand its details inline: Icon (picker with the glyph shown), Track, Knob, Thickness (picture choices,
  showing the ring drawn that way), Wheel step for that ring.
- "All rings" style card at the top; a ring overrides it only when changed ("Uses the common style" / "Custom").
- "Add a display ring": source (Bluetooth device battery with a device picker by name, Wi-Fi signal, Laptop battery,
  Pen battery).

**Toggles**
- The same compact list for toggles, with "N visible without scrolling at this size" on top.
- Expanded row: Icon, "When tapped" and "When held" as plain choices ("Switch on or off", "Open the quick list",
  "Open the full window").

**Behavior**
- Card "Closing": "Close after" (Never, 5, 10, 20, 30 s), "Close when the pointer leaves".
- Card "Dials": "Fine control when you drag away from the ring", "Snap to 0, 25, 50, 75 and 100 %",
  "Volume can go above 100 %" with the maximum (up to 150).
- Card "Theme toggle": "Light theme" and "Dark theme" pickers, pre-filled with the current theme and a sensible
  opposite (a light and a dark installed theme), never left empty.
- Card "Game mode": "When game mode is on, turn off:" with switches Animations, Blur, Shadows, and "Window gaps
  become 0". Wording always says what game mode does.

**About**
- Version, what the plugin is, a link to the README.
- "Plugin status": a readable list, one row per control: name, "Working" / "Not on this machine (reason)" /
  "Problem (reason)". The raw JSON only behind "Copy details".
- Card "Advanced": settings file path with "Open folder", the tap zone switch with its warning.
- Card "Reset": at the bottom, "Reset everything to defaults" with an in-page confirmation, then the 10 s Undo bar.

## Words

Plain English, sentence case, no config keys or units in labels (units go in the help line or the field suffix), no em
or en dashes. "Show on screen" becomes "Show the corner".

## Round 2 (maintainer, 2026-11-17: "I can't find a way easy enough to remove the rings or adjust")

Rings and Toggles become an edit list in two sections, like a phone's control center editor:

- **In the corner**: one row per control in corner order. Row: drag handle, icon, name, value now, an **Edit**
  button (pencil, 48 px) and a **Remove** button (minus in a circle, 48 px, warn colour on hover). Up and down
  buttons appear on keyboard focus and on long press for touch. A capacity line on top ("3 of 4 rings fit at Large");
  when full, Add buttons below are disabled with "Remove one first, or choose a larger size".
- **Not in the corner**: the rest, each with an **Add** button (plus in a circle). Display rings (Bluetooth device,
  Wi-Fi signal, laptop and pen battery) live here too, with their source picker shown when added.
- **Edit** opens a side sheet over the preview (bottom sheet when narrow) for that one control: icon (built-in glyphs
  as a grid of real icons, plus "Type an icon name"), and for rings Track, Knob and Thickness as picture choices drawing
  the ring that way, wheel step, and "Use the common style" (on by default). For toggles: When tapped, When held.
- The preview highlights the control being edited, and clicking a ring or toggle in the preview opens its Edit sheet.
- Removing never deletes settings: a removed control keeps its icon and style for when it is added back.
- The common ring style stays as one card at the top of Rings ("All rings").

## Animation setting (maintainer, 2026-11-17)

A card "Animation" on the Behavior page: **Style** as picture choices that play a small looping preview of each motion
(Tab morph, Hybrid, Lens, Spring cascade, Minimal, Fan, from `docs/prototype/motion-lab.html`), **Speed** (0.5x to 2x)
and, for spring styles, **Bounce** (0 to 0.35). Rule for every style: it opens out of the closed tab and closes back
into it, and its first and last frames are exactly the tab (checked pixel by pixel in the lab). Reduced motion always
uses Minimal without movement.
