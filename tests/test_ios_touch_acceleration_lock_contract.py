from __future__ import annotations

import re
import unittest
from pathlib import Path


REPO = Path(__file__).resolve().parents[1]


class IOSTouchAccelerationLockContractTests(unittest.TestCase):
    def test_hold_locks_release_reasserts_and_tap_unlocks(self) -> None:
        source = (REPO / "apple/ios/KartPadRuntimeOverlayHost.mm").read_text()

        self.assertIn("@property(nonatomic, assign) BOOL kartPadGasLocked;", source)
        self.assertIn("strongSelf.kartPadGasLocked = YES;", source)
        self.assertIn('strongButton.accessibilityValue = @"Acceleration locked";', source)

        down = re.search(
            r"- \(void\)kartPadGasDown:\(UIButton \*\)button \{(.*?)\n\}",
            source,
            re.DOTALL,
        )
        up = re.search(
            r"- \(void\)kartPadGasUp:\(UIButton \*\)button \{(.*?)\n\}",
            source,
            re.DOTALL,
        )
        self.assertIsNotNone(down)
        self.assertIsNotNone(up)
        self.assertIn("if (self.kartPadGasLocked)", down.group(1))
        self.assertIn("self.kartPadGasLocked = NO;", down.group(1))
        self.assertIn("if (self.kartPadGasLocked)", up.group(1))
        self.assertIn("dispatch_async(dispatch_get_main_queue()", up.group(1))
        self.assertIn("[super buttonDown:strongButton];", up.group(1))

    def test_modal_and_lifecycle_reset_cancel_the_lock(self) -> None:
        source = (REPO / "apple/ios/KartPadRuntimeOverlayHost.mm").read_text()
        reset = re.search(
            r"- \(void\)resetKartPadControlAppearance \{(.*?)\n\}",
            source,
            re.DOTALL,
        )
        self.assertIsNotNone(reset)
        self.assertIn("self.kartPadGasLocked = NO;", reset.group(1))
        self.assertGreaterEqual(source.count("resetKartPadControlAppearance"), 4)
        hidden = re.search(
            r"- \(void\)setTouchControlsHidden:\(BOOL\)hidden animated:\(BOOL\)animated \{"
            r"(.*?)\n\}",
            source,
            re.DOTALL,
        )
        self.assertIsNotNone(hidden)
        self.assertIn("[self clearTouchInput];", hidden.group(1))
        self.assertIn("[self resetKartPadControlAppearance];", hidden.group(1))


if __name__ == "__main__":
    unittest.main()
