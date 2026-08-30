# G14 opaque mobile letterbox regression

The supplied iPhone 17 Pro Simulator capture showed title pixels, a checker
corner, and the FPS overlay leaking through the presentation bands outside the
game's fitted 16:9 viewport. Aurora cleared the intermediate presentation
snapshot without an explicit alpha value. On SDL/UIKit's Metal surface, those
transparent pixels did not provide a reliable opaque boundary.

KartPad now builds iOS against a disposable copy of the pinned Aurora checkout
and applies `patches/aurora-ios-opaque-letterbox.patch`. The reference checkout
is unchanged. The patch clears the complete presentation snapshot to opaque
black before drawing the fitted game viewport.

Verification:

- Full translated iOS Simulator app audit: pass.
- Exact SunPad twelve-file snapshot at `e43f0ea6b797e5110787171957c9dc3c6213269c`: pass.
- Rebuilt executable SHA-256: `4f7cc915762e90d70db1e11d35fd9255877f7e15e56b9510ab0878653d16204c`.
- Sole iPhone 17 Pro / iOS 26.5 Simulator: title intro and live game frames are
  bounded by uniform opaque-black side bands; no stale title pixels or checker
  corner are visible.
- The exact SunPad-style menu still exposes KartPad's `Multiplayer…` action.
  Its sheet reports stable Player 1–4 controller assignment, touch availability
  for Player 1, one connected Simulator gamepad, and `Controller Setup…`.
- The app was terminated and the Simulator shut down after capture.

`comparison.png` combines the supplied before capture and the rebuilt title
intro at the same simulated iPhone class. `after-title.jpg` and
`multiplayer.jpg` retain the individual after states. The game-data image and
raw logs are not included.
