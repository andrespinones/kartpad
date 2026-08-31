# Touch-modal input clearing

KartPad now clears the complete SunPad touch contribution whenever Touch
Control Settings opens or closes. The override lives in KartPad's owning
subclass; the pinned twelve-file SunPad snapshot remains byte-identical.

## Runtime proof

- Target: sole booted iPhone 17 Pro Simulator, iOS 26.5.
- Exact action: publish the real A control's touch-down, open the real Touch
  Control Settings path, then sample the shared mixer through the Classic
  adapter.
- Before the modal: Classic buttons `0x00000010` (A held).
- After the modal opened: Classic buttons `0x00000000` (A released).
- Bounded runtime breadcrumb: `touch modal input self-test: pass`.
- Accessibility result after close: `Touch settings input-clear self-test
  passed.`
- The overlay returned to live gameplay with A in its normal released state;
  screenshot: `restored-controls.png`, SHA-256
  `5606e044de6a958444d24564ea20a7b29d213697d195d13ce250f018baa04c9d`.

## Build boundaries

- Full Xcode Simulator app audit: pass; executable SHA-256
  `de7d46bd5bd2c55c7b40acbeac1d4013aa800a5d2b086cf36dfaf2d88e218acb`.
- Full physical-iOS app audit: pass; executable SHA-256
  `f8ed5777817894fffd84e0330659240e2e10731b072d2c60b0df3b1701db9375`.
- The physical binary contains no `KARTPAD_TOUCH_MODAL_SELF_TEST` contract.
- Exact SunPad snapshot verification: pass at
  `e43f0ea6b797e5110787171957c9dc3c6213269c`.

The compact three-dot menu and Touch Control Settings panel were also opened
over live gameplay through Computer Use. Keyboard navigation exposed the
menu's lower rows. Computer Use pointer drags did not become simulated finger
swipes inside the settings scroll view, so direct automation of the lower
Move/Reset rows remains **inconclusive**, not Pass. Their source and prior
shell evidence remain separate. KartPad was terminated, the only Simulator
was shut down, and no runtime remains.
