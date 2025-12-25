#!/usr/bin/env bash
set -euo pipefail

print_usage() {
  cat <<'USAGE'
Usage: scripts/remove_last3.sh DIR

Remove the last 3 PNG files in natural order from a directory.
USAGE
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  print_usage
  exit 0
fi

if [[ "$#" -ne 1 ]]; then
  print_usage >&2
  exit 1
fi

input_dir="$1"
if [[ ! -d "$input_dir" ]]; then
  echo "Directory not found: $input_dir" >&2
  exit 1
fi

shopt -s nullglob
png_files=("$input_dir"/*.png)
shopt -u nullglob

if [[ "${#png_files[@]}" -lt 3 ]]; then
  echo "PNG が3枚未満のため削除できません。" >&2
  exit 1
fi

IFS=$'\n' sorted_files=($(printf '%s\n' "${png_files[@]}" | LC_ALL=C sort -V))
unset IFS

last_three=("${sorted_files[@]: -3}")

for file_path in "${last_three[@]}"; do
  rm -f "$file_path"
  echo "Removed: $file_path"
done
