# G13 enriched privacy-safe macOS diagnostics

Status: **Pass for bounded technical-context export; G13 remains in
progress.**

The native diagnostics report now identifies the exact source/runtime,
product profile, renderer, guest-memory and scheduler strategies, display and
interpolation settings, bounded audio/network/controller state, validated game
data, and yes/no storage health. It includes an explicit review warning while
continuing to omit paths, game data, translated code, save contents, runtime
log text, credentials, device identifiers, and signing material.

The exact candidate exported a schema-2 report through the real save panel:

- source: `c6f94b7b075b652ca558beb0409a68fa28dbbd35`;
- unsigned runtime SHA-256:
  `d549513dd1330a74a8b8be1f3f95e6849ca2fe0b1fc517ae177b034f6e8f1180`;
- signed executable SHA-256:
  `c4102c2181c58de376419b3b784c8568b87a4f71d7b228f63cdb3dd462573504`;
- build-fingerprint SHA-256:
  `d79606a9b7e35f16083ac24be3c66212bb06770000c2f0d8f7f4523f56a67929`;
- bundle-content hash:
  `2e3ba98e58cce0dc7a68d591d1dd5e423ccf9da6b836293a7a40228f56c11b8a`;
- private exported report SHA-256:
  `b45a0a8b285b9adf1688f13f7229dd3d418b1e7ba88ff93a4d14433573a1f495`.

The 890-byte report contains no absolute user/private path or key-like value.
The shell now resolves Application Support and cache locations through the
runtime's installed/portable path policy instead of duplicating path logic.
Strict warnings-as-errors compilation, full runtime relink, package audit,
exact-candidate export, and safe menu Quit pass. No Simulator was booted.

This is richer bounded context, not the complete PRD observability system.
Capped/redacted current/previous session tails, clean/unclean session markers,
and additional live renderer/audio/input/save/network lifecycle breadcrumbs
remain future work.
