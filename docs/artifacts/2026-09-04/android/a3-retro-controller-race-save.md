# Android A3 Retro Rewind controller race/save evidence

Date: 2026-09-04

Branch: `codex/android-a3-retro-runtime`

Target: visible `KartPad_API_36_ARM64`, Android API 36, `arm64-v8a`,
4,096-byte pages, 1280x720 display override

## Falsifiable subgoal

Launch the production Retro Rewind profile, attach an Android-recognized game
controller before gameplay, navigate to a Retro Rewind course, finish a Time
Trial through the ordinary Android InputReader-to-SDL path, persist the
post-results save, force-stop the process, and prove the exact save survives a
cold controller-attached relaunch. Do not count this virtual controller as
physical-controller or physical-device acceptance.

## Exact candidate and input boundary

The run used the unchanged local-only debug APK from the production-chooser
checkpoint, SHA-256
`7088f683c9cc765c77a12203646af6d9ecdb13f1eb77f559b4bfdbc75e1caf94`.
The Android production chooser selected the preserved validated Retro Rewind
6.12.5 installation without a debug profile extra.

An ignored temporary Xbox-compatible `/dev/uinput` device was registered with
Android's documented `uinput` command contract. Android classified it as an
external keyboard/gamepad/joystick and assigned `/dev/input/event12` with the
Xbox key layout. Title, license, mode, character, vehicle, transmission,
course, acceleration, steering, results, and cold-relaunch navigation used
ordinary controller events. The Android chooser itself used its native touch
button before SDL started.

The race feedback loop read only the opt-in content-free native state trace
and emitted analog-axis/button events to `/dev/input/event12`. It did not write
guest memory, alter lap state, force a finish, inject application input, or
stage a replay. The first registration reached its explicit one-hour lifetime
during the race. The runtime recorded a normal controller disconnect and
reconnect before the same live race completed.

## Race, results, and save result

Mario / Standard Kart M / Manual completed Retro Rewind's GCN Baby Park Time
Trial. The result presentation reported total `17:13.562`, best lap
`00:19.742`, and `A ghost has been created for KartPad!`. The deliberately slow
total includes the rejected open-loop steering attempts and is not performance
or trustworthy timing evidence.

The retained ignored state trace contains 24,500 samples, reached finish stage
4 at race timer tick `62191`, and has SHA-256
`03a1f5bc447c22e21fb37a33f2c81e0cbf8aac2f884a2a958895af397bb86127`.
The ignored race console records the canonical Retro Rewind overlay, controller
connection at line 536, the one-hour-lifetime disconnect at line 762,
reconnection at line 765, and no fatal signature. Its SHA-256 is
`1e2ceafea22b33750d2eb5da4b9bdcebd3036a903de9b12d99f593580d190bd6`.

Advancing the retail results changed the isolated Retro Rewind save from
SHA-256
`3c4aeacd0356a679f261571b53cddfd371a5dc3ff9602be39ca26bdef06ea40e`
to
`7279ad4db655b893f8b2dd1a1427512c4d5799efe9047a94e67b35080c600401`.
The Original save remained out of scope and untouched.

## Cold relaunch

With the controller attached, the app was force-stopped and relaunched through
the production chooser as new PID 7432. It reached the branded Retro Rewind
title, retained the exact post-results save SHA-256
`7279ad4db655b893f8b2dd1a1427512c4d5799efe9047a94e67b35080c600401`,
and accepted controller navigation back to the Baby Park ghost menu. The cold
console records the canonical overlay at line 101, controller channel-zero
connection at line 533, active KPAD reads, and no fatal signature; its SHA-256
is `7ea11624c6e1a1982baabb5735e61834440ec7d88fd2001a2e7c9dd28f7426e6`.

The menu continued to surface the faster bundled `01:15.379` Rewind ghost as
the single selectable entry, so this checkpoint does not claim a visible
reload of the much slower new ghost. It proves the post-results save mutation
and byte-stable cold-process persistence. A faster valid record or direct
save-semantic inspection is still needed before claiming visible new-result
reload.

## Honest classification

**Pass for production-profile Retro Rewind controller discovery, menu input,
live analog gameplay, normal disconnect/reconnect handling, complete race and
results presentation, post-results save mutation, and byte-stable
controller-attached cold relaunch.** It is not physical-controller, physical-
device, tactile-rumble, audible-quality, sustained-performance, trustworthy-
timing, faster-record reload, or release acceptance. No APK, AAB, game data,
save, trace, console, or screenshot was published.
