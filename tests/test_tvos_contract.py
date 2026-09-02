import json
import plistlib
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


class TvOSContractTests(unittest.TestCase):
    def test_runtime_target_is_native_dual_mode(self):
        patch = (ROOT / "patches/wiicompiled-tvos-runtime.patch").read_text()
        self.assertIn('CMAKE_SYSTEM_NAME STREQUAL "tvOS"', patch)
        self.assertIn("mkw_configure_kartpad_tvos(KartPadDual KartPad)", patch)
        self.assertIn("TARGET_OS_IOS || TARGET_OS_TV", patch)
        self.assertIn("--- a/src/hle/input/kpad.cpp", patch)
        self.assertGreaterEqual(
            patch.count("TARGET_OS_IOS || TARGET_OS_TV"), 16
        )
        self.assertIn("MINIZIP::minizip", patch)

    def test_tvos_host_keeps_rebuildable_and_durable_state_separate(self):
        host = (ROOT / "apple/tvos/KartPadTVRuntimeHost.mm").read_text()
        self.assertIn("NSApplicationSupportDirectory", host)
        self.assertIn("NSCachesDirectory", host)
        self.assertIn('@"GameData"', host)
        self.assertIn("KartPadRetroRewindInstaller.installedRootPath", host)
        self.assertIn("KartPadTVWriteRuntimePaths", host)

    def test_extended_gamepad_is_explicit_and_siri_remote_is_not_gameplay(self):
        with (ROOT / "apple/tvos/RuntimeInfo.plist").open("rb") as handle:
            info = plistlib.load(handle)
        self.assertTrue(info["GCSupportsControllerUserInteraction"])
        self.assertEqual(
            info["GCSupportedGameControllers"], [{"ProfileName": "ExtendedGamepad"}]
        )
        host = (ROOT / "apple/tvos/KartPadTVRuntimeHost.mm").read_text()
        self.assertIn("Siri Remote", host)
        self.assertIn("not a supported racing controller", host)

    def test_retro_rewind_remains_pinned_and_hash_verified(self):
        profile = json.loads(
            (ROOT / "builder/profiles/mkwii-rmcp01-rev0.json").read_text()
        )
        self.assertEqual(profile["retroRewind"]["version"], "6.12.4")
        host = (ROOT / "apple/tvos/KartPadTVRuntimeHost.mm").read_text()
        self.assertIn("installArchiveAtURL", host)
        self.assertIn("officialArchiveURL", host)
        installer = (ROOT / "apple/ios/KartPadRetroRewindInstaller.mm").read_text()
        self.assertIn("KARTPAD_RR_ARCHIVE_SHA256", installer)
        self.assertIn("TARGET_OS_TV", installer)
        self.assertIn("NSCachesDirectory", installer)

    def test_build_and_audit_scripts_fail_closed(self):
        build = (ROOT / "scripts/build-tvos-game-app.sh").read_text()
        audit = (ROOT / "scripts/audit-tvos-app.sh").read_text()
        stage = (ROOT / "scripts/stage-tvos-game-data.sh").read_text()
        self.assertIn("CODE_SIGNING_ALLOWED=NO", build)
        self.assertIn("KartPadDual", build)
        dawn = (ROOT / "scripts/build-dawn-tvos.sh").read_text()
        self.assertIn("-ffile-prefix-map=${repo_root}=KartPad", dawn)
        self.assertIn("TVOS", audit)
        self.assertIn("/Users/[^/]+/|/tmp/kartpad-tvos-", audit)
        self.assertIn("rksys.dat", audit)
        self.assertIn("appDataContainer", stage)
        self.assertIn("80d18895b39c63bd80f457398bfcbb91", stage)


if __name__ == "__main__":
    unittest.main()
