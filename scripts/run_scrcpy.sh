#!/usr/bin/env bash
set -euo pipefail

print_usage() {
  cat <<'USAGE'
Usage: scripts/run_scrcpy.sh [-s SERIAL]

Start scrcpy to control an Android device.
Options:
  -s SERIAL   Target device serial (adb devices -l で確認)

Environment:
  SCRCPY_ARGS   Extra arguments passed to scrcpy
USAGE
}

serial=""
while getopts ":s:h" opt; do
  case "$opt" in
    s) serial="$OPTARG" ;;
    h)
      print_usage
      exit 0
      ;;
    \?)
      echo "Unknown option: -$OPTARG" >&2
      print_usage >&2
      exit 1
      ;;
  esac
done

if ! command -v adb >/dev/null 2>&1; then
  echo "adb が見つかりません。scripts/setup.sh を実行してください。" >&2
  exit 1
fi
if ! command -v scrcpy >/dev/null 2>&1; then
  echo "scrcpy が見つかりません。scripts/setup.sh を実行してください。" >&2
  exit 1
fi

adb start-server >/dev/null

device_count="$(adb devices | awk 'NR>1 && $2=="device" {count++} END {print count+0}')"
if [[ "$device_count" -eq 0 ]]; then
  echo "接続済みの Android 端末が見つかりません。" >&2
  echo "USB デバッグが有効か確認してください。" >&2
  exit 1
fi

if [[ -z "$serial" && "$device_count" -gt 1 ]]; then
  echo "複数の端末が接続されています。-s SERIAL を指定してください。" >&2
  echo "候補:" >&2
  adb devices -l | sed -n '2,$p' >&2
  exit 1
fi

args=()
if [[ -n "$serial" ]]; then
  args+=("-s" "$serial")
fi
if [[ -n "${SCRCPY_ARGS:-}" ]]; then
  # Allow users to add options like "--turn-screen-off --show-touches"
  read -r -a extra_args <<< "${SCRCPY_ARGS}"
  args+=("${extra_args[@]}")
fi

scrcpy "${args[@]}"
