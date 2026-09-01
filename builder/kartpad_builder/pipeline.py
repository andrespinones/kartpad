from __future__ import annotations

import hashlib
import json
import os
import shutil
import subprocess
from dataclasses import dataclass
from pathlib import Path
from typing import Any

from .packaging import audit_app, package_unsigned_ipa
from .profiles import Profile, canonical_json, sha256_file


PIPELINE_VERSION = 1


class BuildError(RuntimeError):
    pass


def source_fingerprint(repo: Path) -> str:
    command = ["git", "-C", str(repo), "ls-files", "-s"]
    tracked = subprocess.check_output(command)
    diff = subprocess.check_output(["git", "-C", str(repo), "diff", "--binary", "HEAD", "--"])
    return hashlib.sha256(tracked + b"\0" + diff).hexdigest()


def cache_key(profile: Profile, image_sha256: str, source_sha256: str) -> str:
    payload = {
        "pipelineVersion": PIPELINE_VERSION,
        "profileSHA256": profile.profile_sha256,
        "imageSHA256": image_sha256,
        "sourceSHA256": source_sha256,
    }
    return hashlib.sha256(canonical_json(payload)).hexdigest()[:20]


def dependency_cache_key(repo: Path, paths: tuple[str, ...]) -> str:
    digest = hashlib.sha256()
    for relative in paths:
        path = repo / relative
        digest.update(relative.encode() + b"\0" + path.read_bytes() + b"\0")
    return digest.hexdigest()[:16]


def run(command: list[str], *, env: dict[str, str] | None = None) -> None:
    printable = " ".join(command)
    print(f"+ {printable}", flush=True)
    completed = subprocess.run(command, env=env)
    if completed.returncode:
        raise BuildError(f"command failed with exit code {completed.returncode}: {printable}")


def _hex(value: int | str) -> str:
    return value if isinstance(value, str) else f"0x{value:08X}"


def write_translator_manifest(profile: Profile, repo: Path, extraction: Path, translation: Path, path: Path) -> None:
    config = profile.data["translation"]
    executables = profile.data["extraction"]["executables"]
    dol = executables["dol"]
    rel = executables["rel"]
    entry_points = "\n".join(f"    - {_hex(value)}" for value in config["entryPoints"])
    text = f"""schema_version: 1
workspace_root: {repo}

project:
  id: {profile.id}
  display_name: {profile.display_name}
  game_id: {profile.data['game']['discId']}
  region: {profile.data['game']['region']}

memory:
  base: {_hex(config['memoryBase'])}
  size: {_hex(config['memorySize'])}
  sda_base: {_hex(config['sdaBase'])}
  sda2_base: {_hex(config['sda2Base'])}

inputs:
  dol:
    path: {extraction / dol['path']}
    sha256: {dol['sha256']}
  rel:
    path: {extraction / rel['path']}
    load_address: {_hex(rel['loadAddress'])}
    sha256: {rel['sha256']}

translation:
  entry_points:
{entry_points}
  function_map:
    path: {repo / config['functionMap']}
  allow_unsupported_instructions: false

runtime:
  native_registration_root: {repo / 'build/wiicompiled-fpscr/runtime/src'}
  native_abi_directories:
    - {repo / 'build/wiicompiled-fpscr/runtime/src/hle/gx'}

output:
  root: {translation}
  functions: functions
  runtime_config: RuntimeConfig.h
  data_initializer: data_sections_init.cpp
  base_manifest: base/base_manifest.json
"""
    path.write_text(text)


def _validate_extraction(profile: Profile, root: Path) -> None:
    extraction = profile.data["extraction"]
    for relative in extraction["requiredFiles"]:
        if not (root / relative).is_file():
            raise BuildError(f"extraction is missing {relative}")
    boot = (root / "sys/boot.bin").read_bytes()[:28]
    game = profile.data["game"]
    expected_header = game["discId"].encode() + bytes([game["discNumber"], game["revision"]])
    if boot[:8] != expected_header or boot[24:28].hex() != game["wiiMagic"].lower():
        raise BuildError("extracted disc identity does not match the selected profile")
    for name, executable in extraction["executables"].items():
        actual = sha256_file(root / executable["path"])
        if actual != executable["sha256"]:
            raise BuildError(f"extracted {name} does not match the selected profile")


def extract(profile: Profile, image: Path, output: Path) -> None:
    if output.is_dir():
        _validate_extraction(profile, output)
        print(f"Reused validated extraction: {output}")
        return
    if output.exists():
        raise BuildError(f"extraction output exists and is not a directory: {output}")
    extractor = profile.data["extraction"]["extractor"]
    executable = shutil.which(extractor["command"])
    if not executable:
        raise BuildError(f"missing {extractor['command']} {extractor['version']}")
    version = subprocess.check_output([executable, "--version"], text=True).strip()
    if version != f"{extractor['command']} {extractor['version']}":
        raise BuildError(f"expected {extractor['command']} {extractor['version']}, found {version}")
    output.parent.mkdir(parents=True, exist_ok=True)
    stage = output.with_name(output.name + f".partial.{os.getpid()}")
    if stage.exists():
        shutil.rmtree(stage)
    try:
        run([executable, "extract", "--quiet", str(image), str(stage)])
        _validate_extraction(profile, stage)
        manifest = {
            "schemaVersion": 1,
            "profileId": profile.id,
            "profileSHA256": profile.profile_sha256,
            "imageSHA256": sha256_file(image),
            "executables": profile.data["extraction"]["executables"],
            "extractor": version,
        }
        (stage / "kartpad-disc-manifest.json").write_bytes(canonical_json(manifest))
        stage.rename(output)
    finally:
        if stage.exists():
            shutil.rmtree(stage)


def translate(profile: Profile, repo: Path, extraction: Path, output: Path, jobs: int) -> None:
    shards = output / "build_shards/shards.cmake"
    expected_generated = profile.data["translation"]["expectedGeneratedFunctions"]
    expected_base = profile.data["translation"]["expectedBaseFunctions"]
    if shards.is_file():
        count = len(list((output / "functions").glob("func_*.cpp")))
        if count != expected_generated or f"set(MKW_BASE_FUNCTION_COUNT {expected_base})" not in shards.read_text():
            raise BuildError("cached translation failed profile validation")
        print(f"Reused validated translation: {output}")
        return
    run([str(repo / "scripts/prepare-patched-translator.sh")])
    output.mkdir(parents=True, exist_ok=True)
    manifest = output / "kartpad-builder-profile.yml"
    write_translator_manifest(profile, repo, extraction, output, manifest)
    translator = repo / "build/wiicompiled-fpscr/translator/src/Translator.Cli/bin/Release/net8.0/Translator.Cli.dll"
    dotnet = shutil.which("dotnet") or "/opt/homebrew/opt/dotnet@8/bin/dotnet"
    config = profile.data["translation"]
    metadata = output / "base_translation_output.json"
    entry = _hex(config["entryPoints"][0])
    run([dotnet, str(translator), "translate-recursive", entry, "--project", str(manifest), "--threads", str(jobs), "--prune-stale", "--output-metadata", str(metadata)])
    for injector in config["injectors"]:
        run([str(repo / injector["script"]), str(output / "functions" / injector["function"])])
    run([dotnet, str(translator), "generate-data-init", "--project", str(manifest)])
    blob = output / "data_sections_init_blobs.S"
    if ".globl _kData_" not in blob.read_text():
        run(["perl", "-0pi", "-e", r"s/^\.globl (kData_[^\n]+)\n\1:/.globl $1\n.globl _$1\n$1:\n_$1:/mg", str(blob)])
    run([dotnet, str(translator), "emit-build-shards", "--project", str(manifest), "--base-metadata", str(metadata), "--base-functions-dir", str(output / "functions"), "--native-source-dir", str(repo / "build/wiicompiled-fpscr/runtime/src"), "--out", str(output / "build_shards")])
    count = len(list((output / "functions").glob("func_*.cpp")))
    if count != expected_generated or f"set(MKW_BASE_FUNCTION_COUNT {expected_base})" not in shards.read_text():
        raise BuildError("new translation failed profile validation")


@dataclass
class BuildResult:
    ipa: Path
    ipa_sha256: str
    app: Path
    cache_key: str


def build(
    repo: Path,
    profile: Profile,
    image: Path,
    image_sha256: str,
    output: Path,
    work_root: Path,
    jobs: int = 2,
    translation_override: Path | None = None,
    app_override: Path | None = None,
) -> BuildResult:
    fingerprint = source_fingerprint(repo)
    key = cache_key(profile, image_sha256, fingerprint)
    profile_root = work_root / profile.id
    workspace = profile_root / "builds" / key
    extraction = profile_root / "inputs" / image_sha256 / "disc"
    translation = translation_override or workspace / "translation"
    if app_override is None:
        extract(profile, image, extraction)
        if translation_override is None:
            translate(profile, repo, extraction, translation, jobs)
        runtime_source = workspace / "ios-runtime-source"
        xcode_build = workspace / "ios-device-xcode"
        discio_key = dependency_cache_key(
            repo,
            (
                "scripts/build-ios-discio-probe.sh",
                "patches/dolphin-ios-discio.patch",
                "patches/dolphin-ios-discio-coreless.patch",
                "patches/dolphin-curl-ios-pipe2.patch",
            ),
        )
        discio_source = repo / f"build/builder-dependencies/discio-iphoneos-{discio_key}-source"
        discio_build = repo / f"build/builder-dependencies/discio-iphoneos-{discio_key}-build"
        if not (discio_build / "Source/Core/DiscIO/libdiscio.a").is_file():
            run([str(repo / "scripts/build-ios-discio-probe.sh"), str(repo / "ref/upstream/dolphin"), str(discio_source), str(discio_build), "iphoneos"])
        if not runtime_source.exists():
            runtime_stage = runtime_source.with_name(runtime_source.name + ".partial")
            if runtime_stage.exists():
                shutil.rmtree(runtime_stage)
            env = os.environ.copy()
            env["KARTPAD_PREPARE_ONLY"] = "1"
            env["KARTPAD_DISCIO_SOURCE_DIR"] = str(discio_source)
            env["KARTPAD_DISCIO_BUILD_DIR"] = str(discio_build)
            try:
                run([str(repo / "scripts/prepare-ios-game-runtime.sh"), str(translation), str(runtime_stage), str(workspace / "runtime-build")], env=env)
                runtime_stage.rename(runtime_source)
            except Exception:
                if runtime_stage.exists():
                    shutil.rmtree(runtime_stage)
                raise
        env = os.environ.copy()
        env["KARTPAD_DISCIO_SOURCE_DIR"] = str(discio_source)
        env["KARTPAD_DISCIO_BUILD_DIR"] = str(discio_build)
        run([str(repo / "scripts/build-ios-device-game-app.sh"), str(runtime_source), str(xcode_build), str(translation)], env=env)
        app = xcode_build / "Release-iphoneos/KartPad.app"
    else:
        app = app_override
    audit_app(app, (str(repo), str(Path.home()), str(workspace)))
    provenance = {
        "schemaVersion": 1,
        "builderVersion": "0.2.0-preview.3",
        "pipelineVersion": PIPELINE_VERSION,
        "profileId": profile.id,
        "profileSHA256": profile.profile_sha256,
        "imageSHA256": image_sha256,
        "sourceSHA256": fingerprint,
        "cacheKey": key,
        "containsUserSuppliedTranslatedCode": True,
        "redistributionAllowed": False,
    }
    digest = package_unsigned_ipa(app, output, provenance)
    return BuildResult(ipa=output, ipa_sha256=digest, app=app, cache_key=key)
