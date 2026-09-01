#!/usr/bin/env bash
set -euo pipefail

repo_root="$(git rev-parse --show-toplevel)"
manifest="${repo_root}/tools/mkwii-rmcp01-retro-rewind.yml"
output="${repo_root}/private/self-build/retro-rewind/translation"
functions="${output}/functions"
metadata="${output}/base_translation_output.json"
base_manifest_dir="${output}/base"
base_manifest="${base_manifest_dir}/mkwii_base_manifest.json"
mod_output="${repo_root}/private/self-build/retro-rewind/mod"
shards="${output}/build_shards"
default_retro_root="${repo_root}/ref/upstream/rr-pulsar/PulsarPackCreator/Resources"
retro_root="${default_retro_root}"
payload=""
skip_retro_wfc=false
dotnet_bin="/opt/homebrew/opt/dotnet@8/bin/dotnet"
translator="${repo_root}/build/wiicompiled-fpscr/translator/src/Translator.Cli/bin/Release/net8.0/Translator.Cli.dll"
translation_jobs="${KARTPAD_TRANSLATION_JOBS:-2}"

usage() {
  cat >&2 <<'USAGE'
Usage: scripts/translate-retro-rewind.sh (--payload FILE | --skip-retro-wfc) [--retro-root DIR]

Retranslates the user-owned RMCP01 base with awareness of KartPad's pinned
Retro Rewind Code.pul, translates the static mod profile, and emits a separate
native build graph. --skip-retro-wfc is diagnostic only and may not be used for
an online-support claim.
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --payload)
      [[ $# -ge 2 ]] || { usage; exit 64; }
      payload="$2"
      shift 2
      ;;
    --retro-root)
      [[ $# -ge 2 ]] || { usage; exit 64; }
      retro_root="$2"
      shift 2
      ;;
    --skip-retro-wfc)
      skip_retro_wfc=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      usage
      exit 64
      ;;
  esac
done

if [[ -n "${payload}" && "${skip_retro_wfc}" == true ]]; then
  echo "ERROR: choose either --payload or --skip-retro-wfc" >&2
  exit 64
fi
if [[ -z "${payload}" && "${skip_retro_wfc}" == false ]]; then
  echo "ERROR: an explicit local Retro-WFC payload is required" >&2
  usage
  exit 64
fi
[[ "${translation_jobs}" =~ ^[1-8]$ ]] || {
  echo "ERROR: KARTPAD_TRANSLATION_JOBS must be an integer from 1 through 8" >&2
  exit 64
}

retro_root="$(cd "${retro_root}" && pwd)"
if [[ "${retro_root}" == "${default_retro_root}" ]]; then
  code_pul="${retro_root}/Code.pul"
else
  code_pul="${retro_root}/Binaries/Code.pul"
fi
[[ -f "${code_pul}" ]] || {
  echo "ERROR: missing Retro Rewind Code.pul at ${code_pul}" >&2
  exit 66
}
if [[ -n "${payload}" ]]; then
  payload="$(cd "$(dirname "${payload}")" && pwd)/$(basename "${payload}")"
  [[ -f "${payload}" ]] || {
    echo "ERROR: missing Retro-WFC payload at ${payload}" >&2
    exit 66
  }
fi

"${repo_root}/scripts/prepare-disc.sh"
"${repo_root}/scripts/prepare-patched-translator.sh"
mkdir -p "${output}" "${base_manifest_dir}"

"${dotnet_bin}" "${translator}" translate-recursive 0x800060A4 \
  --project "${manifest}" --profile retro-rewind \
  --threads "${translation_jobs}" --prune-stale \
  --output-metadata "${metadata}"
"${repo_root}/scripts/inject-g10-rkg-fixture-hook.py" \
  "${functions}/func_8051FC84.cpp"
for selection_function in 8083DFA8 80846C1C 8084E388 80643F48; do
  "${repo_root}/scripts/inject-online-rkg-selection-hooks.py" \
    "${functions}/func_${selection_function}.cpp"
done
"${repo_root}/scripts/inject-g10-camera-lifecycle-guard.py" \
  "${functions}/func_805A1A8C.cpp"

"${dotnet_bin}" "${translator}" emit-base-manifest \
  --project "${manifest}" --profile retro-rewind \
  --out "${base_manifest_dir}" --functions-dir "${functions}" \
  --translation-output-metadata "${metadata}" --region P
[[ -f "${base_manifest}" ]] || {
  echo "ERROR: translator did not emit ${base_manifest}" >&2
  exit 70
}

translate_mod_args=(
  translate-mod --project "${manifest}" --profile retro-rewind
  --base-manifest "${base_manifest}"
  --base-translation-output-metadata "${metadata}"
  --code-pul "${code_pul}" --mod-root "${retro_root}"
  --mod-name "Retro Rewind" --region P --out "${mod_output}"
  --prefer-cached-inputs --emit-cpp --threads "${translation_jobs}"
)
if [[ "${skip_retro_wfc}" == true ]]; then
  translate_mod_args+=(--skip-retro-wfc)
else
  translate_mod_args+=(--retro-wfc-payload "${payload}")
fi
"${dotnet_bin}" "${translator}" "${translate_mod_args[@]}"

"${dotnet_bin}" "${translator}" generate-data-init \
  --project "${manifest}" --profile retro-rewind
"${dotnet_bin}" "${translator}" emit-build-shards \
  --project "${manifest}" --profile retro-rewind \
  --base-metadata "${metadata}" --base-functions-dir "${functions}" \
  --native-source-dir "${repo_root}/build/wiicompiled-fpscr/runtime/src" \
  --resolved-profile "${mod_output}/resolved_dispatch_profile.json" \
  --retro-cpp-dir "${mod_output}/cpp" --out "${shards}"

[[ -f "${mod_output}/resolved_dispatch_profile.json" ]]
[[ -f "${shards}/shards.cmake" ]]
rg -q '^set\(MKW_RETRO_REWIND_FUNCTION_COUNT [1-9][0-9]*\)$' \
  "${shards}/shards.cmake"
rg -q '^set\(MKW_HAVE_RETRO_REWIND_SHARDS ON\)$' "${shards}/shards.cmake"

echo "Generated validated private Retro Rewind native graph"
if [[ "${skip_retro_wfc}" == true ]]; then
  echo "NOTE: Retro-WFC payload lowering was intentionally skipped; online is not proven"
fi
