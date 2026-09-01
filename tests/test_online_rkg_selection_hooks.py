from __future__ import annotations

import importlib.util
import sys
import tempfile
import unittest
from pathlib import Path


REPO = Path(__file__).resolve().parents[1]
SCRIPT = REPO / "scripts" / "inject-online-rkg-selection-hooks.py"


def load_injector():
    spec = importlib.util.spec_from_file_location("online_rkg_selection_hooks", SCRIPT)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"unable to load {SCRIPT}")
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


class OnlineRkgSelectionHookTests(unittest.TestCase):
    def test_all_hooks_are_exact_and_idempotent(self) -> None:
        module = load_injector()
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            for filename, hook in module.HOOKS.items():
                with self.subTest(function=filename):
                    path = root / filename
                    path.write_text(
                        f"{hook.declaration_anchor}\n"
                        f"{hook.statement_anchor}\n"
                    )
                    self.assertTrue(module.inject(path))
                    injected = path.read_text()
                    self.assertEqual(injected.count(hook.declaration), 1)
                    self.assertEqual(injected.count(hook.statement), 1)
                    self.assertFalse(module.inject(path))
                    self.assertEqual(path.read_text(), injected)


if __name__ == "__main__":
    unittest.main()
