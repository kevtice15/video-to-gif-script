#!/usr/bin/env bash
set -euo pipefail

APP_NAME="video-to-slides-gif"
DEFAULT_PREFIX="$HOME/Scripts/$APP_NAME"
PREFIX="$DEFAULT_PREFIX"
WIDTH="1200"
INSTALL_DEPS=0

usage() {
  cat <<'USAGE'
Usage:
  ./install.sh [options]

Options:
  --prefix DIR          Install directory (default: ~/Scripts/video-to-slides-gif)
  --width PX            Finder Quick Action width (default: 1200)
  --install-deps        Install ffmpeg (+ gifsicle) via Homebrew if missing
  -h, --help            Show this help

This installer:
  1) Copies scripts to the install directory
  2) Makes scripts executable
  3) Creates a Quick Action snippet file to paste into Automator
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --prefix)
      PREFIX="$2"
      shift 2
      ;;
    --width)
      WIDTH="$2"
      shift 2
      ;;
    --install-deps)
      INSTALL_DEPS=1
      shift
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

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "Error: this installer is intended for macOS." >&2
  exit 1
fi

if [[ ! "$WIDTH" =~ ^[1-9][0-9]*$ ]]; then
  echo "Error: --width must be a positive integer." >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

mkdir -p "$PREFIX"
cp "$SCRIPT_DIR/video_to_slides_gif.sh" "$PREFIX/video_to_slides_gif.sh"
cp "$SCRIPT_DIR/video_to_slides_gif_finder.sh" "$PREFIX/video_to_slides_gif_finder.sh"
cp "$SCRIPT_DIR/VIDEO_TO_SLIDES_GUIDE.md" "$PREFIX/VIDEO_TO_SLIDES_GUIDE.md"
chmod +x "$PREFIX/video_to_slides_gif.sh" "$PREFIX/video_to_slides_gif_finder.sh"

if [[ "$INSTALL_DEPS" -eq 1 ]]; then
  if command -v brew >/dev/null 2>&1; then
    if ! command -v ffmpeg >/dev/null 2>&1; then
      brew install ffmpeg
    fi
    if ! command -v gifsicle >/dev/null 2>&1; then
      brew install gifsicle
    fi
  else
    echo "Warning: Homebrew is not available. Install dependencies manually." >&2
  fi
fi

if ! command -v ffmpeg >/dev/null 2>&1; then
  echo "Warning: ffmpeg not found. Install with: brew install ffmpeg" >&2
fi

if ! command -v gifsicle >/dev/null 2>&1; then
  echo "Note: gifsicle not found. Optional install for smaller GIFs: brew install gifsicle" >&2
fi

QUICK_ACTION_SNIPPET="$PREFIX/quick_action_run.zsh"
cat > "$QUICK_ACTION_SNIPPET" <<EOF
#!/bin/zsh
VIDEO_TO_SLIDES_GIF_WIDTH="$WIDTH" "$PREFIX/video_to_slides_gif_finder.sh" "\$@"
EOF
chmod +x "$QUICK_ACTION_SNIPPET"

cat <<EOF
Installed $APP_NAME to:
  $PREFIX

Next: create Finder Quick Action in Automator:
  1) New Quick Action
  2) Workflow receives current: movie files
  3) In: Finder
  4) Add "Run Shell Script" with:
     - Shell: /bin/zsh
     - Pass input: as arguments
  5) Paste this line:
     "$QUICK_ACTION_SNIPPET" "\$@"
  6) Save as: Video to Slides GIF

Notes:
  - Finder width is set to $WIDTH px (change by re-running install.sh --width N)
  - Core CLI script remains available at:
    $PREFIX/video_to_slides_gif.sh
EOF
