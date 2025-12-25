#!/usr/bin/env bash
set -euo pipefail

print_usage() {
  cat <<'USAGE'
Usage: scripts/trim_manga.sh [-o OUTPUT_DIR] [-t TOP_PX] [-b BOTTOM_PX] [-k] DIR

Trim manga area by cutting top/bottom pixels from screenshots.
Defaults: top=435px, bottom=435px

Options:
  -o OUTPUT_DIR  Output directory (default: same as input dir)
  -t TOP_PX      Pixels to cut from top (default: 340)
  -b BOTTOM_PX   Pixels to cut from bottom (default: 340)
  -k             Keep original files (default: delete originals)
USAGE
}

output_dir=""
top_px=340
bottom_px=340
keep_originals=false

while getopts ":o:t:b:kh" opt; do
  case "$opt" in
    o) output_dir="$OPTARG" ;;
    t) top_px="$OPTARG" ;;
    b) bottom_px="$OPTARG" ;;
    k) keep_originals=true ;;
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
shift $((OPTIND - 1))

if [[ "$#" -ne 1 ]]; then
  print_usage >&2
  exit 1
fi

if ! [[ "$top_px" =~ ^[0-9]+$ && "$bottom_px" =~ ^[0-9]+$ ]]; then
  echo "TOP_PX/BOTTOM_PX は 0 以上の整数で指定してください。" >&2
  exit 1
fi

input_dir="$1"
if [[ ! -d "$input_dir" ]]; then
  echo "Directory not found: $input_dir" >&2
  exit 1
fi
if [[ -z "$output_dir" ]]; then
  output_dir="$input_dir"
fi

im_cmd=()
if command -v magick >/dev/null 2>&1; then
  im_cmd=(magick)
elif command -v convert >/dev/null 2>&1 && convert -version 2>/dev/null | grep -q "ImageMagick"; then
  im_cmd=(convert)
else
  echo "ImageMagick が見つかりません。brew install imagemagick を実行してください。" >&2
  exit 1
fi

mkdir -p "$output_dir"

shopt -s nullglob
png_files=("$input_dir"/*.png)
shopt -u nullglob
if [[ "${#png_files[@]}" -eq 0 ]]; then
  echo "No PNG files found in: $input_dir" >&2
  exit 1
fi

for in_path in "${png_files[@]}"; do
  base_name="$(basename "$in_path")"
  name="${base_name%.*}"
  ext="${base_name##*.}"
  if [[ "$name" =~ ([0-9]{4})$ ]]; then
    out_path="${output_dir}/${BASH_REMATCH[1]}.${ext}"
  else
    echo "ファイル名の末尾に4桁の数字が見つかりません: $base_name" >&2
    exit 1
  fi

  "${im_cmd[@]}" "$in_path" \
    -gravity North -chop "0x${top_px}" \
    -gravity South -chop "0x${bottom_px}" \
    "$out_path"

  if [[ "$keep_originals" == false ]]; then
    rm -f "$in_path"
  fi

  echo "Saved: $out_path"
done
