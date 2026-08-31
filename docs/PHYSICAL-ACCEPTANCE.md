# iPad and iPhone physical acceptance

KartPad is ready for the next gate: a locally signed install on one physical
iPad, followed by one physical iPhone. The repository does not contain a
playable binary, signing identity, or game data.

## Before testing

- Use the current `main` checkout and your own supported PAL `RMCP01`, revision
  0 WBFS/ISO in Files.
- Build the unsigned device app with `scripts/build-ios-device-game-app.sh`,
  then sign/install it locally with your Apple development team in Xcode.
- Start on iPad. Do not begin iPhone acceptance until the iPad run is closed.
- Pair at least one extended GameController-compatible controller; two are
  useful for checking stable multiplayer slots.

## Acceptance pass

1. **Clean first launch:** with no installed game data, choose the WBFS/ISO in
   the native picker. Confirm visible progress, successful extraction, and a
   same-session transition into the Mario Kart Wii title.
2. **Identity and persistence:** reach the title and a live race, close the
   app normally, relaunch, and confirm no second import is required and the
   existing save remains available.
3. **Touch:** steer, accelerate, brake/reverse, drift, use an item, pause, and
   navigate menus. Hold A for one second: it must turn cyan, remain asserted,
   and release immediately on finger-up. Confirm compact R matches L.
4. **Three-dot menu:** open and close every KartPad/SunPad row, including
   Multiplayer, Motion Steering, Game Data & Saves, touch layout editing,
   diagnostics, display, and controls. No held input may survive a modal.
5. **Controller handoff:** while touch controls are visible, connect or wake the
   first controller. It must take Player 1, clear touch state, and hide touch
   controls by default. Drive and navigate with it. Disconnect or sleep it;
   touch must return without stale steering or buttons.
6. **Multiplayer:** connect a second controller and verify the Multiplayer view
   reports stable Player 1 and Player 2 assignments. Disconnect/reconnect in a
   different order and confirm stale input clears while retained controllers
   keep their slots.
7. **Lifecycle:** background and foreground during title and race, rotate only
   through supported landscape orientations, and recover without a black frame,
   stuck audio, lost input, or save corruption.
8. **Device quality:** listen for clean audio; assess touch and motion feel;
   watch frame pacing through title, menus, and a representative twelve-racer
   course; note thermals, memory pressure, and battery behavior.

Repeat the same pass on iPhone after iPad acceptance. Record the exact device,
OS version, commit, executable hash, controller model, and any failure's bounded
diagnostics report. Physical execution, performance, thermals, audio quality,
motion feel, and controller takeover feel are deliberately not claimed until
this procedure passes.
