#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "usage: $0 /absolute/path/to/native-state-trace.csv" >&2
  exit 64
fi

repo_root="$(git rev-parse --show-toplevel)"
trace_path="$1"
app_path="${KARTPAD_RUNTIME_APP:-${repo_root}/build/g7-game-run/KartPadRuntime.app}"
launcher="${app_path}/Contents/MacOS/KartPadRuntime"
runtime="${app_path}/Contents/MacOS/WiiCompiled-bin"

if [[ "${trace_path}" != /* ]]; then
  echo "trace path must be absolute: ${trace_path}" >&2
  exit 64
fi
if [[ -e "${trace_path}" ]]; then
  echo "refusing to overwrite existing trace: ${trace_path}" >&2
  exit 73
fi
if [[ ! -d "$(dirname "${trace_path}")" ]]; then
  echo "trace parent directory does not exist: $(dirname "${trace_path}")" >&2
  exit 72
fi
if [[ ! -x "${launcher}" || ! -x "${runtime}" ]]; then
  echo "KartPad runtime is not built at ${app_path}" >&2
  exit 69
fi
if pgrep -f "${runtime}" >/dev/null; then
  echo "refusing to launch a second KartPad runtime" >&2
  exit 75
fi

export KARTPAD_STATE_TRACE="${trace_path}"
exec "${launcher}"
