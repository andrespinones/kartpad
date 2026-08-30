# G13 exact branded macOS package launch and gameplay

Date: 2026-08-30

Classification: **Pass for exact-package audit, installed storage, configured launch, and live gameplay. G13 remains in progress.** Native first-run image selection, settings, diagnostics, data management, update-in-place, and clean-clone self-build are not claimed.

## Exact candidate

- Source commit: `325d5f3c90c8167b38c1b63d6b95dbcdf44c6eea`
- Bundle: ignored local `KartPad-packaged-325d5f3.app`
- Bundle identifier: `dev.kartpad.app`
- Branded executable: `Contents/MacOS/KartPad`
- Unsigned runtime SHA-256 recorded in the package fingerprint: `b2a66498ca8cfeee4daddf799f39260e5bbf54c01de4af2b163e7e2ffc6be38f`
- Signed executable SHA-256: `4efb40ca526ba31a0ba277c39577182bf0deabdd472ca9e4444aa6296f23caa6`
- Bundle-content audit hash: `12e827fdaf206df3689ab0fe0b73fa7ebe20fe3827b538d8fe7c21e8ac25e3db`
- Package size: 80 MiB

The fail-closed audit proves native arm64, a macOS 14.0 floor, Apple-system-only dynamic dependencies, strict ad-hoc signature validity, original ICNS inclusion, initial pipeline-cache inclusion, and absence of disc images, saves, logs, writable configuration, translated source, builder-home paths, and other prohibited private inputs.

## Installed storage

The installed runtime now separates durable and rebuildable state:

- configuration, NAND, saves, and logs: `~/Library/Application Support/KartPad`
- Dawn and pipeline caches: `~/Library/Caches/KartPad`
- transferable initial cache: read from `Contents/Resources/initial_pipeline_cache.db`

A clean-storage run on the immediately preceding storage-identical candidate seeded 1,199 cache rows from `Contents/Resources`, created a real POSIX NAND hierarchy, and created no backslash-named path component. The final branded candidate independently logged the same Resources seed and installed roots during configured gameplay. The current installed tree contains zero backslash-named paths.

## Exact-candidate playtest

With no Simulator or reference emulator active, the final candidate was launched through the audited single-instance runner. macOS accessibility identified both the process and game window as `KartPad`. The run:

1. reached the retail title screen;
2. loaded the existing `Player` license;
3. reached Main Menu;
4. selected 50cc Grand Prix, Mario, Standard Kart M, Automatic, and Mushroom Cup;
5. reached live Luigi Circuit gameplay at a displayed 60 FPS;
6. accepted live accelerate input; and
7. closed normally through the window close control.

The RKSYS save remained byte-identical at SHA-256 `ad79c24bc5eb0ba6bc8cd2836a55680621892b578a04ea49d8884a71a42c563a`. The bundle-content hash was identical before and after playtesting. The private runtime log SHA-256 is `12a1f7502831f201afed1f9359de18b907c6df0cce5040068eb105cb43c3e8ec`; the private live-race screenshot SHA-256 is `790112079301c971085dfe22d941930771972e1fbc295a5bd8a90d619f9694dc`.

## Remaining G13 work

- native guided WBFS selection/validation and local-generation flow
- settings, controller mapping, audio controls, and display controls
- bounded diagnostics export and data management
- update-in-place preservation test
- clean-clone macOS self-build
- hardened-runtime/notarization research, kept separate from local ad-hoc acceptance
