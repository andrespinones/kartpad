# G13 native macOS controller-settings entry

Status: **Pass for native entry into the existing controller-mapping UI; G13
remains in progress.**

The KartPad application menu now includes `Controller Settings…`. It raises
the retail window and posts the same F10 event consumed by the existing
in-game settings overlay; it does not create a second mapping implementation.
The exact candidate opened the real top bar with its `Controller settings`
menu over live retail rendering, toggled it closed through the same native
entry, and continued gameplay. Native Quit then exited without a fatal report.

Exact candidate:

- source: `ac892252977d07bfdd043672de160ef003d34aed`;
- unsigned runtime SHA-256:
  `9d8521428c680be154bdcf32c1fb5ad5447257861ce787fb98fd4c53ef53b81c`;
- signed executable SHA-256:
  `803f5cc313c53053ce73b36bf76fae854b4f2cbab6ee984110bcad9fd85bc583`;
- build-fingerprint SHA-256:
  `ca985f97601949ac1aa92800c9dbdcac999b3474f541a7ed58d83006d140dbf4`;
- bundle-content hash:
  `1c645a4a7d633cfc710bed23732eee018079edf937b4e5c7662bfef63bd1cd64`.

The Objective-C++ source passes strict warnings-as-errors compilation, the
complete translated runtime relinks, and the signed package passes the
strengthened shell-contract audit. No Simulator was booted.

Remaining G13 shell work includes richer privacy-safe runtime breadcrumbs,
update-in-place, direct WBFS extraction/translation, and a fresh clean-clone
self-build/package exercise.
