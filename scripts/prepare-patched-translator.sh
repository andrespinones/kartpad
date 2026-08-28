#!/bin/zsh
set -euo pipefail

repo=${0:A:h:h}
upstream="$repo/ref/upstream/Wiicompiled"
stage="$repo/build/wiicompiled-fpscr"
patch_file="$repo/patches/wiicompiled-fpscr-state.patch"

mkdir -p "$stage"
rsync -a --delete --exclude .git --exclude bin --exclude obj \
  "$upstream/" "$stage/"
git apply --unidiff-zero --unsafe-paths --directory="$stage" "$patch_file"

dotnet_bin=/opt/homebrew/opt/dotnet@8/bin/dotnet
project="$stage/translator/src/Translator.Cli/Translator.Cli.csproj"
"$dotnet_bin" build "$project" -c Release
