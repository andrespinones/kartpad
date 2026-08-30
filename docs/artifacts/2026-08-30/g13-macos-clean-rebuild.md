# G13 clean macOS runtime rebuild checkpoint

Status: **Pass for a fresh disposable runtime source/object graph, signed
package audit, and launch/normal-close exercise; G13 remains in progress.**

Starting from the current clean KartPad checkout at source `d54db68`, the
macOS preparation was repeated into new disposable directories:

- source: `build/g13-clean-macos-source`;
- object graph: `build/g13-clean-macos-build`;
- package: `build/KartPad-clean-macos-d54db68.app`.

The preparation copied the immutable pinned WiiCompiled/Aurora input, applied
both tracked KartPad patch files afresh, downloaded the pinned `sse2neon`
input, and verified its SHA-256 as
`44b9fa3d9dd92c4dcce7cdd4f2f76702e4fb14d7a5211da9a5086df180aa3bd9`.
CMake configured a new 857-step graph. That graph compiled all translated
title shards, runtime/HLE, SDL, static dependencies, Aurora, and the native
AppKit shell and linked successfully.

Before packaging, the fresh `WiiCompiled` executable had SHA-256
`7a92787f2297ab1350aa8d2e41487b0bc4e47f32fe9ebbc94b2c90abfb73db7d`.
The packager then applied the intended runtime-path/signing transformations.
The audited package identities are:

- unsigned packaged runtime:
  `12bc002ef09134a81703c3120d80d45e2bc7a624b554cf152fbca74eae13b010`;
- signed executable:
  `02ce2679b1b24c1da55bac2fd767dc423a227255f1efab074f913cfc739adb8c`;
- build fingerprint:
  `38f2129a646716149b3a39f0d3bfbc39219427fc6f9437140a3be3ab5aee88ec`;
- bundle content:
  `840d0dca6027a4841665f9cfeea92b5dc4aa8c414127134cfa429982f07690a4`.

The fail-closed package audit passed. An isolated portable copy loaded the
supported extracted game data, initialized the Metal backend and non-silent
audio, reached the retail Wii presentation at approximately 60 FPS, and
exposed the complete native application menu: About, Settings, Services,
Show Data, Show Cache, Choose Game Data, Controller Settings, Save
Diagnostics, Hide, and Quit. Native Quit closed the sole game process with
exit status 0. Audio telemetry ended with zero empty-before-push observations
and zero dropped blocks. No Simulator was booted.

This is deliberately a bounded reproducibility claim. It proves a clean
runtime source copy, clean object graph, package, and smoke exercise from the
current checkout. It reused the user's ignored, previously generated private
translated title shards and extracted data. It is not a fresh network clone,
does not regenerate translation from the WBFS, and does not establish direct
in-app WBFS extraction/translation.
