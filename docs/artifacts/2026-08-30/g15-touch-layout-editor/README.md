# Touch layout editor and reset

The pinned twelve-file SunPad component remains byte-identical. A
Simulator-only KartPad owner-layer probe exposes the unchanged settings
scroll view's lower rows so the real editor and reset actions can be exercised
without adding product UI or changing SunPad source.

## Move, select, resize, and persist

- Target: the sole iPhone 17 Pro Simulator on iOS 26.5.
- The real `Move controls` switch's value-change action entered layout-editing
  mode, hid the settings panel, outlined the editable controls, and exposed the
  editor bar.
- The real A control was selected and its real `A size` slider action changed
  the scale to `1.25`.
- Runtime evidence reported `move/resize pass (A=1.25)`. Accessibility exposed
  `A size`, value `1.25`, and `Finish moving touch controls`; invoking Done
  removed the editor bar.
- The application preference file independently contained
  `SunPadControlSizeScales = { A = 1.25; }` after Done.
- Screenshot: `move-resize-a.png`, SHA-256
  `34df199deb8de4e495731a0e7a2f1b0f00097f5645fb54835585d05900332ae3`.

## Confirm reset and restore defaults

- A bounded test origin for A was added before invoking the real
  `Reset This Device Layout` button.
- The native destructive confirmation exposed the exact title, explanatory
  text, Cancel, and Reset actions. Reset was confirmed through accessibility.
- The preference file then contained none of `SunPadControlOrigins`,
  `SunPadControlSizeScales`, `SunPadControlSizeScale`, or
  `SunPadControlOpacity`.
- A normal launch without the probe restored the default A size and ordinary
  overlay while retail rendering continued.
- Confirmation screenshot: `reset-confirmation.png`, SHA-256
  `0f815bec1729389ace88ef86a229905f0a46fa1cd079306011b03d3a219e00b5`.
- Restored screenshot: `reset-restored-default.png`, SHA-256
  `d2851c3a100b97142bdb795603ac94913f8274d03e01d020b06c80a1ef424283`.

## Build and scope

- Full Simulator app audit: pass; executable SHA-256
  `cbea21a728182be320d18d14d681248f4433e50f0617ac0c5bb731efecac2a34`.
- Full unsigned physical-iOS app compile/link/audit: pass; executable SHA-256
  `cf1d4ccdb20b52d52231b272b1538896ead972fdc18096fcae766d4497416e00`.
- The physical binary contains no `KARTPAD_TOUCH_EDITOR_UI_TEST` contract.
- Exact SunPad snapshot: byte-identical at
  `e43f0ea6b797e5110787171957c9dc3c6213269c`.
- The app and sole Simulator were terminated and shut down. Finger-drag feel
  remains a hands-on device acceptance row; it is not inferred from this
  deterministic editor/action test.

Classification: **Pass for editor entry, control selection, per-control resize,
persistence, Done, destructive reset confirmation, reset semantics, and
default restoration.** Physical finger-drag ergonomics remain open.
