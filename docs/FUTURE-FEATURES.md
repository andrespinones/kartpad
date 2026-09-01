# KartPad future features

This document records credible product opportunities that are not part of the
current release priority. An entry here is not a shipping promise and should
not be presented as supported until its implementation and acceptance gates
pass.

## RetroAchievements

**Status:** Researched; deferred.

RetroAchievements could add community-authored achievements, leaderboards, and
rich presence to the original Mario Kart Wii mode. Mario Kart Wii already has
an active achievement set and a supported PAL disc hash. The feature should be
optional and eventually entered through a `RetroAchievements…` item in the
three-dot menu.

### Recommended reusable design

- Pin an official stable `rcheevos` release as the shared C runtime.
- Provide a small adapter per static-recompilation runtime: console ID, memory
  reads, frame processing, reset/pause state, and imported-game identity.
- Put Apple-specific HTTP, token storage, badge caching, notifications, and UI
  in a reusable Objective-C++ layer.
- Store the returned login token in Keychain; never persist the password.
- Keep credentials per app initially. A cross-app Keychain access group depends
  on consistent signing teams and entitlements and is unsuitable as the first
  sideloaded implementation.
- Expose the menu item only when the client is compiled in. Show whether the
  current game hash is recognized before enabling a session.

### KartPad integration points

- The Wii runtime exposes MEM1 and MEM2 through `Memory::GetPointer`; map the
  official Wii achievement address ranges onto those buffers.
- Call `rc_client_do_frame` once for every emulated frame, not merely every
  displayed frame. Call the idle path while gameplay is paused.
- Hash the user's WBFS/ISO during import, before KartPad removes a temporary
  picker copy, and persist only the resulting hash/game identifier.
- An extracted DATA folder cannot safely reproduce the official encrypted-disc
  hash. Do not infer identity solely from `main.dol`, even though KartPad uses
  that file as one compatibility check.
- Do not identify Retro Rewind as the retail Mario Kart Wii set. Leave
  RetroAchievements disabled for that mode unless its exact hash or a compatible
  subset is officially registered.

### Delivery stages

1. Build a developer-only Casual-mode proof with login, hashing, memory reads,
   per-frame evaluation, and log-only unlock events.
2. Add achievement list/status UI, unlock popups, badge caching, rich presence,
   leaderboards, network error handling, and secure offline retry behavior.
3. Validate retail PAL memory semantics and supported hashes with
   RetroAchievements administrators before public release.
4. Extract the Apple client layer only after KartPad proves the interface; keep
   console and engine mappings in per-project adapters.
5. Consider Hardcore only as a later project. It requires strict reset and mode
   transitions, disabled cheats/rewind/slowdown/frame advance/save-state loads,
   offline queuing, complete UI visibility, a stable unique user agent, privacy
   documentation, and RetroAchievements compliance approval.

### Priority decision

Do not schedule this ahead of current import reliability, lifecycle stability,
performance, physical-device coverage, or production online acceptance. It is a
medium-to-large reusable feature, not a small menu addition.
