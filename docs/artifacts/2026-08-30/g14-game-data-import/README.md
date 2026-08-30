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
  `87636292fd6ea11b5bb7560d05d30f19858dbf3a22006daebd2c67deefb25efb`.
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
  transcript reports one priority and one background worker.
- The app was terminated and the Simulator shut down; none remains booted.
- A Simulator-only launch environment forced failure after the installed tree
  had moved aside but before the staged tree could replace it. The importer
  reported `Injected Simulator swap failure.`, restored the original
  `GameData`, retained the exact DOL and save hashes above, and left zero
  staging or rollback directories. A normal cold relaunch then returned to
  live gameplay. The hook is compiled out for physical iOS builds.

`folder-picker.jpg`, `no-sunpad-folder-alert.jpg`, `full-import-success.jpg`,
and `rollback-injected-failure.jpg` are the exercised UI states. Direct WBFS
extraction, first-launch-with-no-data, and safe removal of active data remain
open. No private game data is included in this evidence.
