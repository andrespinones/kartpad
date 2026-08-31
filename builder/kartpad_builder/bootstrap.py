from __future__ import annotations

import hashlib
import json
import os
import shutil
import subprocess
import urllib.request
from pathlib import Path
from typing import Any

from .pipeline import BuildError, run
from .profiles import Profile


REQUIRED_COMMANDS = ("cmake", "ninja", "git", "rg", "python3", "dotnet", "nodtool", "xcrun")


def load_lock(repo: Path) -> dict[str, Any]:
    lock = json.loads((repo / "dependencies.lock.json").read_text())
    if lock.get("schemaVersion") != 1 or not isinstance(lock.get("dependencies"), list):
        raise BuildError("dependencies.lock.json has an unsupported schema")
    return lock


def _dependency_map(lock: dict[str, Any]) -> dict[str, dict[str, Any]]:
    return {dependency["name"]: dependency for dependency in lock["dependencies"]}


def _verify_checkout(repo: Path, dependency: dict[str, Any]) -> None:
    path = repo / dependency["path"]
    if not (path / ".git").exists():
        raise BuildError(f"missing pinned source {dependency['name']}: {path}")
    commit = subprocess.check_output(["git", "-C", str(path), "rev-parse", "HEAD^{commit}"], text=True).strip()
    tree = subprocess.check_output(["git", "-C", str(path), "rev-parse", "HEAD^{tree}"], text=True).strip()
    if commit != dependency["commit"] or tree != dependency["tree"]:
        raise BuildError(f"{dependency['name']} does not match dependencies.lock.json")
    if subprocess.check_output(["git", "-C", str(path), "status", "--porcelain"], text=True):
        raise BuildError(f"{dependency['name']} source must be clean")


def _download(url: str, expected_sha256: str, output: Path) -> None:
    output.parent.mkdir(parents=True, exist_ok=True)
    partial = output.with_name(output.name + ".partial")
    digest = hashlib.sha256()
    try:
        with urllib.request.urlopen(url) as response, partial.open("wb") as handle:
            while chunk := response.read(1024 * 1024):
                digest.update(chunk)
                handle.write(chunk)
        if digest.hexdigest() != expected_sha256:
            raise BuildError(f"downloaded artifact hash mismatch: {output.name}")
        os.replace(partial, output)
    finally:
        if partial.exists():
            partial.unlink()


def prepare_dependencies(repo: Path, profile: Profile, install: bool) -> list[str]:
    missing_commands = [command for command in REQUIRED_COMMANDS if shutil.which(command) is None]
    if missing_commands:
        raise BuildError(f"missing required commands: {', '.join(missing_commands)}")
    lock = load_lock(repo)
    dependencies = _dependency_map(lock)
    required = profile.data["sourceDependencies"]
    for name in required:
        if name not in dependencies:
            raise BuildError(f"profile names an unknown dependency: {name}")
        dependency = dependencies[name]
        path = repo / dependency["path"]
        if not (path / ".git").exists():
            if not install:
                raise BuildError(f"missing {name}; run ./scripts/build-user-ipa.sh bootstrap")
            path.parent.mkdir(parents=True, exist_ok=True)
            run(["git", "clone", "--recurse-submodules", dependency["repository"], str(path)])
            run(["git", "-C", str(path), "checkout", "--detach", dependency["commit"]])
            run(["git", "-C", str(path), "submodule", "update", "--init", "--recursive"])
            run(["git", "-C", str(path), "remote", "set-url", "--push", "origin", "DISABLED"])
        _verify_checkout(repo, dependency)

    dawn = dependencies["Dawn prebuilt"]
    dawn_output = repo / "build/dependency-cache" / f"dawn-ios-arm64-{dawn['version']}.tar.gz"
    if not dawn_output.is_file() or hashlib.sha256(dawn_output.read_bytes()).hexdigest() != dawn["iosArm64Sha256"]:
        if not install:
            raise BuildError("missing pinned physical-iOS Dawn archive; run ./scripts/build-user-ipa.sh bootstrap")
        _download(dawn["iosArm64Url"], dawn["iosArm64Sha256"], dawn_output)
    return required
