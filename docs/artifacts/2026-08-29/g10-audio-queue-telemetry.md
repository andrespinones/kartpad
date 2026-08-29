# G10 audio queue telemetry

Date: 2026-08-29

## Purpose

PRD row 33 requires evidence for continuity, not merely proof that non-silent PCM reaches the host. Earlier runtime logs reported the first full-queue drop but deliberately suppressed repeats, so they could not distinguish a startup/load burst from sustained loss.

The Apple runtime patch now records bounded cumulative telemetry every 8,192 queue checks (about 30 seconds at the observed title/menu submission rate) and on an orderly audio-backend shutdown:

- queue checks;
- empty-before-push observations after the initial block;
- dropped block and byte counts;
- successfully submitted bytes;
- current and observed queue-depth range; and
- the configured queue limit.

The counters add no game data or sample contents to the log. They do not alter queuing, conversion, gain, or timing behavior.

## First diagnostic sample

The initial instrumentation candidate built and ran in the signed native arm64 application. During an approximately six-minute title/attract/menu-transition session it recorded:

- 104,960 queue checks;
- 40,304,256 successfully submitted bytes;
- zero empty-before-push observations after startup;
- zero dropped blocks and zero dropped bytes; and
- an observed queue range of 0–14,796 bytes under the 15,360-byte limit.

This changed-variable sample ran after the earlier competing translation workload had ended. It proves the queue can remain continuously fed without a drop in an uncontended native session. It also explains why older one-line overflow reports cannot be accepted as sustained-loss evidence: those historical runs include heavily contended diagnostic sessions and do not contain counters.

The first candidate logged every 512 checks so its behavior could be observed quickly. The checked-in candidate uses the bounded 8,192-check interval; it must receive a fresh runtime sample before this instrumentation checkpoint is accepted.

## Classification

**In progress for PRD row 33.** The first queue sample is healthy. A fresh bounded-interval sample, gameplay/pause transitions, output-device migration, and a longer session remain open.
