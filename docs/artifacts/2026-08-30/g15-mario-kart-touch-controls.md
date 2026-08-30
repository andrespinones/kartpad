# Mario Kart touch-control adaptation

This checkpoint adapts the exact SunPad control surface to Mario Kart Wii
without modifying the pinned upstream snapshot.

## Product behavior

- Classic R has the same compact pill bounds and corner treatment as L.
- Any nonzero R pressure publishes a digital full press; touch-up publishes
  zero. Sunshine's analog pressure-fill artwork is hidden.
- A continues to publish acceleration from touch-down through touch-up using
  SunPad's unchanged mixer.
- After one uninterrupted second, A turns cyan, adds light haptic feedback,
  and exposes `Acceleration held` to accessibility.
- Touch-up, touch cancellation, app backgrounding, and overlay teardown all
  invalidate the delayed callback and restore A's normal appearance.

## Verification

- Exact SunPad twelve-file snapshot:
  `e43f0ea6b797e5110787171957c9dc3c6213269c` — pass.
- `kartpad_mobile_classic_input_tests` — pass.
- Full arm64 IOSSIMULATOR application compile/link — pass.
- Full-game package audit with required touch contracts — pass.
- Simulator executable SHA-256:
  `653943e6cfd1e965c70f743ede11fe464dadf3c752afdbe2ec7b3454ad9f631e`.
- Sole iPhone 17 Pro Simulator: compact R geometry, one-second cyan A state,
  `Acceleration held` accessibility state, and release reset — pass.
- Shutdown: zero KartPad processes, zero Simulator processes, and zero booted
  devices after the iPhone check.

The Simulator-only visual hook calls only the subclass appearance callbacks;
it does not call SunPad's input publisher and is compiled out of physical-iOS
builds. Physical-device touch feel and haptic acceptance are not claimed.
