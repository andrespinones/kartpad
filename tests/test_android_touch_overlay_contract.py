from __future__ import annotations

import unittest
from pathlib import Path


REPO = Path(__file__).resolve().parents[1]


class AndroidTouchOverlayContractTests(unittest.TestCase):
    def test_overlay_exposes_complete_classic_control_set(self) -> None:
        source = (REPO / "android/app/src/main/java/dev/kartpad/android/KartPadOverlayView.kt").read_text()
        for control in (
            '"move"', '"c"', '"A"', '"B"', '"X"', '"Y"', '"Z"',
            '"Start"', '"L"', '"R"', '"DpadUp"', '"DpadDown"',
            '"DpadLeft"', '"DpadRight"',
        ):
            self.assertIn(control, source)
        self.assertIn("pointerOwners", source)
        self.assertIn("nativePublishTouchState", source)

    def test_lifecycle_clears_touch_state(self) -> None:
        activity = (REPO / "android/app/src/main/java/dev/kartpad/android/KartPadActivity.kt").read_text()
        self.assertIn("override fun onPause()", activity)
        self.assertIn("override fun onWindowFocusChanged(hasFocus: Boolean)", activity)
        self.assertGreaterEqual(activity.count("kartPadOverlay.clearTouchInput()"), 2)

    def test_runtime_preparation_applies_touch_bridge(self) -> None:
        script = (REPO / "scripts/prepare-android-game-runtime.sh").read_text()
        self.assertIn("wiicompiled-android-touch-input.patch", script)
        patch = (REPO / "patches/wiicompiled-android-touch-input.patch").read_text()
        self.assertIn('"kartpad/android/touch_input.h"', patch)
        self.assertIn("ConsumeTouchInput()", patch)
        self.assertIn("CoreButtonsForClassic(touchInput.buttons)", patch)

    def test_game_build_selects_dual_preparation_for_a_dual_graph(self) -> None:
        script = (REPO / "scripts/build-android-game-app.sh").read_text()
        self.assertIn('runtime_product="base"', script)
        self.assertIn('runtime_product="dual"', script)
        self.assertIn('"$runtime_build" "$runtime_product"', script)
        self.assertIn('native_target="KartPadDual"', script)


if __name__ == "__main__":
    unittest.main()
