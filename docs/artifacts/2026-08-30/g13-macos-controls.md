# macOS controls convergence

This checkpoint closes the Mac controls-discoverability gap without changing
the mobile SunPad component or controller mappings.

## Product changes

- Native **KartPad → Controls…** panel, also exposed as `Command-/`.
- Visible Player 1 keyboard map for steering, accelerate/confirm,
  brake/reverse/back, drift, items, tricks, pause, select, X/Y, ZL/ZR, and F10.
- Left Shift now publishes Classic L for items.
- Tab now publishes Classic minus/select.
- The panel routes controller users to the existing remapping and stable
  Player 1–4 assignment UI.

## Verification

- `git diff --check`: pass.
- Upstream runtime patch dry-run against the immutable pin: pass.
- arm64 translated-runtime compile and link: pass.
- signed package audit, including controls-panel string contracts: pass.
- unsigned executable SHA-256:
  `162007d4be078232c5f91707a193a313f3daebd2ec58578c8d90db0fdf84d4f3`.
- audited bundle-content SHA-256:
  `5fbc01bf36428c4611358cc7d24e023fe168ec4b3ff203b9f4d8b9bcac77dff4`.
- single-runtime visual check: the complete panel rendered without clipping in
  dark mode over the running 60 FPS title presentation.
- shutdown: normal application-menu Quit; afterward there were zero KartPad
  processes, zero Simulator.app processes, and zero booted Simulator devices.

This is acceptance of the Mac control surface and discoverability. It does not
claim physical-controller feel, physical iPhone/iPad behavior, or a long-run
reliability soak.
