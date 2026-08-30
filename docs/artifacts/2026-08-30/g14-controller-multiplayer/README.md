# G14 physical-controller and multiplayer checkpoint

- Built the complete 29,065-function retail iOS Simulator app with KartPad's four-player physical-controller publisher and per-channel KPAD bridge.
- `SunPadControllerSlots.h`, `SunPadControllerMapping.h`, and `SunPadControllerMapping.mm` are byte-identical to pinned SunPad commit `e43f0ea6b797e5110787171957c9dc3c6213269c`.
- The deterministic controller test covers stable slot reconciliation, persisted face-button mapping, both sticks, D-pad, shoulders, triggers, and final Classic A/R/Plus propagation. It passes together with the existing touch/Classic contract.
- The fail-closed bundle audit requires the per-player bridge, KartPad controller manager, and SunPad mapping store symbols. The audited executable SHA-256 is `be38d5d261e5ec8baa95bbe840b85e69ab7ad7b3db18f5e2e82cbf6e02e2977c`.
- Exactly one iPhone 17 Pro Simulator was booted. The app loaded the preserved `Player` data, reached live gameplay, and the Simulator's extended `Gamepad` was assigned to Player 1.
- The exact three-dot menu exposes `Multiplayer…`; its sheet reported `Connected now: 1`, explained automatic Player 1–4 assignment, and opened the Controller Setup alert. The alert is shown in `controller-setup.png` (SHA-256 `2f6f95155219062e2d1745ce52b36d3cdebe51d9f9cc10c23d338d6a548c6ea8`).

Classification: **Pass for deterministic four-channel controller publication, full-app linkage/audit, Simulator discovery, and Multiplayer/Controller Setup UI.** This does not claim hands-on Bluetooth/USB controller feel or a completed physical-controller multiplayer race on iPhone/iPad hardware.
