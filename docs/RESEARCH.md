# KartPad research ledger

## Notion/source baseline

The approved PRD records a favorable but medium-confidence feasibility assessment: WiiCompiled provides a real static-recompilation substrate, while PowerPC floating-point fidelity, Darwin guest memory, portable scheduling, native Metal integration, and online compatibility remain hard evidence gates. The source/self-build and private-data boundary is mandatory.

## Current upstream research

WiiCompiled was fetched and verified at commit `1912292c804ff9b1b79938de89369ec4496f9fff` with tree `34f9deda094915e12f47316059911b28c6812964`. Implementation conclusions remain pending complete source inspection and execution of the upstream tests.

The other required references are pinned in `dependencies.lock.json`: WheelWizard, Retro Rewind Pulsar, the Retro Rewind WFC server and patcher, and Dolphin. Aurora is vendored inside the WiiCompiled tree and declares Dawn build `v20260603.191052`. All Git reference checkouts are detached, clean, and push-disabled. The server is AGPL-3.0; the patcher offers its custom attribution license or GPL-2.0-or-later; Dolphin requires per-file SPDX review. No default local-testing private key may enter a KartPad artifact or log.

WiiCompiled bundles `projects/mkwii/MAP.txt` in its GPLv3 repository. It is sufficient as a private local translation/symbolization reference at the pin, but independent provenance for republishing the map has not been established; package/repository audits must not copy it into KartPad.

## Direct product reference: SunPad

The user supplied a local SunPad checkout as the authoritative interaction and README reference. Its iOS overlay provides a persistent `•••` menu, multitouch controls, normalized per-device layouts, edit/reset behavior, controller handoff, held-input clearing, settings, data management, diagnostics, and accessibility labels. KartPad will reuse the component implementation directly when the mobile prerequisite gates are met. SunPad's README structure—clear product statement, icon, badges, evidence-backed status, build/first-run guidance, touch documentation, screenshots, data boundary, FAQ, architecture, and legal notices—is the documentation quality bar.

The exact component is `apple/ios/SunPadGameOverlay.mm` plus its delegate contract, settings, input state, and input mixer. The persistent menu button uses the SF Symbol `ellipsis`, a 40-point circular dark material-like treatment, `showsMenuAsPrimaryAction`, and a rebuilt `UIMenu`; its placement remains above controls and inside the safe area. These source details are GPLv3-compatible with KartPad's WiiCompiled-derived GPLv3 distribution requirement.
