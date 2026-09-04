# Android A3 Retro replay isolation

Date: 2026-09-04

## Scope

This is a bounded API 36 ARM64 emulator diagnostic for the first Retro Rewind
race gate. It distinguishes translated Retro Rewind race execution from the
existing player-side RKG input fixture. It is not physical-device or complete
A3 gameplay acceptance.

## Preconditions

- The previously validated Retro Rewind 6.12.5 installation and game disc were
  retained in app-private storage.
- Networking remained disabled.
- The app explicitly selected the `retro_rewind` runtime and did not fall back
  to Original Mario Kart Wii.
- The official `Ghosts/ExpertsRT/0_150.rkg` card identified SNES Donut Plains
  1, Mario, Sneakster, Manual, and `01:34.086`.
- State trace output contained numeric guest state only. No RKG, disc, pack,
  save, APK, or local path was copied into this artifact.

## Metadata-override isolation

A temporary debug-only launch switch disabled
`KARTPAD_RKG_FORCE_METADATA_V2`. The official input was then supplied to the
player fixture after manually selecting the matching course, character,
vehicle, and drift mode. Outside transmission was selected because the RKG's
Retro Rewind extension is `TRANSMISSION_DEFAULT`, which the two-choice player
screen does not expose.

The fixture armed at the normal countdown boundary and maintained the expected
238-frame stream/race offset. At visible race time `00:19.380`, however, the
player was still on lap 1 and had diverged into the same barrier/off-road state
seen with metadata forcing enabled. Disabling the base-course metadata writes
therefore did not fix the failure. The temporary launch switch was removed
from source after this falsification.

## Native replay control

The diagnostic RKG file was renamed out of the recognized path and the process
was cold-started. Retro Rewind's own Replay path loaded the same official card,
followed the course, visibly crossed into lap 2, and reached the three-lap
finish/results presentation without an Android fatal record. The bounded trace
progressed through stages 0, 1, 2, and 4. The result presentation showed
`00:57.691`; because this does not equal the card's `01:34.086`, this run does
not claim replay timing fidelity.

The KartPad save changed from the prior cold-relaunch hash
`9c451f517267b800a7100bcf3f7445917ddca2361dc7deb1d184f76086600604`
to `c5496e08dceab593a787b1363b2a4ce756313cebd768ab2d0d814c99db931383`
after the result presentation. After removing all diagnostic files, installing
the clean rebuilt APK, and force-stop/cold-launching the explicit Retro profile
at the emulator's native display size, the branded title returned and that
changed hash remained exact.

## Classification

**Partial pass.** The Android Retro Rewind runtime can execute the expanded
course and its native replay through a three-lap finish/results path, so the
earlier failure is not caused by the metadata override or a general inability
to run Retro Rewind race physics. The player-side diagnostic RKG bridge still
diverges and cannot be used as A3 race acceptance. Its most likely remaining
boundary is Retro Rewind's transmission/RKG-to-live-controller semantics, but
that cause is not yet proven. A controller-driven race, trustworthy timing,
save/relaunch verification for that controller-driven race, mode switching,
and physical-device execution remain open.
