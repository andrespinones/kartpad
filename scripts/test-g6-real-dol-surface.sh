#!/bin/zsh
set -euo pipefail

repo=${0:A:h:h}
cd "$repo"

dol=private/game-extract/sys/main.dol
expected_dol=80d18895b39c63bd80f457398bfcbb91b7d16ac116a41a88967e954080155b05
[[ -f "$dol" ]] || {
  echo "ERROR: missing ignored, user-owned $dol" >&2
  exit 1
}
actual_dol=$(shasum -a 256 "$dol" | awk '{print $1}')
[[ "$actual_dol" == "$expected_dol" ]] || {
  echo "ERROR: main.dol hash $actual_dol != $expected_dol" >&2
  exit 1
}

dotnet_bin=/opt/homebrew/opt/dotnet@8/bin/dotnet
translator_project=ref/upstream/Wiicompiled/translator/src/Translator.Cli/Translator.Cli.csproj
translator_dll=ref/upstream/Wiicompiled/translator/src/Translator.Cli/bin/Release/net8.0/Translator.Cli.dll
manifest=tools/g6-real-mkwii.yml

"$dotnet_bin" build "$translator_project" -c Release --no-restore
"$dotnet_bin" "$translator_dll" translate-recursive 0x800060A4 \
  --project "$manifest" --threads 8 --prune-stale

function_dir=private/g6-real-translation/functions
function_count=$(find "$function_dir" -name '*.cpp' -type f | wc -l | tr -d ' ')
[[ "$function_count" == 10836 ]] || {
  echo "ERROR: translated function count $function_count != 10836" >&2
  exit 1
}

surface_build=build/g6-real-surface
mkdir -p "$surface_build"
xcrun clang++ -std=c++20 -ffp-model=strict -fno-fast-math -ffp-contract=off \
  -Iruntime/translation_shim -Iruntime/include -x c++-header \
  runtime/translation_shim/ppc_runtime.h -o "$surface_build/ppc_runtime.pch"
find "$function_dir" -name '*.cpp' -print0 | xargs -0 -n 96 -P 8 \
  xcrun clang++ -std=c++20 -ferror-limit=3 -ffp-model=strict \
  -fno-fast-math -ffp-contract=off -Iruntime/translation_shim -Iruntime/include \
  -include-pch "$surface_build/ppc_runtime.pch" -fsyntax-only

echo "G6 real DOL surface: pass ($function_count translated functions, $actual_dol)"
