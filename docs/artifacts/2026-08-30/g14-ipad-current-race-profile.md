# G14 current-core iPad Simulator race profile

Date: 2026-08-30  
Host: Apple-silicon macOS, Xcode iOS 26.5 Simulator runtime  
Device: iPad Pro 13-inch (M5), iOS 26.5 Simulator  
Classification: **Pass for current-core packaging, live FPS preference refresh,
real-time stationary-race cadence, bounded presentation telemetry, CPU sampling,
and clean single-Simulator shutdown. Physical-device performance and touch feel
remain open.**

## Candidate identity

- Source checkpoint: `443fd69` (`Refresh iOS runtime settings without relaunching`)
- Prepared source: ignored `build/g11-ios-effect-443fd69-source`
- Xcode product: ignored
  `build/g11-ios-effect-443fd69-xcode/Release-iphonesimulator/KartPad.app`
- Executable SHA-256:
  `08eafccd48a9e412bf133a55aed221d252bcd14c46c9ac5f4b44596fe2c669d7`
- `Assets.car` SHA-256:
  `d25540efa70a7c9f6ef8d12849a6469ea8e7ff2c5cbe9477c9e7513c640b2434`
- `PrivacyInfo.xcprivacy` SHA-256:
  `343dbc92a22d95a896d5bb894f439d655ac8e15d0fcc7fe72500bd5fcaba1740`
- The strict IOSSIMULATOR full-game audit passed before launch. The build used
  the latest full FPSCR-effect-model translation, not the older mobile graph.

## Live settings regression

The exact SunPad three-dot menu opened over the retail title. `Show FPS Counter`
was initially selected. Selecting it removed the FPS overlay immediately;
opening the menu again showed the item unselected. Selecting it a second time
restored the overlay immediately. Neither transition relaunched the process.

This closes the discovered mismatch in which the native menu persisted the
preference but the emulator sampled it only at startup. The copied SunPad
snapshot remains byte-identical; the runtime refresh lives in KartPad's patch
layer.

## Representative live scene

The touch overlay drove the normal path through the saved license:

`Single Player -> Grand Prix -> 50cc -> Mario -> Standard Kart M -> Automatic
-> Mushroom Cup -> Luigi Circuit`

The resulting scene contained the normal twelve-racer field. Mario remained on
the start straight so the measurement is directly comparable with the earlier
stationary Luigi Circuit sample; it is not a complete touch-driven race.

## Presentation and real-time cadence

The session emitted 103 strict presentation records. Across the retained live
race tail (`total >= 20,700`, 35 records):

- minimum effective FPS: `57.003`
- maximum effective FPS: `60.082`
- maximum p99 frame time: `19.767 ms`
- maximum single-frame time: `70.572 ms`
- final record: `60.004 FPS`, `16.765 ms p99`, `16.869 ms worst`
- pipelines queued: `0`
- pipelines created after warmup: `1,684`

Presentation rate alone can hide repeated guest frames, so two native
screenshots bracketed a ten-second wall-clock interval. The retail race clock
advanced from `01:11.278` to `01:21.893`, or `10.615` guest seconds during the
roughly ten-second command interval (which also includes screenshot overhead).
The stationary live race was therefore advancing at real-time cadence rather
than merely repainting a slow guest at 60 Hz.

## Paired CPU observation

`/usr/bin/sample` captured the app for 20 seconds during the live race. Raw
samples and game screenshots remain under ignored `private/` and are not
published.

| Metric | Older mobile candidate `c87a1c4e` | Current candidate `08eafccd` |
|---|---:|---:|
| Main-thread samples | 15,375 | 14,972 |
| `RuntimeMain` samples | 11,098 | 10,689 |
| `feclearexcept` leaf samples | 4,986 | 3,277 |
| `fetestexcept` leaf samples | 1,146 | 883 |
| Direct fenv leaf total | 6,132 | 4,160 |
| Physical footprint | 710.6 MiB | 700.8 MiB |

The same floating-point exception bookkeeping remains the largest identifiable
CPU leaf cost. The current observation is materially lower, while total
`RuntimeMain` sampling changed much less, but this is one paired scene at a
different race-clock point. It is evidence for a reproduction run, not a
claimed speedup and not permission to weaken guest FPSCR behavior.

## Shutdown and disposition

- KartPad was terminated normally through `simctl`.
- The sole booted Simulator was shut down.
- No macOS game process overlapped the Simulator run.
- No raw trace, game data, save, log, or screenshot is committed.
- G14 Simulator integration is stronger; physical iPad/iPhone touch, audio,
  thermals, memory pressure, sustained performance, and motion acceptance are
  still required before mobile promotion.

## Follow-up: live display settings

Source `049ee94` extended the same KartPad-owned refresh bridge to the two other
SunPad menu groups that do not advertise a restart requirement. The exact
copied menu files remain byte-identical.

The incrementally rebuilt Xcode app passed the strict IOSSIMULATOR audit with
executable SHA-256
`bdb805b933e9cbce3e921dba11063af18fd6b18eaebdb36c447bbae24f71f2d8`.
On a single iPad Pro 13-inch (M5) Simulator process:

- `Original 4:3 -> 16:9 (Experimental)` immediately produced the expected
  opaque-black top and bottom bands while keeping the touch layout fitted.
- `16:9 (Experimental) -> Original 4:3` immediately restored the full 4:3
  presentation.
- `1x (Native) -> 2x -> 1x (Native)` applied in-process without relaunching.
- Bounded runtime records confirmed the exact sequence:
  `aspectMode=0, resolutionScale=1, aspectMode=1, aspectMode=0,
  resolutionScale=2, resolutionScale=1`.

The patch reads the current Metal surface only when the aspect preference
changes and calls the existing framebuffer-scale API only when the resolution
preference changes. It does no per-frame reconfiguration in steady state. The
full patch stack applies from immutable upstream, the exact SunPad snapshot
passes, the app exited normally, and the sole Simulator was shut down.

## Follow-up: inherited experiments are explicit

The exact SunPad menu also contains two restart-required experiments whose
implementations are product-specific: Sunshine's 90% emulated-clock mode and
its GMSE01 60 FPS patch. KartPad's ahead-of-time Mario Kart Wii runtime exposes
neither mechanism. Leaving the inherited actions active would persist settings
that KartPad could not honor.

Source `f9ee662` keeps the exact visible titles and system icons, but the
KartPad-owned menu wrapper replaces only those two handlers. Each now presents
an `Unavailable in KartPad` explanation naming the incompatible feature,
states that stable retail timing remains active, and confirms that no setting
was changed. The copied SunPad snapshot remains byte-identical.

The rebuilt app passed the strict IOSSIMULATOR audit with executable SHA-256
`0459d6948e856547dcbe77f7b1839ff7882a8cf73cb0c3052c5c53ff99e98d90`.
Both actions were exercised over live Mario Kart Wii rendering in one iPad
Simulator process. The expected alerts appeared, neither experimental defaults
key was created, the app was terminated normally, and the sole Simulator was
shut down.
