#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  ./uninstall.sh [--prefix DIR]

Options:
  --prefix DIR     Install directory to remove (default: ~/Scripts/video-to-slides-gif)
  -h, --help       Show this help
USAGE
}

PREFIX="$HOME/Scripts/video-to-slides-gif"
WORKFLOW_NAMES=(
  "Video to Slides GIF - Small"
  "Video to Slides GIF - Medium"
  "Video to Slides GIF - Large"
  "Video to Slides GIF - Max"
)
while [[ $# -gt 0 ]]; do
  case "$1" in
    --prefix)
      PREFIX="${2:-}"
      if [[ -z "$PREFIX" || "$PREFIX" == -* ]]; then
        echo "Error: --prefix requires a directory path." >&2
        exit 1
      fi
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage
      exit 1
      ;;
  esac
done

if [[ "$PREFIX" == "/" || -z "$PREFIX" ]]; then
  echo "Error: refusing to remove unsafe prefix: $PREFIX" >&2
  exit 1
fi

if [[ -d "$PREFIX" ]]; then
  rm -rf "$PREFIX"
  echo "Removed: $PREFIX"
else
  echo "Nothing to remove at: $PREFIX"
fi

for workflow_name in "${WORKFLOW_NAMES[@]}"; do
  workflow_path="$HOME/Library/Services/${workflow_name}.workflow"
  if [[ -d "$workflow_path" ]]; then
    rm -rf "$workflow_path"
    echo "Removed Quick Action:"
    echo "  $workflow_path"
  else
    echo "No Quick Action found at:"
    echo "  $workflow_path"
  fi
done

if [[ -x /System/Library/CoreServices/pbs ]]; then
  /System/Library/CoreServices/pbs -update >/dev/null 2>&1 || true
fi
