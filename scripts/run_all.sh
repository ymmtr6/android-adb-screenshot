#!/usr/bin/env bash
set -euo pipefail

print_usage() {
  cat <<'USAGE'
Usage: scripts/run_all.sh TITLE [-s SERIAL]

Run: auto swipe -> remove last 3 -> trim -> pngs to pdf.
Output directory: assets/TITLE
Optional: send Slack notification via scripts/run_all.env.

Options:
  -s SERIAL   Target device serial (adb devices -l で確認)
USAGE
}

if [[ "$#" -lt 1 ]]; then
  print_usage >&2
  exit 1
fi

title="$1"
shift

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

if [[ -z "$title" ]]; then
  echo "TITLE を指定してください。" >&2
  exit 1
fi

output_dir="assets/${title}"
mkdir -p "$output_dir"

serial_args=()
if [[ -n "$serial" ]]; then
  serial_args+=("-s" "$serial")
fi

config_file="scripts/run_all.env"
if [[ -f "$config_file" ]]; then
  # shellcheck disable=SC1090
  source "$config_file"
fi

SWIPE_Y_MIN_PCT=35 \
SWIPE_Y_MAX_PCT=70 \
SWIPE_START_PCT=10 \
SWIPE_END_PCT=90 \
  bash scripts/auto_swipe.sh "${serial_args[@]}" -o "$output_dir"

bash scripts/remove_last3.sh "$output_dir"
bash scripts/trim_manga.sh "$output_dir"
bash scripts/pngs_to_pdf.sh "$output_dir"

if [[ -n "${SLACK_WEBHOOK_URL:-}" ]]; then
  slack_channel="${SLACK_CHANNEL:-#system}"
  slack_username="${SLACK_USERNAME:-webhookbot}"
  slack_icon="${SLACK_ICON_EMOJI:-:ghost:}"
  curl -X POST --data-urlencode \
    "payload={\"channel\": \"${slack_channel}\", \"username\": \"${slack_username}\", \"text\": \"[完了通知]${title} の処理が完了しました。\", \"icon_emoji\": \"${slack_icon}\"}" \
    "$SLACK_WEBHOOK_URL"
fi
