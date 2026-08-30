# G13 native macOS data and diagnostics menu

Status: **Pass for the native data/cache actions and bounded diagnostics
export; G13 remains in progress.**

## Candidate identity

- Source commit: `5781b9950013f405e61018ecd4893401fd7f08a1`
- Package: `build/KartPad-packaged-5781b99.app` (ignored generated product)
- Unsigned runtime SHA-256:
  `929a0f5ac7101583624f1f3b44ccea3b9c7aaeb874c425016de793ceff7484ae`
- Signed executable SHA-256:
  `a4620de0ae056ebcda44fc143f5d286288fe08e654f5e6ce04a0a6ad8b9b6a9c`
- Build-fingerprint SHA-256:
  `0e97adb93346b44f55c1cc77ac05d044dbb2073a0bf7e642ddb074f86d78b1ae`
- Bundle-content hash:
  `dd7679fecdf4baaa89b59461d50fec7e24c57ab50b76e00bc83e2f24a7c87ba0`

## Exercise

The Objective-C++ shell compiled with `-Wall -Wextra -Wpedantic -Werror`.
The complete 29,065-function runtime relinked, the pinned-source patch chain
reproduced cleanly, and the strengthened package auditor passed 20 consecutive
runs.

The exact post-commit package was then exercised through macOS accessibility:

- the KartPad application menu presents `Show KartPad Data`, `Show KartPad
  Cache`, and `Save Diagnostics Report…` in normal application-menu order
  before Hide and Quit;
- `Show KartPad Data` opened Finder at KartPad's Application Support folder;
- `Save Diagnostics Report…` opened a native `Save KartPad Diagnostics` panel;
- saving through that panel produced the exact-candidate private report at
  SHA-256
  `4b9a7b860782aa0598701cefa95dd5a04df15f582f90b6b08dc6c50a92575ba9`;
- the report contains schema, generation time, version/build, OS,
  architecture, and only yes/no existence fields for Application Support,
  cache, configuration, and save state;
- it explicitly states that paths, game data, save contents, credentials, and
  logs are omitted.

The report itself stays under ignored `private/` because even bounded local
diagnostics are runtime evidence rather than distributable source. KartPad
closed normally after the export. No Simulator was booted during this macOS
exercise.

## Remaining G13 boundary

This checkpoint does not claim the complete native application goal. Native
display/audio settings subsequently pass in `g13-macos-settings/`. Native
first-run WBFS/extracted-data setup, controller-mapping entry from the native
shell, richer privacy-safe runtime breadcrumbs, update-in-place, and the
clean-clone self-build/package exercise remain open.
