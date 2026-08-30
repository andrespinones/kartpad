# G13 macOS update-in-place checkpoint

Status: **Pass for app-bundle replacement with external state preservation;
G13 remains in progress.**

An isolated installed-style home began with signed package source `a5ee9fe`
and its user state under `Library/Application Support/KartPad`, with cache state
separated under `Library/Caches/KartPad`. The older package loaded the exact
configured extracted-data root, reached the retail title, produced non-silent
host audio, and exited normally.

The test then moved the old app bundle aside as a recoverable rollback and
copied the exact `c6f94b7` signed package into the same install path. It did not
copy, migrate, rewrite, or delete the isolated Application Support tree. The
updated package loaded that existing configuration, initialized the supported
game data, reached retail rendering with audio, exposed the new Controller
Settings and schema-2 diagnostics menu entries, and exited normally.

Before the old launch, after the old launch, immediately after replacement,
and after the new launch:

- `Config.toml` remained byte-identical at SHA-256
  `ef058e8898a4b827d41330a7fb20d018446fa39ae218d5dee37a6e6382d68573`;
- `rksys.dat` remained byte-identical at SHA-256
  `708c7a040e0cfe6cd815690e63f46d1678f17899bce0e786f7480030830f1d13`.

The old and new build-fingerprint hashes were respectively
`a371e4246349c1e0018ec8b791acc882962a43c61e17ec169cfacde7ebf37ef0`
and `d79606a9b7e35f16083ac24be3c66212bb06770000c2f0d8f7f4523f56a67929`,
proving that the exercised executable bundle changed while user state did
not. No Simulator was booted.

This proves the local app-bundle update boundary. It does not claim a signed
Sparkle feed, notarized installer, downgrade migrations, or public updater
service.
