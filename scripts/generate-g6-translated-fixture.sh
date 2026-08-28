#!/bin/zsh
set -euo pipefail
repo=${0:A:h:h}
dotnet_bin=/opt/homebrew/opt/dotnet@8/bin/dotnet
cd "$repo"
mkdir -p generated/g6
"$dotnet_bin" run --project tools/SemanticDolGenerator/SemanticDolGenerator.csproj \
  -c Release -- generated/g6/semantic-fixture.dol
./scripts/prepare-patched-translator.sh
"$dotnet_bin" build/wiicompiled-fpscr/translator/src/Translator.Cli/bin/Release/net8.0/Translator.Cli.dll \
  translate-recursive 0x80001000 --project fixtures/g6/translated-semantics.yml
