#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
dotnet_bin="/opt/homebrew/opt/dotnet@8/bin/dotnet"
upstream="${repo_root}/ref/upstream/Wiicompiled"
output_root="${repo_root}/generated/g7"
manifest="${repo_root}/fixtures/g7/translated-frame.yml"

test -x "${dotnet_bin}"
test -f "${upstream}/translator/src/Translator.Cli/Translator.Cli.csproj"
mkdir -p "${output_root}"

"${dotnet_bin}" run --project "${repo_root}/tools/FixtureDolGenerator/FixtureDolGenerator.csproj" \
  -c Release -- "${output_root}/fixture.dol"
"${dotnet_bin}" build "${upstream}/translator/src/Translator.Cli/Translator.Cli.csproj" -c Release
translator="${upstream}/translator/src/Translator.Cli/bin/Release/net8.0/Translator.Cli.dll"
"${dotnet_bin}" "${translator}" translate-recursive 0x80001000 --project "${manifest}"

find "${output_root}/translation" -type f -maxdepth 4 -print | LC_ALL=C sort
