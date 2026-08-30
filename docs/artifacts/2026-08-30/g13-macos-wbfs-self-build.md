# G13 WBFS-to-macOS self-build checkpoint

Status: **Pass for the supported read-only WBFS through fresh extraction,
translation, runtime build, signed package audit, launch, input, audio, and
clean quit; G13 remains in progress.**

The repository now exposes a public, fail-closed local workflow:

```sh
./scripts/self-build-macos.sh /path/to/your/Mario-Kart-Wii.wbfs
```

Its explicit stages are `prepare-disc.sh`, `translate-base.sh`,
`build-macos-app.sh`, and the existing package/audit scripts. Private extracted
data and generated translation stay under ignored `private/`; build products
stay under ignored `build/`. The runtime preparation temporarily points the
upstream generated-data alias at the selected graph and restores the prior
alias on every exit.

## Exercised input and extraction

The default path read the original read-only user WBFS without modifying it.
It required the complete image SHA-256
`fc035e60610842da6860d23d4a30c1f1c0f019d492469deb8a2ac25ef5822331`
and pinned `nodtool 2.0.0-alpha.9`. The fresh extraction then validated:

- `RMCP01`, disc 0, revision 0 and Wii magic `0x5d1c9ea3`;
- `main.dol` SHA-256
  `80d18895b39c63bd80f457398bfcbb91b7d16ac116a41a88967e954080155b05`;
- `StaticR.rel` SHA-256
  `16d9d146112541fefea701ecb5bc1a496f9d50e4a752fbb5b6778e7c6399f67d`.

The content-private extraction manifest has SHA-256
`4e8a06a25a8667d308e91bdede34383fcbb744ff0e2a2492c37c847fc19d4002`.
Because this exact WBFS triggers nodtool's known first-block H0 rejection, the
workflow does not claim its optional H0 validation. It instead fails closed on
the already pinned full-image hash and the independently pinned extracted
executable identities.

## Fresh translation and build

The pinned patched translator built with zero warnings/errors, used two
bounded workers, discovered/emitted 29,637 functions, applied the two tracked
generated-source guards, generated 7,701,072 bytes of embedded DOL/REL data,
and emitted 72 balanced base shards for 29,065 shared base functions. The
fresh function-tree hash is
`ded6953573bf8d2086ed02c45f9619d21772903b4a2ab6b26c5f77c4b3f738e6`;
the fresh shard-source hash is
`79a984c8808e50927f5963106146619808c64a6c4b1f9c4495ac43f493ba9a9c`.
Both are byte-identical to the earlier known-good independently generated
graph. The base-common shard map has SHA-256
`fb3590e6d870de65f60b939d1cbf7368abf69709d6a0f1c38c2031a60f8f676c`.

A new macOS source/object graph configured all 29,065 shared functions and
completed all 857 build steps. The unmodified linked runtime before packaging
has SHA-256
`2c2777b7b82ca872f91e64e423ccff0be6b5bf3877ff4d40f0cc0b192e7f3ddd`.
The package/audit step passed with no private data, writable state, forbidden
image, non-system dynamic dependency, builder-home string, or invalid signing
boundary.

Exact committed workflow/package identity:

- source: `d6e320295aa29303325908e9bd1f5cc9e756a15c`;
- unsigned packaged runtime SHA-256:
  `b3cabaaddb70079459fee42980098d47edba582dda0ab1de50b9081b0760419a`;
- signed executable SHA-256:
  `7982af482b0f4fa0fe522606de1d0493a3dc88a13384ef37d9d542f03de33a99`;
- build-fingerprint SHA-256:
  `0b767fd3cdf44ff183dfe15b6adb2814f5b34afb7d3d8084a8a80e34baa3ec68`;
- audited bundle-content SHA-256:
  `bc53f9e82e2e7656d86170e59426b9ab79b4553366946b684824739fd9f0fc92`.

## Runtime exercise and boundary

The freshly built app loaded the fresh extraction, initialized all embedded
DOL/REL data and constructors, Metal, and non-silent 32 kHz stereo audio. It
reached the retail title/attract presentation at 60 FPS. The mapped A input was
observed in the retail KPAD report and changed scenes. Native Quit exited the
sole game process with status 0, wrote `endedCleanly=yes`, and removed the
active marker. The post-commit exact-fingerprint package independently reached
the retail title at 60 FPS with non-silent audio and also quit cleanly. No
Simulator was booted.

This proves the currently pinned checkout's real WBFS-to-app workflow and
PRD row 61's core private-input path. It is not yet a fresh network Git clone:
the ignored pinned reference checkouts and dependency archives were already
present. The native first-run app still accepts an extracted folder while the
WBFS translation/build occurs through the Mac command-line workflow. Automated
fresh-clone source provisioning, native progress UI/resume/cache management,
and public notarized update infrastructure remain open.
