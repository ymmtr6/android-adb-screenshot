#!/usr/bin/env bash
set -euo pipefail

print_usage() {
  cat <<'USAGE'
Usage: scripts/setup.sh [--install]

Check required tools for adb + scrcpy on macOS.
  --install   Install missing tools via Homebrew.
USAGE
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  print_usage
  exit 0
fi

install=false
if [[ "${1:-}" == "--install" ]]; then
  install=true
fi

if ! command -v brew >/dev/null 2>&1; then
  echo "Homebrew が見つかりません。先に Homebrew をインストールしてください。"
  echo "https://brew.sh/ を参照してください。"
  exit 1
fi

missing=()
if ! command -v adb >/dev/null 2>&1; then
  missing+=("android-platform-tools")
fi
if ! command -v scrcpy >/dev/null 2>&1; then
  missing+=("scrcpy")
fi
if ! command -v magick >/dev/null 2>&1 && ! command -v convert >/dev/null 2>&1; then
  missing+=("imagemagick")
fi

if [[ ${#missing[@]} -eq 0 ]]; then
  echo "必要なツールは揃っています。"
  exit 0
fi

echo "不足しているツール: ${missing[*]}"
if [[ "$install" == true ]]; then
  brew install "${missing[@]}"
else
  echo "インストールする場合は次を実行してください:"
  echo "  scripts/setup.sh --install"
fi
