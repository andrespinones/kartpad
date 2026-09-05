from __future__ import annotations

import unittest
from pathlib import Path


REPO = Path(__file__).resolve().parents[1]


class AndroidBundleDerivedApkContractTests(unittest.TestCase):
    def test_runner_audits_installs_and_restores_without_clearing_data(self) -> None:
        runner = (
            REPO / "scripts/test-android-bundle-derived-apk-emulator.sh"
        ).read_text()

        self.assertIn("audit-android-bundle.sh", runner)
        self.assertIn("build-apks", runner)
        self.assertIn("--mode=universal", runner)
        self.assertIn("audit-android-package.sh", runner)
        self.assertIn('pull "$installed_path" "$restore_apk"', runner)
        self.assertGreaterEqual(runner.count('"${adb_target[@]}" install'), 3)
        self.assertNotIn("pm clear", runner)
        self.assertIn("application-debuggable", runner)
        self.assertIn("Running main function SDL_main", runner)
        self.assertIn("sdl_main_executed=yes", runner)
        self.assertIn("kartpad_mode_original", runner)
        self.assertIn('shell input tap', runner)
        self.assertIn("files/KartPad/GameData/sys/main.dol", runner)
        self.assertIn("tree_digest files/KartPad/NAND", runner)
        self.assertIn("tree_digest files/KartPad/Saves", runner)
        self.assertIn("tree_digest shared_prefs", runner)
        self.assertIn("durable_state_preserved=yes", runner)
        self.assertIn("debug_apk_restored=yes", runner)
        self.assertIn("derived_version >= restore_version", runner)
        self.assertIn("restore_install_args=(-r -d)", runner)
        self.assertIn(".KartPadLaunchActivity", runner)
        self.assertIn("rm -rf -- \"$temp_root\"", runner)

    def test_apk_audit_accepts_only_the_complete_bundletool_profile_pair(self) -> None:
        audit = (REPO / "scripts/audit-android-package.sh").read_text()

        self.assertIn("assets/dexopt/baseline.prof", audit)
        self.assertIn("assets/dexopt/baseline.profm", audit)
        self.assertIn("Require the complete,", audit)
        self.assertIn("KARTPAD_ANDROID_EXPECTED_VERSION_NAME", audit)
        self.assertIn("0.4.0-android-preview.1", audit)


if __name__ == "__main__":
    unittest.main()
