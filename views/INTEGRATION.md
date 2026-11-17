# Views handoff

Only `views/*` and `vm/FanModel.qml` are owned by this change. Service.qml is unchanged.

## Service.qml wiring

1. Import `core`, `vm`, `views`, and `theme`. Instantiate `ConfigStore`, `Registry { store: configStore; active: fanModel.open }`, `Theme`, and one `FanModel`. Bind `configStore.catalog` to `registry.catalog` and supply the settings track's validated icon/theme resources to the store.
2. Bind `FanModel.registry: registry` and `config: configStore.config`. Remove the old explicit `rings: [volumeControl]` binding and direct volume control instantiation. Registry owns controls. ControlBase currently calls its stable ID `controlId`, which these views use.
3. Supply `FanModel.battery` and `profile` as ControlBase objects. Use `registry.byId(...)` with a dependency on `registry.revision` so asynchronously created objects rebind. Battery `valueText` supplies the number; `batteryLine` supplies the summary, defaulting to the battery control's label. Set `batteryLine` to the readout adapter's charge/time summary if it provides one. No UPower import belongs in the view.
4. For every eligible output, instantiate one `CornerWindow` and one `TabWindow` as siblings. Pass the same `screen`, `theme`, and `model` to both. Keep them mapped. Do not nest TabWindow in CornerWindow.
5. Pass `config.corner`, `config.size`, and `config.cornerIcon.mode` to `CornerWindow.corner`, `size`, and `iconMode`. Pass an optional theme corner radius as `detailRadius` (default 12 because the current Theme interface has no radius role).
6. To the corresponding TabWindow pass `corner`, `iconMode`, `iconAboveWindows: config.cornerIcon.aboveWindows`, `source: config.cornerIcon.source`, and `tabStyle: config.tabStyle`. Bind `approaching` to that CornerWindow's `approaching` and `fanPresenting` to its `fanPresenting`. The tab has an empty input region and chooses Top or Bottom itself. Handle `iconFailed(source)` in the config problems UI; a failed image falls back to the two-ring mark.
7. Set both windows' `suppressed` on lock, fullscreen on that output, or output ineligibility. Close on workspace switch; call `forceHide()` on output loss. The model's `output` selects the only fan that is drawn. Pointer triggers select their own screen. Before keybind/IPC `show(true)`, set `fanModel.output` to the focused screen; keybind/IPC toggle should explicitly use `show(true)` when opening. Plain `toggle()` is a pointer-style open.
8. Connect `FanModel.settingsRequested()` to the settings panel. The gear is already beside the chip. Keep the IPC status endpoint returning `registry.status()` (already JSON), adding session status if desired.

Activation contract: the model resolves configured tap/hold actions and calls `control.activate(actionName)`; `quickDetail` stays local. Ring taps send `tap`, detail rows send their `key`, and external details send `quickDetail`. Pending controls reject duplicate actions. Several current backends only implement row keys, so their Controls-track activation dispatch must accept the catalog action names and ring `tap` before hardware tap acceptance can pass. Views deliberately contain no backend-specific switches.

## Validation

Every QML file was checked with `/usr/lib/qt6/bin/qmllint -I /usr/lib/qt6/qml <file>`. The two PanelWindow declarations locally suppress only the Quickshell qmltypes `uncreatable-type` false positive: Quickshell creates these through its own engine. All other lint categories remain enabled. Every QML file is below 150 lines. `MotionValue.qml` owns interruption-safe scalar channels; `AnimatedTheme.qml` owns view-local role interpolation and contrast fallback.

An isolated offscreen Quickshell harness loaded Fan, all nested components, and detail entry/back; rendered fan and detail images were inspected. Assertions covered stationary dial release, cancellation without writes, native-value commit, readout write prevention, capture-deferred close, and detail selection/back. The existing test/run-all.sh passed. The offscreen environment cannot create an IPC socket or Wayland surfaces; this does not validate layer behavior.

## Prototype parity and live checks

No browser-only feature required a Canvas or a custom shader. Rings use the device-verified CurveRenderer, pending dashes animate locally, and details render the supplied row schema. Custom detail implementations, credential entry, app sliders and backend-specific actions need richer backend data or their own detail components; the current host intentionally provides generic wrapping action rows.

Shared MotionValue channels retarget from their displayed value with proportional remaining-distance timing and snap to semantic targets when reduced motion is enabled. AnimatedTheme cross-fades theme roles and snaps failing text/control contrast pairs to their new endpoints. These need live capture and contrast verification; the offscreen harness does not certify compositor timing.

Live checks: all four corners and S/M/L under screen caps; icon lookup/tint; long curved labels and battery copy; 32-byte SSIDs and translated detail headers; touch cancellation at 6 px and hold at 449/450 ms; arc snap interruption/end fades; brightness release and rollback; pending/failure read-back; keyboard focus, Tab order and Escape; separate Top/Bottom layers and quarter-disc mask; compositor fade stacking and reversal captures; frame pacing and contrast in the real themes. Detail headers grow the row viewport. A wrapped battery summary still needs a live check against the readout reservations.
