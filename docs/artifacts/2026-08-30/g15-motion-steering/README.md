# G15 configurable motion-steering checkpoint

Status: **Pass for implementation, deterministic mapping, arm64 Simulator/device
compilation, package audit, and Simulator UI fallback. Physical-device
calibration and a complete motion-steered race remain open.**

KartPad adds motion steering in its owning integration layer around the exact,
byte-identical SunPad touch component. No copied SunPad file changed. The
KartPad-owned top-level menu extension now places `Motion Steering…` beside
`Multiplayer…`, ahead of SunPad's unchanged menu children.

The CoreMotion implementation:

- defaults off and persists enabled, inversion, and 0.5x/1.0x/2.0x sensitivity;
- calibrates the first valid gravity-plane sample and supports explicit
  recentering;
- applies a continuous dead zone, wrapped angles, bounded sensitivity, and
  clamped full-lock output;
- mixes by strongest magnitude with Player 1 touch steering, so touch can
  override motion without changing the exact SunPad mixer;
- yields to any connected physical controller;
- clears motion steering on background/uninstall and restarts only when enabled;
- rejects unavailable and invalid sensor input as neutral.

Verification:

- `kartpad.mobile.classic-input`: pass.
- `kartpad.mobile.physical-controller`: pass.
- `kartpad.mobile.motion-steering`: pass for neutral/dead-zone, positive and
  negative steering, clamp, inversion, angle wrap, sensitivity, and invalid
  sensor vectors.
- Exact twelve-file SunPad snapshot
  `e43f0ea6b797e5110787171957c9dc3c6213269c`: pass.
- Complete 29,065-function arm64 Simulator compile/link and strengthened app
  audit: pass. Executable SHA-256:
  `c87a1c4ef6577dce0e72b27c4070d611cae6f4b7a5e59284cd6bb1d94f12e25c`.
- Unsigned arm64 physical-iOS shell compile/link and IOS package audit: pass.
- Exactly one iPhone 17 Pro / iOS 26.5 Simulator launched. The live retail game
  retained the exact touch overlay, the menu exposed the new owned action, and
  the action sheet accurately reported that Simulator motion data was
  unavailable while preserving touch/controller steering. Gameplay continued
  afterward. The final candidate also backgrounded to Home and resumed to the
  live touch surface. The app was terminated and the Simulator shut down.

`menu-entry.png` and `simulator-unavailable.png` show the exercised states. The
screenshots contain the user's privately executed retail game output only as
visual test evidence; no game data or executable is included.

This checkpoint does not claim physical sensor direction/feel, calibration
ergonomics, controller handoff during active motion input, or a complete
gyro-only race. Those are hands-on physical-device gates.
