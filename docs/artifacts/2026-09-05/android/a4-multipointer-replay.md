# Android A4 multi-pointer replay

## Scope

This checkpoint closes the automated two-finger ownership replay required by
the A4 emulator gate. It does not claim physical touch ergonomics, digitizer
behavior, or a complete touch-only race.

## Fixture

The source-only activity can now opt into a production-gated replay that builds
real Android `MotionEvent` objects and sends them through
`KartPadOverlayView.onTouchEvent`. The replay uses two stable pointer IDs at the
actual laid-out centers of A and B:

1. pointer 0 presses A;
2. pointer 1 presses B while A remains held;
3. pointer 0 releases A while pointer 1 continues holding B;
4. pointer 1 releases B.

After each event, the fixture checks the exact Classic button mask published to
the normal native touch bridge. It also requires the pointer-owner table to be
empty at completion and clears all state. The delayed A-lock generation is
invalidated before it can fire. The fixture invocation requires both a debug
build and `GAME_RUNTIME=false`; private production runtime startup cannot
activate it.

`scripts/test-android-touch-multipointer.sh` builds and installs the source-only
APK, enforces the one-device rule and lane-native landscape rotation, launches
the replay, and accepts only this marker:

```text
A4 multi-pointer fixture passed a=0x10 both=0x50 b=0x40 neutral=0x0
```

## Results

The same wrapper passed on visibly running wiped API 36 ARM64 Pixel 6 and Pixel
Tablet emulators. This proves that lifting one pointer does not clear the other,
that A and B combine without aliasing, and that the final release is neutral on
both canonical geometries.

The complete translated dual-runtime APK then rebuilt and passed the strict
package/privacy audit at SHA-256
`726cf06af9208fdcb3fe91b80a89046daf32adbf8b288d54a36d753f81a890ba`.
Android lint, the 75-test suite with one intentional skip, repository safety,
shell syntax, Python compilation, and whitespace checks pass.

## Classification

Pass for automated two-pointer ownership and published-mask transitions on the
canonical emulator phone/tablet lanes. Multi-control physical touch, A-lock
feel, haptic feel, and touch-only racing remain physical acceptance gates. No
APK/AAB, private data, raw log, UI dump, or screenshot was published.
