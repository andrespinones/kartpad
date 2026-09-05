from __future__ import annotations

import json
import unittest
from pathlib import Path


REPO = Path(__file__).resolve().parents[1]


class AndroidTlsContractTests(unittest.TestCase):
    def test_android_apk_packages_mbed_tls_license(self) -> None:
        license_path = (
            REPO
            / "android/app/src/main/assets/ThirdPartyLicenses/Mbed-TLS.txt"
        )
        license_text = license_path.read_text(encoding="utf-8")
        self.assertIn("Apache License", license_text)
        self.assertIn("GNU GENERAL PUBLIC LICENSE", license_text)

    def test_mbedtls_release_is_hash_locked_and_prepared(self) -> None:
        dependencies = json.loads((REPO / "dependencies.lock.json").read_text())["dependencies"]
        dependency = next(item for item in dependencies if item["name"] == "Mbed TLS Android")
        self.assertEqual(dependency["version"], "4.1.1")
        self.assertEqual(dependency["bytes"], 7_099_934)
        self.assertEqual(
            dependency["sha256"],
            "3359a349e23db3d5536fcee032ae7b2ecbfc08972fab643089b5cbf2a375c98c",
        )
        prepare = (REPO / "scripts/prepare-android-dependencies.sh").read_text()
        self.assertIn('mbedtls_version="4.1.1"', prepare)
        self.assertIn('echo "MBEDTLS_ANDROID_ROOT=$mbedtls_root"', prepare)

    def test_source_fixture_requires_entropy_and_peer_verification(self) -> None:
        fixture = (REPO / "android/app/src/main/cpp/android_tls_fixture.cpp").read_text()
        main = (REPO / "android/app/src/main/cpp/fixture_main.cpp").read_text()
        cmake = (REPO / "android/app/src/main/cpp/CMakeLists.txt").read_text()
        self.assertIn("psa_crypto_init()", fixture)
        self.assertIn("psa_generate_random", fixture)
        self.assertIn("MBEDTLS_SSL_VERIFY_REQUIRED", fixture)
        self.assertIn('mbedtls_ssl_set_hostname(&ssl, "kartpad.invalid")', fixture)
        self.assertIn("RunAndroidTlsFixture()", main)
        self.assertIn("mbedtls android log dl", cmake)

    def test_guest_tls_backend_is_patched_into_android_product(self) -> None:
        header = (
            REPO / "runtime/include/kartpad/network/android_mbedtls.h"
        ).read_text()
        source = (
            REPO / "runtime/src/hle/net/android_mbedtls.cpp"
        ).read_text()
        patch = (
            REPO / "patches/wiicompiled-android-network-tls.patch"
        ).read_text()
        prepare = (REPO / "scripts/prepare-android-game-runtime.sh").read_text()
        cmake = (REPO / "android/app/src/main/cpp/CMakeLists.txt").read_text()

        self.assertIn("class AndroidMbedTlsSession final", header)
        self.assertIn("MBEDTLS_SSL_VERIFY_REQUIRED", source)
        self.assertIn("mbedtls_x509_crt_parse_der", source)
        self.assertIn("mbedtls_ssl_set_hostname", source)
        self.assertIn("AndroidMbedTlsSession", patch)
        self.assertIn("SetRootCaDer", patch)
        self.assertIn("AttachSocket", patch)
        self.assertIn("wiicompiled-android-network-tls.patch", prepare)
        self.assertIn('runtime/src/hle/net/android_mbedtls.cpp"', cmake)
        self.assertIn("MINIZIP::minizip mbedtls", cmake)

    def test_tls_fixtures_use_only_ephemeral_private_keys(self) -> None:
        script = (REPO / "scripts/test-android-tls-local.sh").read_text()
        emulator_script = (
            REPO / "scripts/test-android-tls-emulator.sh"
        ).read_text()
        loopback = (
            REPO / "android/app/src/main/cpp/android_tls_loopback_fixture.cpp"
        ).read_text()
        main = (REPO / "android/app/src/main/cpp/fixture_main.cpp").read_text()
        private_key_marker = "BEGIN " + "PRIVATE" + " KEY"

        self.assertIn("mktemp -d", script)
        self.assertIn("trap cleanup EXIT", script)
        self.assertIn('rm -rf "$temporary_root"', script)
        self.assertNotIn(private_key_marker, script)
        self.assertIn("mktemp -d", emulator_script)
        self.assertIn("trap cleanup EXIT", emulator_script)
        self.assertNotIn(private_key_marker, emulator_script)
        self.assertIn('"10.0.2.2"', loopback)
        self.assertIn("RunAndroidTlsLoopbackFixture()", main)


if __name__ == "__main__":
    unittest.main()
