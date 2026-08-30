# G13 macOS static package audit

Date: 2026-08-29

Classification: **Pass for the build/link/package audit subcase.** Launch, relocated-storage mutation, and gameplay verification of this exact package remain open and are not claimed here.

## Candidate identity

- Source commit: `17cee52d92b70b73e8216a8469dfba668cf4022d`
- Generated runtime SHA-256 before packaging: `4c12eadfd5edf0dd106b76692bef82d8162026684969c7b498a0d3a830f4a0a5`
- Runtime SHA-256 after the package-time `@rpath` load-command update and before signing: `544e47f42718db5894127cef7712374d2fd871a6cac55645a87a0b6ec6af2303`
- Signed packaged executable SHA-256: `05f868bc6826ee009356abc236e9ce507a123e687d86ced0fb33665ab1a11d36`
- App icon SHA-256: `2c83d844e0fe895cae99bc4ed8ea976a969b3035833373c39af31247b17ea7b8`
- Bundle-content audit hash: `8a8ff8b38aa699070f3e6ad20a251a4adafb0a3d5cdb7df71aed90bacecbd602`
- Bundle identifier: `dev.kartpad.app`
- App version/build: `0.1.0` / `1`
- Package size: 80 MiB

## Commands

```text
cmake -S build/g7-game-runtime-source -B build/g7-game-runtime-build -G Ninja \
  -DMKW_TRANSLATED_SHARD_MANIFEST=<private>/g8-full-translation/build_shards/shards.cmake \
  -DMKW_TRANSLATED_COMPILE_JOBS=2
cmake --build build/g7-game-runtime-build --target WiiCompiled --parallel 8
scripts/package-macos-runtime.sh <runtime-build> <KartPad.app>
scripts/audit-macos-package.sh <KartPad.app>
```

The first static-link attempt was rejected because configuration incorrectly retained the older G6 translation manifest and failed on missing `func_8055531C`. The function exists in the authoritative 29,637-function G8 full-title graph. Changing only the manifest to the full graph produced a successful link; no stub or semantic bypass was added. The preparation script now defaults to that full graph.

## Observed audit results

- Mach-O architecture: arm64.
- `LC_BUILD_VERSION`: platform macOS, minimum 14.0, SDK 26.5.
- Dynamic dependencies: Apple system frameworks plus `/usr/lib` only; no Homebrew, SDL, libpng, FreeType, Abseil, or other developer-machine dylib remains.
- First-party compile paths are redacted; the executable contains no path under the builder's home directory.
- The app contains the DSP coefficient ROM, transferable initial pipeline cache, Wii first-run bootstrap, and original ICNS.
- The app contains no `portable.txt`, `UserData`, `Config.toml`, WBFS, ISO, RVZ, WIA, or GCZ.
- `codesign --verify --deep --strict` passes for the ad-hoc signed bundle.
- `plutil -lint` passes; package and executable both declare macOS 14.0.
- Repository safety audit and patch dry-run against the pinned WiiCompiled source pass.

The app bundle is an ignored local artifact and is not published to Git. It will not be launched while the single long-session gameplay process is active.
