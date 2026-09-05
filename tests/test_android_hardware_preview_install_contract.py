from __future__ import annotations

import unittest
from pathlib import Path


REPO = Path(__file__).resolve().parents[1]


class AndroidHardwarePreviewInstallContractTests(unittest.TestCase):
    def test_installer_is_fail_closed_and_preserves_existing_data(self) -> None:
        installer = (
            REPO / "scripts/install-android-hardware-preview.sh"
        ).read_text()

        self.assertIn("check-android-physical-device.sh", installer)
        self.assertIn("audit-android-package.sh", installer)
        self.assertIn("24e977d497d5c587eb79771d09e317693", installer)
        self.assertIn("0.4.0-android-preview.1", installer)
        self.assertIn("expected_version_code=6", installer)
        self.assertIn("KARTPAD_ANDROID_ALLOW_PREVIEW_UPDATE", installer)
        self.assertIn('install -r "$apk"', installer)
        self.assertNotIn("pm clear", installer)
        self.assertNotIn(" uninstall ", installer)
        self.assertNotIn("install -d", installer)
        self.assertIn("KartPadLaunchActivity", installer)
        self.assertIn("Mario Kart Wii", installer)
        self.assertIn("Retro Rewind", installer)
        self.assertIn("capture-android-a2-session.sh", installer)
        self.assertIn("adb_serial=redacted", installer)
        self.assertIn("rm -rf -- \"$inspect_root\"", installer)

    def test_physical_preflight_supports_android_9_page_size_probe(self) -> None:
        preflight = (REPO / "scripts/check-android-physical-device.sh").read_text()

        self.assertIn("getconf PAGE_SIZE", preflight)
        self.assertIn("KernelPageSize", preflight)
        self.assertIn("/proc/self/smaps", preflight)


if __name__ == "__main__":
    unittest.main()
