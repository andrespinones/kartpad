#!/usr/bin/env bash
set -euo pipefail

repo_root="$(git rev-parse --show-toplevel)"
cd "${repo_root}"

dotnet_bin="/opt/homebrew/opt/dotnet@8/bin/dotnet"
translator_dll="${repo_root}/build/wiicompiled-fpscr/translator/src/Translator.Cli/bin/Release/net8.0/Translator.Cli.dll"
manifest="${repo_root}/private/g8-full-mkwii.yml"
output="${repo_root}/private/g8-full-translation"
functions="${output}/functions"
metadata="${output}/base_translation_output.json"
shards="${output}/build_shards"

"${repo_root}/scripts/prepare-patched-translator.sh"
"${dotnet_bin}" "${translator_dll}" translate-recursive 0x800060A4 \
  --project "${manifest}" --threads 8 --prune-stale \
  --output-metadata "${metadata}"
"${repo_root}/scripts/inject-g10-rkg-fixture-hook.py" \
  "${functions}/func_8051FC84.cpp"
"${dotnet_bin}" "${translator_dll}" generate-data-init --project "${manifest}"
"${dotnet_bin}" "${translator_dll}" emit-build-shards \
  --project "${manifest}" \
  --base-metadata "${metadata}" \
  --base-functions-dir "${functions}" \
  --native-source-dir "${repo_root}/build/wiicompiled-fpscr/runtime/src" \
  --out "${shards}"

test -f "${functions}/func_8055531C.cpp"
test -f "${shards}/shards.cmake"
function_count="$(find "${functions}" -name 'func_*.cpp' -type f | wc -l | tr -d ' ')"
echo "Generated full DOL+StaticR title graph: ${function_count} functions"
