# G14 private extracted-game-data import checkpoint

KartPad's exact SunPad-derived `Game Data & Saves` submenu now connects two
previously placeholder actions to a real private import boundary. `Import or
Reimport Game Data` opens the system Files folder picker. `Import from SunPad
Folder` looks only inside KartPad's Files-visible Documents directory and
offers extracted candidates there.

The importer accepts a selected folder itself or a nested `DATA`/`GameData`
folder. Before any installed data is replaced, it requires the extracted disc
surface (`files/`, `sys/fst.bin`, and the runtime-critical files), validates
the `RMCP01` PAL revision-0 boot header and Wii magic, and matches
`sys/main.dol` against the supported profile. It copies into a unique staging
directory under private Application Support, updates the relative
`dvd_root = "GameData"` setting, and swaps the validated copy into place with
rollback of the previous directory on failure. Private data receives iOS file
protection and is excluded from iCloud backup. Stale incomplete staging
directories are removed before a new import.

Verification:

- Complete 29,065-function iOS Simulator app build and fail-closed audit: pass.
- Exact SunPad twelve-file snapshot at
  `e43f0ea6b797e5110787171957c9dc3c6213269c`: pass.
- Rebuilt executable SHA-256:
  `9a6cd90f15a4174369445a65875aa27627efa717e94a28bff37f1845104e3019`.
- Exactly one iPhone 17 Pro / iOS 26.5 Simulator was booted. The real system
  folder picker opened and cancelled back to live gameplay.
- The SunPad-folder path produced the expected bounded no-candidate alert for
  an empty Documents directory and returned to gameplay after cancellation.
- A 2.5 GiB APFS-cloned extracted fixture was then presented through that same
  path. The first attempt correctly failed closed when the streaming hash path
  could not read the mapped file. The repaired mapped-data hash validated the
  supported `sys/main.dol` at
  `80d18895b39c63bd80f457398bfcbb91b7d16ac116a41a88967e954080155b05`.
- The final candidate completed the full copy/staging/swap, left zero import or
  rollback directory behind, normalized `Config.toml` to exactly one relative
  `dvd_root = "GameData"`, and cold-launched from the imported copy.
- The simulator save remained byte-identical at SHA-256
  `87473fa67e0ec2345d471584979217f6dbd7316ed47db054ce565269ef316d58`.
- During the rejected first attempt, the six-worker Simulator-only Metal
  compiler path crashed inside `MTLCompilerScheduler::assignQosToRequest`.
  KartPad now reproducibly limits only iOS Simulator pipeline compilation to
  one worker; physical-device and macOS worker policy is unchanged. The final
  transcript reports one priority and one background worker. A later supplied
  crash report was classified as the same pre-fix six-worker incident; its
  binary UUID and timestamps predate the current patch and candidate. See
  `metal-compiler-crash-classification.md`.
- The app was terminated and the Simulator shut down; none remains booted.
- A Simulator-only launch environment forced failure after the installed tree
  had moved aside but before the staged tree could replace it. The importer
  reported `Injected Simulator swap failure.`, restored the original
  `GameData`, retained the exact DOL and save hashes above, and left zero
  staging or rollback directories. A normal cold relaunch then returned to
  live gameplay. The hook is compiled out for physical iOS builds.
- A no-data launch now stops before Aurora, Metal, or DVD initialization and
  presents a native `Game Data Required` flow. Its real Files folder picker,
  bounded empty-KartPad-folder alert, and full 2.5 GiB import were exercised.
  After the successful swap, the early gate reloads the runtime configuration
  and continues directly into the exact SunPad gameplay surface in that same
  process; no relaunch is required.
- A separate interrupted-launch recovery removed the active directory while
  leaving exactly one `GameData.rollback-*` tree. The next ordinary launch
  restored it automatically, preserved the supported DOL and save hashes,
  removed the orphan, and reached live gameplay.
- The final hardening test left a deliberately invalid active directory beside
  a valid rollback. Onboarding appeared and retained the rollback. After the
  invalid active directory was moved aside, the next launch restored the valid
  tree, removed all import/rollback directories, preserved the DOL and save
  hashes, and logged the exact SunPad runtime overlay installation.
- The entire serialized 29,065-function graph was then prepared from the
  immutable source pins and rebuilt cleanly through all 852 Ninja targets. Its
  arm64 Simulator executable SHA-256 is
  `07c4da68ae6d08d0cb0045bbf84f641d65e708285517271490687861d79b7afd`.
- `Remove Stored Game Data` now schedules deletion instead of removing files
  underneath the running guest. The native follow-up explains that removal
  occurs before emulation on the next launch and provides `Undo`. Undo removed
  only the marker and retained the complete active tree.
- The exercised destructive path retained the active tree until normal app
  termination. On relaunch, the early gate removed the complete 2.5 GiB copy,
  all import/rollback directories, and the marker before emulator startup,
  then returned to `Game Data Required`. The save remained byte-identical at
  SHA-256 `87473fa67e0ec2345d471584979217f6dbd7316ed47db054ce565269ef316d58`.
- A disposable clean iPhone Simulator held all destructive-test data. The
  first attempted CoreSimulator clone was rejected before app launch because
  its cloned registry retained source-device absolute paths. The genuinely new
  device was terminated, shut down, and deleted after the test; none remains
  booted and the preserved iPhone container was never modified.

`folder-picker.jpg`, `no-sunpad-folder-alert.jpg`, `full-import-success.jpg`,
`rollback-injected-failure.jpg`, `first-launch-required.jpg`, and
`first-launch-runtime.jpg`, `removal-scheduled.png`, and `removal-applied.png`
are the exercised UI states. Direct WBFS extraction remains open. No private
game data is included in this evidence.
