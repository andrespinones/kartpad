#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 || $# -gt 5 ]]; then
  echo "usage: $0 PID [DURATION_SECONDS] [INTERVAL_SECONDS] [ABSOLUTE_OUTPUT_DIR] [ABSOLUTE_SAVE_FILE]" >&2
  exit 64
fi

repo_root="$(git rev-parse --show-toplevel)"
pid="$1"
duration_seconds="${2:-28800}"
interval_seconds="${3:-60}"
output_dir="${4:-${repo_root}/private/macos-soak-$(date -u +%Y%m%dT%H%M%SZ)}"
save_file="${5:-}"

case "${pid}" in
  ''|*[!0-9]*) echo "PID must be a positive integer" >&2; exit 64 ;;
esac
case "${duration_seconds}" in
  ''|*[!0-9]*) echo "duration must be a positive integer" >&2; exit 64 ;;
esac
case "${interval_seconds}" in
  ''|*[!0-9]*) echo "interval must be a positive integer" >&2; exit 64 ;;
esac
if (( pid <= 1 || duration_seconds <= 0 || interval_seconds <= 0 )); then
  echo "PID, duration, and interval must be greater than zero" >&2
  exit 64
fi
if [[ "${output_dir}" != /* || "${output_dir}" != "${repo_root}/private/"* ]]; then
  echo "output directory must be an absolute path below ${repo_root}/private" >&2
  exit 64
fi
if [[ -n "${save_file}" && ( "${save_file}" != /* || ! -f "${save_file}" ) ]]; then
  echo "save file must be an existing absolute path" >&2
  exit 66
fi
if ! kill -0 "${pid}" 2>/dev/null; then
  echo "process ${pid} is not running" >&2
  exit 66
fi

executable="$(ps -o comm= -p "${pid}" | sed 's/^[[:space:]]*//')"
if [[ "${executable}" != *.app/Contents/MacOS/KartPad &&
      "${executable}" != *.app/Contents/MacOS/WiiCompiled-bin ]]; then
  echo "process ${pid} is not a KartPad app executable: ${executable}" >&2
  exit 65
fi

mkdir -p "${output_dir}"
metadata="${output_dir}/metadata.txt"
samples="${output_dir}/samples.csv"
start_epoch="$(date +%s)"
start_utc="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

{
  echo "start_utc=${start_utc}"
  echo "pid=${pid}"
  echo "duration_seconds=${duration_seconds}"
  echo "interval_seconds=${interval_seconds}"
  echo "executable=${executable}"
  echo "executable_sha256=$(shasum -a 256 "${executable}" | awk '{print $1}')"
  echo "git_commit=$(git -C "${repo_root}" rev-parse HEAD)"
  echo "hardware=$(sysctl -n hw.model)"
  echo "os_version=$(sw_vers -productVersion)"
  echo "os_build=$(sw_vers -buildVersion)"
  echo "power_source=$(pmset -g batt | head -1 | tr -d "'" | sed 's/^[[:space:]]*//')"
  if [[ -n "${save_file}" ]]; then
    echo "save_file=${save_file}"
    echo "save_size_start=$(stat -f %z "${save_file}")"
    echo "save_sha256_start=$(shasum -a 256 "${save_file}" | awk '{print $1}')"
  fi
} > "${metadata}"

echo "utc,elapsed_seconds,rss_kib,cpu_percent,thread_count" > "${samples}"
/usr/bin/vmmap -summary "${pid}" > "${output_dir}/vmmap-start.txt" 2>&1 || true

deadline=$((start_epoch + duration_seconds))
while :; do
  now_epoch="$(date +%s)"
  elapsed=$((now_epoch - start_epoch))
  if ! kill -0 "${pid}" 2>/dev/null; then
    echo "process_exited_early_at_seconds=${elapsed}" >> "${metadata}"
    exit 1
  fi

  read -r rss_kib cpu_percent < <(
    ps -o rss= -o %cpu= -p "${pid}" | awk 'NR == 1 { print $1, $2 }'
  )
  thread_count="$(ps -M "${pid}" | awk 'NR > 1 { count++ } END { print count + 0 }')"
  printf '%s,%d,%s,%s,%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    "${elapsed}" "${rss_kib}" "${cpu_percent}" "${thread_count}" >> "${samples}"

  if (( now_epoch >= deadline )); then
    break
  fi
  remaining=$((deadline - now_epoch))
  wait_seconds="${interval_seconds}"
  if (( remaining < wait_seconds )); then
    wait_seconds="${remaining}"
  fi
  sleep "${wait_seconds}"
done

/usr/bin/vmmap -summary "${pid}" > "${output_dir}/vmmap-end.txt" 2>&1 || true
set +e
/usr/bin/leaks "${pid}" > "${output_dir}/leaks.txt" 2>&1
leaks_status=$?
set -e
{
  echo "end_utc=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "completed_duration=true"
  echo "leaks_exit_status=${leaks_status}"
  echo "process_alive_at_end=$(kill -0 "${pid}" 2>/dev/null && echo true || echo false)"
  if [[ -n "${save_file}" && -f "${save_file}" ]]; then
    echo "save_size_end=$(stat -f %z "${save_file}")"
    echo "save_sha256_end=$(shasum -a 256 "${save_file}" | awk '{print $1}')"
  fi
} >> "${metadata}"

echo "macOS soak monitoring complete: ${output_dir}"
echo "Leave the app running for the explicit clean-shutdown check."
