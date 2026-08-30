# G13 native macOS first-run game-data checkpoint

Status: **Pass for validated extracted-data selection and same-process startup;
G13 remains in progress.**

## Exact candidate

- Source: `a5ee9fecc64ba14cdd5f1beb8609be955c435bd4`
- Generated package: `build/KartPad-packaged-a5ee9fe.app` (ignored)
- Unsigned runtime SHA-256:
  `345113c0a1b7524bd9838f8dc399800360742f314ef89dc98af83e42b5ecf777`
- Signed executable SHA-256:
  `67723c7341efce1fa6a999f21ce25cd6e1128a62d6a2f9e4950ee71c9fc42a6f`
- Build-fingerprint SHA-256:
  `a371e4246349c1e0018ec8b791acc882962a43c61e17ec169cfacde7ebf37ef0`
- Bundle-content hash:
  `1874ae00de3f3ba66a675849875ca769e6edb5fd4edd8966bdcafa3dd96d4aca`

## Exercise

With no configured game data, the native AppKit gate appeared before Aurora
or translated-game initialization. Its system folder picker accepted the
user-owned extracted root only after checking the required `files/` and `sys/`
surface, `RMCP01` PAL disc/revision header, Wii disc magic, and supported
`main.dol` profile. It wrote `paths.dvd_root`, reloaded the cached runtime
configuration, and reached the retail game in the same process at normal
frame cadence with non-silent host audio.

The in-game application menu exposes About, Settings, Services, Show Data,
Show Cache, Choose Game Data, Save Diagnostics, Hide, and Quit. A deliberately
unsupported folder produced the bounded `Unsupported Game Data` alert and
left `Config.toml` byte-identical at SHA-256
`ef058e8898a4b827d41330a7fb20d018446fa39ae218d5dee37a6e6382d68573`.
The empty first-run Quit route exited before runtime initialization. The first
menu-Quit implementation exposed a real translated-render-worker teardown
failure; the accepted route now closes the Aurora window so its established
successful-exit path flushes placement state and exits without C++ guest-fiber
teardown. Both the configured pre-commit candidate and exact post-commit
package exited without a fatal report.

The Objective-C++ shell passes strict warnings-as-errors syntax compilation.
The pinned-source patch chain reproduces the prepared runtime exactly, the
complete 29,065-function runtime relinks, and the strengthened signed-package
audit passes. No Simulator was booted during this macOS exercise.

## Remaining boundary

This flow intentionally accepts an already extracted supported game folder.
It does not yet extract or translate a WBFS inside the app; that remains in the
documented Mac self-build workflow. Native controller-mapping entry, richer
privacy-safe runtime breadcrumbs, update-in-place, and a fresh clean-clone
self-build/package exercise also remain open for G13.
