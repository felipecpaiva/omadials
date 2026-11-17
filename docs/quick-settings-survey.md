# Quick settings survey

Written 2026-11-17 after design round 1. Three web research passes: Linux desktop shells, phone and OS control
centers, and radial or dial interfaces. Read only; nothing was installed or run. Several sources are search summaries
or forum posts, not first-hand tests. Treat each idea as a candidate until a design round accepts it.

## What others do, in one line each

| Product | What stands out | Source |
|---|---|---|
| GNOME quick settings | No reorder or remove; users have asked for years | [gnome-shell#7086](https://gitlab.gnome.org/GNOME/gnome-shell/-/issues/7086) |
| Quick Settings Tweaker (GNOME) | Hide, reorder, recolour; per-app volume mixer; media card | [repo](https://github.com/qwreey75/quick-settings-tweaks) |
| Bluetooth Battery Meter (GNOME) | Device battery in the menu; many devices report nothing without BlueZ experimental features | [extension](https://extensions.gnome.org/extension/6670/bluetooth-battery-meter/) |
| KDE Plasma 6 | Scroll on an icon to change brightness or app volume; per-monitor brightness; light/dark toggle (6.7) | [Plasma 6.6](https://www.omgubuntu.co.uk/2026/02/kde-plasma-6-6-released) |
| COSMIC | Accessibility and on-screen keyboard applets as first-class items | [cosmic-applets](https://github.com/pop-os/cosmic-applets) |
| caelestia shell | Each toggle can be turned off; game mode applies a set of Hyprland options; VPN toggle; volume cap | [repo](https://github.com/caelestia-dots/shell) |
| SwayNotificationCenter | Widgets added and reordered in config; user toggles with a state command; no touch support | [repo](https://github.com/ErikReider/SwayNotificationCenter) |
| nwg-panel | One brightness slider per monitor (ddcutil); per-app volume; graphical config | [repo](https://github.com/nwg-piotr/nwg-panel) |
| HyprPanel | Archived 2026-04; its own README calls the config a "JSON mess" | [repo](https://github.com/Jas-SinghFSU/HyprPanel) |
| iOS 18 Control Center | Hold a tile to expand it; controls resize; edits apply at once with no undo (top complaint) | [Apple](https://support.apple.com/ro-ro/102351), [no undo](https://allthings.how/ios-18-control-center-desperately-needs-an-undo-feature) |
| Android 16 | Wi-Fi and Bluetooth details expand inside the panel; the merged Internet tile (2 taps for a radio) drew backlash | [detail view](https://www.androidauthority.com/android-quick-settings-expansion-3521878/), [split tile](https://www.androidauthority.com/android-split-internet-quick-settings-3626933) |
| Samsung One UI 7 | Hold the brightness slider for more options (adaptive switch); hold volume for sound shortcuts | [SammyFans](https://www.sammyfans.com/2025/07/20/samsung-one-ui-7-quick-panel-has-two-hidden-features/) |
| macOS Control Center | Edit mode; pin a control to the menu bar; small or medium size | [Apple](https://support.apple.com/en-mt/guide/mac-help/mchl50f94f8f/26/mac/26) |
| Steam Deck quick access | Performance settings saved per game | [TechSpot](https://www.techspot.com/news/94576-steam-deck-update-adds-game-performance-settings.html) |
| Surface Dial | About 7 items on its radial menu; short labels; ticks make a wheel precise | [Microsoft](https://learn.microsoft.com/en-us/windows/uwp/design/input/windows-wheel-interactions) |
| Apple Watch Digital Crown | Detents must match the visual steps and be uniform | [HIG](https://developer.apple.com/design/human-interface-guidelines/digital-crown.md) |
| Marking menus (Kurtenbach, Buxton) | Fixed positions build muscle memory; they fail when items move around | [summary](https://people.eecs.berkeley.edu/~fox/summaries/ui/marking_menus.html) |
| Mela (dial precision) | Move the finger away from the dial for finer steps | [forum post](https://mela.userjot.com/board/p/experimental-feature-in-4.2-beta-increased-precision-of-dials-and-sliders) |

## What this confirms in our plan

- Details open inside the corner (Android 16 moved the same way).
- Wi-Fi and Bluetooth stay separate one-tap toggles; hold opens the list.
- Hold a dial label for more (Samsung does the same with sliders).
- Choose, hide and reorder everything in a settings app (the most requested GNOME feature).
- Undo in settings (ux.md acceptance 23); iOS shows the cost of leaving it out.
- Bluetooth battery shows "no data" when the device does not report it, never 0%.
- Never write hardware state on startup; only read it (end-4 shipped bugs here).
- Touch first is open ground: no Linux control center we found supports touch well.

## New candidate ideas

| # | Idea | Why | Fit | Conflict |
|---|---|---|---|---|
| 1 | Fine control: drag the finger outward (or inward) from a ring to slow it down, with a "fine" label | A short arc has few pixels per percent | strong | Changes "knob under the finger" while in fine mode |
| 2 | Visible detents at 0, 25, 50, 75, 100 | Ticks make dials precise; the Z13 has no useful vibration | strong | Extends the current tick rule |
| 3 | Order never changes by itself | Muscle memory; marking menu research | strong | None; write it down |
| 4 | Per-app volume mixer as the volume detail | GNOME tweaks, Plasma and nwg-panel all ship it | strong | None |
| 5 | Game mode toggle (turn off animations, blur, gaps in Hyprland) | caelestia; suits the Z13 for games | maybe | Writes Hyprland settings; needs a safe revert |
| 6 | Light and dark theme toggle (or a theme picker detail) | Plasma 6.7; Omarchy has many themes | maybe | None |
| 7 | VPN toggle | Cheap to add | maybe | Needs a VPN backend to exist |
| 8 | On-screen keyboard toggle | The Z13 has no on-screen keyboard; it would also unblock the inline Wi-Fi password | maybe | Depends on an OSK being installed |
| 9 | User-made toggles and readouts (a command plus a state command) | SwayNC and nwg-panel users want them | maybe | Breaks the rule "no commands read from config" (safety) |
| 10 | Per-app or per-monitor profiles (Steam Deck style) | Saved settings per context | weak | Big scope |
| 11 | Media player card | Common in shells | weak | Does not fit a quarter circle |
| 12 | Relative drag (value moves by the change in angle, never jumps to the touch) | Avoids jumps | weak | Our tap never changes a value already; knob under finger is the chosen feel |

## Decisions (maintainer, 2026-11-17)

All ideas are worth keeping. The rule that sorts them: anything that needs an outside app or a new subsystem waits.

| When | Ideas |
|---|---|
| Round 3, design now | 1 fine control (it also covers 12: in fine mode the value moves by the change in angle), 2 visible detents, 3 order never changes by itself, 4 per-app volume detail, 5 game mode toggle with a safe revert, 6 theme toggle or picker, 11 media card as a detail or a fit study |
| Later, needs an outside app | 7 VPN toggle (needs a VPN client), 8 on-screen keyboard toggle (needs an on-screen keyboard installed) |
| Separate future plugin | 9 user-made toggles and actions. This is an Omarchy version of Apple Shortcuts and deserves its own plugin. omadials will later offer a small, documented way for that plugin to add toggles, so omadials itself still never runs commands from its config |

### Added 2026-11-17: the corner itself

- The settings app sets which corner omadials lives in (already in the config as `corner`; it must be a first-class choice in settings, with a live preview).
- The corner shows an icon, so people can see where omadials lives. Default: the omadials app icon (`branding/logo/icon-mono.svg`, tinted by the theme). The user can pick another icon or none. Open design points for the next pass: icon size and resting opacity, how it reacts to hover and press, hiding over fullscreen windows and on the lock screen (already a rule for the trigger zone), and which custom icons are allowed (a local SVG or PNG file, or an icon theme name; read only, size limited, validated).
- Settings: "Show corner icon" on or off. Off still keeps the invisible tap zone, so omadials works without a visible mark.
- Settings: "Keep icon above windows" on or off. On: the icon floats over other windows (layer above them). Off: it sits behind windows and only shows on an empty desktop. Either way the tap zone and the fullscreen and lock screen rules stay the same. Decided (maintainer): only the icon moves behind windows. The tap zone always stays reachable above windows, even when the icon is hidden or covered.
- Icon visibility becomes a closed set of 3 modes: `always`, `onApproach`, `never`. Proposed (maintainer idea, 2026-11-17): `onApproach` keeps the icon hidden until the mouse pointer enters the corner zone, then fades it in (80 ms, it takes the place of the hint arc); a click on it opens. In this mode the 150 ms push-to-open is off by default, so a pointer passing by only shows the icon and never opens the corner by itself. Touch has no hover, so a tap in the zone always opens, in every mode.
- Limit to check: a layer only sees the pointer inside its input mask, and that mask also catches clicks. So the reveal area must be the same small zone as the tap zone (32 px), not larger, or it would eat clicks on windows below. Part of spike S3.
