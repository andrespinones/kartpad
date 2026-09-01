from __future__ import annotations

import re
import unittest
from pathlib import Path


REPO = Path(__file__).resolve().parents[1]


class IOSGameDataPickerContractTests(unittest.TestCase):
    def test_picker_does_not_filter_disc_images_by_dynamic_uti(self) -> None:
        source = (REPO / "apple/ios/KartPadRuntimeOverlayHost.mm").read_text()
        match = re.search(
            r"NSArray<UTType \*> \*KartPadGameDataContentTypes\(\) \{(.*?)\n\}",
            source,
            re.DOTALL,
        )
        self.assertIsNotNone(match)
        body = match.group(1)

        self.assertIn("return @[UTTypeItem];", body)
        self.assertNotIn("typeWithFilenameExtension", body)
        self.assertEqual(
            source.count(
                "initForOpeningContentTypes:KartPadGameDataContentTypes()"
            ),
            2,
        )


if __name__ == "__main__":
    unittest.main()
