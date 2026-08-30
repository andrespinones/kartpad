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
  `c676a066fd9fe28f8a64ea43ee0286c9989a4e3fcf60bb982c3980d09f70b9b7`.
- Exactly one iPhone 17 Pro / iOS 26.5 Simulator was booted. The real system
  folder picker opened and cancelled back to live gameplay.
- The SunPad-folder path produced the expected bounded no-candidate alert for
  an empty Documents directory and returned to gameplay after cancellation.
- The app was terminated and the Simulator shut down; none remains booted.

`folder-picker.jpg` and `no-sunpad-folder-alert.jpg` are the exercised UI
states. A successful 2.5 GiB data copy was deliberately not run in this
checkpoint, so copy completion, rollback under injected failure, direct WBFS
extraction, first-launch-with-no-data, and removal of active data remain open.
No private game data is included in this evidence.
