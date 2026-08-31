from __future__ import annotations

import hashlib
import json
import plistlib
import stat
import tempfile
import unittest
import zipfile
from pathlib import Path

from kartpad_builder.packaging import PackageError, audit_app, package_unsigned_ipa
from kartpad_builder.pipeline import cache_key, dependency_cache_key
from kartpad_builder.profiles import Profile, ProfileError, load_profiles, select_profile, validate_profile


REPO = Path(__file__).resolve().parents[1]
PROFILES = REPO / "builder/profiles"


class ProfileTests(unittest.TestCase):
    def test_public_profiles_are_valid_and_unique(self) -> None:
        profiles = load_profiles(PROFILES)
        self.assertEqual([profile.id for profile in profiles], ["mkwii-rmcp01-rev0"])

    def test_profile_can_accept_multiple_container_variants(self) -> None:
        data = json.loads((PROFILES / "mkwii-rmcp01-rev0.json").read_text())
        second_hash = "1" * 64
        data["containers"]["acceptedImages"].append(
            {"format": "iso", "sha256": second_hash, "note": "test variant"}
        )
        validate_profile(data)
        profile = Profile(Path("test.json"), data)
        self.assertIs(select_profile([profile], second_hash), profile)

    def test_duplicate_container_hash_fails_closed(self) -> None:
        data = json.loads((PROFILES / "mkwii-rmcp01-rev0.json").read_text())
        data["containers"]["acceptedImages"].append(dict(data["containers"]["acceptedImages"][0]))
        with self.assertRaisesRegex(ProfileError, "duplicate"):
            validate_profile(data)

    def test_unknown_image_fails_closed(self) -> None:
        with self.assertRaisesRegex(ProfileError, "no supported profile"):
            select_profile(load_profiles(PROFILES), "0" * 64)

    def test_cache_key_changes_for_each_input(self) -> None:
        profile = load_profiles(PROFILES)[0]
        baseline = cache_key(profile, "a" * 64, "b" * 64)
        self.assertNotEqual(baseline, cache_key(profile, "c" * 64, "b" * 64))
        self.assertNotEqual(baseline, cache_key(profile, "a" * 64, "d" * 64))
        changed = json.loads(json.dumps(profile.data))
        changed["displayName"] += " changed"
        self.assertNotEqual(baseline, cache_key(Profile(Path("changed"), changed), "a" * 64, "b" * 64))

    def test_dependency_cache_key_changes_with_build_inputs(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            (root / "first").write_bytes(b"one")
            (root / "second").write_bytes(b"two")
            baseline = dependency_cache_key(root, ("first", "second"))
            (root / "second").write_bytes(b"changed")
            self.assertNotEqual(baseline, dependency_cache_key(root, ("first", "second")))


class PackagingTests(unittest.TestCase):
    def make_app(self, root: Path) -> Path:
        app = root / "KartPad.app"
        app.mkdir()
        plist = {
            "CFBundleIdentifier": "dev.kartpad.app",
            "CFBundleExecutable": "KartPad",
        }
        with (app / "Info.plist").open("wb") as handle:
            plistlib.dump(plist, handle)
        binary = app / "KartPad"
        binary.write_bytes(b"test arm64 executable")
        binary.chmod(0o755)
        (app / "asset.bin").write_bytes(b"asset")
        return app

    def test_deterministic_unsigned_ipa(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            app = self.make_app(root)
            first = root / "first.ipa"
            second = root / "second.ipa"
            provenance = {"schemaVersion": 1, "profileId": "test"}
            first_hash = package_unsigned_ipa(app, first, provenance)
            second_hash = package_unsigned_ipa(app, second, provenance)
            self.assertEqual(first_hash, second_hash)
            self.assertEqual(first.read_bytes(), second.read_bytes())
            with zipfile.ZipFile(first) as archive:
                mode = archive.getinfo("Payload/KartPad.app/KartPad").external_attr >> 16
                self.assertTrue(mode & stat.S_IXUSR)

    def test_forbidden_game_image_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            app = self.make_app(Path(temp))
            (app / "game.wbfs").write_bytes(b"private")
            with self.assertRaisesRegex(PackageError, "forbidden"):
                audit_app(app)

    def test_private_build_path_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            app = self.make_app(Path(temp))
            (app / "KartPad").write_bytes(b"prefix /Users/private/build suffix")
            with self.assertRaisesRegex(PackageError, "private build path"):
                audit_app(app, ("/Users/private",))


if __name__ == "__main__":
    unittest.main()
