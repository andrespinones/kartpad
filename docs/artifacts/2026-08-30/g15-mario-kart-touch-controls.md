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
  `7c3c6a4ddda8a2d89d42e4a867dfc6c1e43aadd4635c28a2870e302e525956be`.
- Sole iPhone 17 Pro Simulator: compact R geometry, one-second cyan A state,
  `Acceleration held` accessibility state, and release reset — pass.
- After iPhone shutdown, sole iPad Pro 13-inch Simulator with the same binary:
  matching compact L/R pills in landscape, one-second cyan A state,
  `Acceleration held` accessibility state, release reset, and uninterrupted
  retail rendering — pass.
- Shutdown: each device was terminated and shut down before the next launch;
  the final state has zero KartPad processes, zero Simulator processes, and
  zero booted devices.

## Gameplay-input proof

The visual state is supplemented by a Simulator-only end-to-end probe that
dispatches the real A button's existing SunPad touch-down and touch-up targets,
then observes the shared mixer through KartPad's Classic adapter:

```text
[KartPad] touch A hold self-test: held pass (classic=00000010)
[KartPad] touch A release self-test: release pass (classic=00000000)
```

The probe held A for 1.1 seconds before the first observation. The running
iPhone app also exposed `Acceleration releases when your finger lifts. Input
self-test passed.` through accessibility after release. This proves the game
input remains asserted across the delayed color change and clears on lift.

The visual-only hook still calls only the subclass appearance callbacks. The
separate input probe is opt-in, publishes the bounded test input deliberately,
and is compiled out of physical-iOS builds. Physical-device touch feel and
haptic acceptance are not claimed.
