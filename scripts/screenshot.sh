#!/usr/bin/env bash
set -euo pipefail

print_usage() {
  cat <<'USAGE'
Usage: scripts/screenshot.sh [-s SERIAL] [-o OUTPUT_DIR] [-p PREFIX]

Take a screenshot from an Android device via adb.
Options:
  -s SERIAL      Target device serial (adb devices -l で確認)
  -o OUTPUT_DIR  Output directory (default: assets/screenshots)
  -p PREFIX      Filename prefix (default: screenshot)
USAGE
}

serial=""
output_dir="assets/screenshots"
prefix="screenshot"

while getopts ":s:o:p:h" opt; do
  case "$opt" in
    s) serial="$OPTARG" ;;
    o) output_dir="$OPTARG" ;;
    p) prefix="$OPTARG" ;;
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

adb start-server >/dev/null

device_count="$(adb devices | awk 'NR>1 && $2=="device" {count++} END {print count+0}')"
if [[ "$device_count" -eq 0 ]]; then
  echo "接続済みの Android 端末が見つかりません。" >&2
  exit 1
fi

if [[ -z "$serial" && "$device_count" -gt 1 ]]; then
  echo "複数の端末が接続されています。-s SERIAL を指定してください。" >&2
  echo "候補:" >&2
  adb devices -l | sed -n '2,$p' >&2
  exit 1
fi

mkdir -p "$output_dir"
timestamp="$(date +%Y%m%d_%H%M%S)"
file_path="${output_dir}/${prefix}_${timestamp}.png"

args=()
if [[ -n "$serial" ]]; then
  args+=("-s" "$serial")
fi

adb "${args[@]}" exec-out screencap -p > "$file_path"
echo "Saved: $file_path"
