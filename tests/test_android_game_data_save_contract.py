from __future__ import annotations

import unittest
from pathlib import Path


REPO = Path(__file__).resolve().parents[1]


class AndroidGameDataSaveContractTests(unittest.TestCase):
    def test_launcher_and_runtime_share_real_game_data_management(self) -> None:
        launcher = (REPO / "android/app/src/main/java/dev/kartpad/android/KartPadLaunchActivity.kt").read_text()
        activity = (REPO / "android/app/src/main/java/dev/kartpad/android/KartPadActivity.kt").read_text()
        manager = (REPO / "android/app/src/main/java/dev/kartpad/android/KartPadGameDataActivity.kt").read_text()
        storage = (REPO / "android/app/src/main/java/dev/kartpad/android/KartPadGameDataStorage.kt").read_text()
        manifest = (REPO / "android/app/src/main/AndroidManifest.xml").read_text()

        self.assertIn('text = "Manage Game Data…"', launcher)
        self.assertIn("KartPadGameDataStorage.validationError(filesDir)", launcher)
        self.assertIn("original.isEnabled = gameDataValid", launcher)
        self.assertIn('"Import or Reimport Game Data…"', activity)
        self.assertIn('"Remove Stored Game Data…"', activity)
        self.assertIn("Intent.ACTION_OPEN_DOCUMENT_TREE", manager)
        self.assertIn("takePersistableUriPermission", manager)
        self.assertIn("KartPadGameDataStorage.importExtractedTree", manager)
        self.assertIn("KartPadGameDataStorage.scheduleRemoval", manager)
        self.assertIn('android:name=".KartPadGameDataActivity"', manifest)
        self.assertIn('android:process=":launcher"', manifest)

        self.assertIn('"sys/boot.bin"', storage)
        self.assertIn('"files/rel/StaticR.rel"', storage)
        self.assertIn('"RMCP01"', storage)
        self.assertIn("MAIN_DOL_SHA256", storage)
        self.assertIn("GameData.import-", storage)
        self.assertIn("GameData.rollback-", storage)
        self.assertIn("ensureRelativeDvdRoot", storage)
        self.assertIn("RemoveGameDataOnNextLaunch", storage)

    def test_save_restore_is_validated_staged_and_backed_up_before_sdl(self) -> None:
        activity = (REPO / "android/app/src/main/java/dev/kartpad/android/KartPadActivity.kt").read_text()
        storage = (REPO / "android/app/src/main/java/dev/kartpad/android/KartPadSaveStorage.kt").read_text()

        self.assertIn('"Manage Saves…"', activity)
        self.assertIn('"Export Save Backup…"', activity)
        self.assertIn('"Restore Save Backup…"', activity)
        self.assertIn("Intent.ACTION_CREATE_DOCUMENT", activity)
        self.assertIn("Intent.ACTION_OPEN_DOCUMENT", activity)
        self.assertIn("KartPadSaveStorage.applyPending(filesDir)", activity)
        self.assertLess(
            activity.index("KartPadSaveStorage.applyPending(filesDir)"),
            activity.index("super.onCreate(savedInstanceState)"),
        )
        self.assertIn("SAVE_BYTES = 0x2bc000", storage)
        self.assertIn('"RKSD0006"', storage)
        self.assertIn("CRC32()", storage)
        self.assertIn("CORE_CRC_OFFSET", storage)
        self.assertIn("AtomicFile", storage)
        self.assertIn("SaveBackups", storage)


if __name__ == "__main__":
    unittest.main()
