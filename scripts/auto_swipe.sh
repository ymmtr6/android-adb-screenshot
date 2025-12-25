#!/usr/bin/env bash
set -euo pipefail

print_usage() {
  cat <<'USAGE'
Usage: scripts/auto_swipe.sh [-s SERIAL] [-o OUTPUT_DIR] [-p PREFIX] [-i INDEX]

Loop: take screenshot -> swipe right -> sleep (0.5-2.0s random).
Exit when two consecutive screenshots are unchanged. Ctrl+C to stop.

Options:
  -s SERIAL      Target device serial (adb devices -l で確認)
  -o OUTPUT_DIR  Output directory (default: assets/screenshots)
  -p PREFIX      Filename prefix (default: auto)
  -i INDEX       Start index (zero-padded 4 digits, default: 0)
USAGE
}

serial=""
output_dir="assets/screenshots"
prefix="auto"
start_index=0

while getopts ":s:o:p:i:h" opt; do
  case "$opt" in
    s) serial="$OPTARG" ;;
    o) output_dir="$OPTARG" ;;
    p) prefix="$OPTARG" ;;
    i) start_index="$OPTARG" ;;
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

if ! [[ "$start_index" =~ ^[0-9]+$ ]]; then
  echo "INDEX は 0 以上の整数で指定してください。" >&2
  exit 1
fi

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

args=()
if [[ -n "$serial" ]]; then
  args+=("-s" "$serial")
fi

get_swipe_coords() {
  local size_line width height start_x end_x y
  size_line="$(adb "${args[@]}" shell wm size | tr -d '\r' | awk -F'[: x]+' '/Physical size/ {print $3,$4}')"
  width="$(awk '{print $1}' <<< "$size_line")"
  height="$(awk '{print $2}' <<< "$size_line")"

  if [[ -z "$width" || -z "$height" ]]; then
    size_line="$(adb "${args[@]}" shell dumpsys display | tr -d '\r' | awk -F'[= x]+' '/mDisplayWidth/ {print $3,$5; exit}')"
    width="$(awk '{print $1}' <<< "$size_line")"
    height="$(awk '{print $2}' <<< "$size_line")"
  fi

  if [[ -z "$width" || -z "$height" ]]; then
    echo "画面サイズの取得に失敗しました。" >&2
    exit 1
  fi

  local start_pct end_pct
  start_pct="${SWIPE_START_PCT:-80}"
  end_pct="${SWIPE_END_PCT:-20}"

  if [[ "$start_pct" -le 0 || "$start_pct" -ge 100 || "$end_pct" -le 0 || "$end_pct" -ge 100 ]]; then
    echo "SWIPE_START_PCT/SWIPE_END_PCT は 1-99 の範囲で指定してください。" >&2
    exit 1
  fi

  start_x=$(( width * start_pct / 100 ))
  end_x=$(( width * end_pct / 100 ))

  local y_min_pct y_max_pct y_pct
  y_min_pct="${SWIPE_Y_MIN_PCT:-40}"
  y_max_pct="${SWIPE_Y_MAX_PCT:-60}"

  if [[ "$y_min_pct" -le 0 || "$y_min_pct" -ge 100 || "$y_max_pct" -le 0 || "$y_max_pct" -ge 100 || "$y_min_pct" -gt "$y_max_pct" ]]; then
    echo "SWIPE_Y_MIN_PCT/SWIPE_Y_MAX_PCT は 1-99 の範囲で、min <= max で指定してください。" >&2
    exit 1
  fi

  y_pct="$(awk -v min="$y_min_pct" -v max="$y_max_pct" 'BEGIN{srand(); print int(min + rand() * (max - min + 1))}')"
  y=$(( height * y_pct / 100 ))

  echo "$start_x $y $end_x $y"
}

trap 'echo "Stopped."; exit 0' INT

last_hash=""
same_count=0
swipe_coords="$(get_swipe_coords)"
index="$start_index"

while true; do
  file_path="${output_dir}/${prefix}_$(printf '%04d' "$index").png"
  adb "${args[@]}" exec-out screencap -p > "$file_path"

  current_hash="$(shasum -a 256 "$file_path" | awk '{print $1}')"
  if [[ "$current_hash" == "$last_hash" ]]; then
    same_count=$((same_count + 1))
  else
    same_count=0
  fi
  last_hash="$current_hash"

  if [[ "$same_count" -ge 2 ]]; then
    echo "スクリーンショットが2回連続で変化しないため終了します。"
    exit 0
  fi

  adb "${args[@]}" shell input swipe $swipe_coords 300

  sleep_sec="$(awk 'BEGIN{srand(); printf "%.2f", 0.5 + rand() * 0.5}')"
  sleep "$sleep_sec"
  index=$((index + 1))
done
