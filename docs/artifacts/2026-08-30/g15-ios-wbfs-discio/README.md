# iOS WBFS / DiscIO feasibility boundary

Date: 2026-08-30  
Goal: G15 mobile game-data flow  
Classification: **Pass for clean pinned DiscIO compilation and real Simulator WBFS read/system export. App import integration remains open.**

## Input and source

- User-owned read-only input: ignored `ref/Mario Kart Wii.wbfs`
- Input profile: WBFS, `RMCP01`, disc 0, revision 0
- Pinned Dolphin commit: `4f8af23db516d8b6e9cd00e7b261a65b026514a8`
- Source patch: `patches/dolphin-ios-discio.patch`
- Nested curl patch: `patches/dolphin-curl-ios-pipe2.patch`
- Probe source: `tests/ios_discio_probe.cpp`
- Target: arm64 `IOSSIMULATOR`, iOS 16.0 minimum

No disc bytes or extracted private content are stored in this artifact.

## Result

The first feasibility oracle and the clean pinned rebuild produced the same runtime result on an iPhone 17 Pro Simulator:

```text
game=RMCP01 revision=0 children=2095
system export passed
main.dol.sha256=80d18895b39c63bd80f457398bfcbb91b7d16ac116a41a88967e954080155b05
```

The clean pinned executable SHA-256 was:

```text
acac0a73fa04085fe9d9f8eac80ab13183d7d25999f1489511173b96e6e10984
```

Exactly one Simulator was booted during the accepted run (`booted_count_during_test=1`). It was shut down by a shell trap, and the Simulator removed the temporary APFS-cloned 2.6 GB input plus exported system files during shutdown. A post-run check reported zero booted devices and confirmed the staging path no longer existed.

## What this proves

- The supplied WBFS can be opened directly by pinned Dolphin DiscIO on arm64 iOS Simulator.
- The embedded disc identity, revision, filesystem, and 2,095-entry tree are readable.
- Disc system-data export works and reproduces KartPad's accepted `main.dol` hash.
- The required upstream portability changes are serialized and the immutable reference checkout is clean again.

It does not yet prove full `files/` extraction inside the KartPad app, an atomic WBFS-to-active-data transition, physical-device extraction, progress/cancellation, or enough free space on a specific device.
