#!/usr/bin/env bash
set -euo pipefail

repo_root="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
export PYTHONPATH="${repo_root}/builder${PYTHONPATH:+:${PYTHONPATH}}"
exec python3 -m kartpad_builder.cli "$@"
