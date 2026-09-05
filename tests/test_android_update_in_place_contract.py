from __future__ import annotations

import unittest
from pathlib import Path


REPO = Path(__file__).resolve().parents[1]


class AndroidUpdateInPlaceContractTests(unittest.TestCase):
    def test_emulator_runner_preserves_durable_state(self) -> None:
        runner = (
            REPO / "scripts/test-android-update-in-place-emulator.sh"
        ).read_text()

        self.assertNotIn("pm clear", runner)
        self.assertGreaterEqual(runner.count('install -r "$apk"'), 1)
        self.assertIn("files/KartPad/Config.toml", runner)
        self.assertIn("files/KartPad/GameData/sys/main.dol", runner)
        self.assertIn("tree_digest files/KartPad/NAND", runner)
        self.assertIn("tree_digest files/KartPad/Saves", runner)
        self.assertIn("tree_digest shared_prefs", runner)
        self.assertIn("durable_state_preserved=yes", runner)
        self.assertIn(".KartPadLaunchActivity", runner)


if __name__ == "__main__":
    unittest.main()
