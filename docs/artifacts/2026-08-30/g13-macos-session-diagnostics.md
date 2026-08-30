# G13 bounded macOS session diagnostics checkpoint

Status: **Pass for capped current/previous session context, clean/unclean
classification, redaction, exact-package export, and clean relaunch; G13
remains in progress.**

The native shell now creates a small structured session manifest under the
external Application Support `Logs` directory before emulator initialization.
Each launch atomically rotates the prior current log, writes an active marker,
and records the bounded renderer, product, guest-memory, and scheduler
identity. A normal return or native Quit appends an end timestamp and
`endedCleanly=yes`, then removes the active marker. If the process disappears
without that finalization, the next launch records `previousSessionClean=no`.

An isolated regression intentionally killed the sole disposable game process
after its active marker was written. The marker remained, and the next launch
classified the prior session as unclean. The corrected native Quit then exited
0, appended the clean result, and removed the marker. A following launch
reported `previousSessionClean=yes` and also closed normally. No Simulator was
booted.

Diagnostics schema 3 includes at most 4,096 bytes from each current/previous
structured session tail. It replaces known macOS, Linux, and Windows home-path
forms plus the current username, explicitly warns that arbitrary text still
requires review, and continues to exclude private game data, translated code,
save contents, credentials, device identifiers, signing material, and
unbounded logs.

Exact source/package identity:

- source commit: `df98779114abd242ca56764e57c2b57977a09b5e`;
- unsigned packaged runtime SHA-256:
  `b3cabaaddb70079459fee42980098d47edba582dda0ab1de50b9081b0760419a`;
- signed executable SHA-256:
  `c415f0397de0101ba1c6ee876f65c971c2ff9394c8a7c3f0a2da3cfd7c5e600e`;
- build-fingerprint SHA-256:
  `50221dd1913372f4cccbe16e0c96861df926c7aa28aff37a79fd451c0e16b753`;
- bundle-content SHA-256:
  `893095ac96d66d036c61cbfa8af79b58eac3bdbf9d24b5da4fa44066111afcb6`.

The exact package reached retail rendering/audio, exported a 1,366-byte
report with SHA-256
`421a64fa8662bfcd948cc190b2b8d530dbffbf617e9da1103c51122fee9244d1`,
and passed a scan for the local username, absolute user paths, private data
root, key blocks, tokens, and passwords. Its first native Quit wrote a clean
marker; an exact-package relaunch observed `previousSessionClean=yes`, and the
second native Quit again exited 0 and removed the marker.

This provides bounded startup/session breadcrumbs, not a raw runtime-log
collection or crash symbolication system. Fatal guest PC/LR/function context
still belongs to the runtime's local-only fault diagnostics and is not copied
into this privacy-bounded shared report.
