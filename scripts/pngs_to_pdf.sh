#!/usr/bin/env bash
set -euo pipefail

print_usage() {
  cat <<'USAGE'
Usage: scripts/pngs_to_pdf.sh [-o OUTPUT_PDF] DIR

Create a single PDF from PNG files in a directory (one image per page).

Options:
  -o OUTPUT_PDF  Output PDF path (default: DIR/output.pdf)
USAGE
}

output_pdf=""

while getopts ":o:h" opt; do
  case "$opt" in
    o) output_pdf="$OPTARG" ;;
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

input_dir="$1"
if [[ ! -d "$input_dir" ]]; then
  echo "Directory not found: $input_dir" >&2
  exit 1
fi

if [[ -z "$output_pdf" ]]; then
  base_dir="${input_dir%/}"
  dir_name="$(basename "$base_dir")"
  output_pdf="${base_dir}/${dir_name}.pdf"
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

shopt -s nullglob
png_files=("$input_dir"/*.png)
shopt -u nullglob
if [[ "${#png_files[@]}" -eq 0 ]]; then
  echo "No PNG files found in: $input_dir" >&2
  exit 1
fi

IFS=$'\n' sorted_files=($(printf '%s\n' "${png_files[@]}" | LC_ALL=C sort))
unset IFS

"${im_cmd[@]}" "${sorted_files[@]}" "$output_pdf"
echo "Saved: $output_pdf"
