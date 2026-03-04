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

cat <<'EOF'
If you created the Finder Quick Action, remove it manually:
  Finder -> Go -> Go to Folder...
  ~/Library/Services
Then delete:
  Video to Slides GIF.workflow
EOF
