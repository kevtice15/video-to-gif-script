#!/usr/bin/env bash
set -euo pipefail

APP_NAME="video-to-slides-gif"
DEFAULT_PREFIX="$HOME/Scripts/$APP_NAME"
PREFIX="$DEFAULT_PREFIX"
INSTALL_DEPS=0

usage() {
  cat <<'USAGE'
Usage:
  ./install.sh [options]

Options:
  --prefix DIR          Install directory (default: ~/Scripts/video-to-slides-gif)
  --install-deps        Install ffmpeg (+ gifsicle) via Homebrew if missing
  -h, --help            Show this help

This installer:
  1) Copies scripts to the install directory
  2) Makes scripts executable
  3) Installs Finder Quick Actions automatically
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --prefix)
      PREFIX="$2"
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

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKFLOW_TEMPLATE_DIR="$SCRIPT_DIR/templates/quick_action"

mkdir -p "$PREFIX"
cp "$SCRIPT_DIR/video_to_slides_gif.sh" "$PREFIX/video_to_slides_gif.sh"
cp "$SCRIPT_DIR/video_to_slides_gif_finder.sh" "$PREFIX/video_to_slides_gif_finder.sh"
cp "$SCRIPT_DIR/create_quick_action.sh" "$PREFIX/create_quick_action.sh"
cp "$SCRIPT_DIR/VIDEO_TO_SLIDES_GUIDE.md" "$PREFIX/VIDEO_TO_SLIDES_GUIDE.md"
mkdir -p "$PREFIX/templates"
rm -rf "$PREFIX/templates/quick_action"
cp -R "$WORKFLOW_TEMPLATE_DIR" "$PREFIX/templates/quick_action"
chmod +x \
  "$PREFIX/video_to_slides_gif.sh" \
  "$PREFIX/video_to_slides_gif_finder.sh" \
  "$PREFIX/create_quick_action.sh"

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

create_quick_action() {
  local label="$1"
  local width="$2"
  local launcher="$PREFIX/quick_action_${label}.zsh"
  local display_label=""
  local action_name=""
  local workflow_path=""

  case "$label" in
    small) display_label="Small" ;;
    medium) display_label="Medium" ;;
    large) display_label="Large" ;;
    max) display_label="Max" ;;
    *) echo "Error: unknown Quick Action label: $label" >&2; exit 1 ;;
  esac

  action_name="Video to Slides GIF - $display_label"
  workflow_path="$HOME/Library/Services/${action_name}.workflow"

  cat > "$launcher" <<EOF
#!/bin/zsh
VIDEO_TO_SLIDES_GIF_WIDTH="$width" VIDEO_TO_SLIDES_GIF_LABEL="$label" "$PREFIX/video_to_slides_gif_finder.sh" "\$@"
EOF
  chmod +x "$launcher"

  "$PREFIX/create_quick_action.sh" \
    --launcher "$launcher" \
    --template-dir "$PREFIX/templates/quick_action" \
    --workflow-path "$workflow_path" \
    --name "$action_name"
}

create_quick_action "small" "800"
create_quick_action "medium" "1200"
create_quick_action "large" "1600"
create_quick_action "max" "1920"

if [[ -x /System/Library/CoreServices/pbs ]]; then
  /System/Library/CoreServices/pbs -update >/dev/null 2>&1 || true
fi

cat <<EOF
Installed $APP_NAME to:
  $PREFIX

Installed Finder Quick Actions:
  $HOME/Library/Services/Video to Slides GIF - Small.workflow
  $HOME/Library/Services/Video to Slides GIF - Medium.workflow
  $HOME/Library/Services/Video to Slides GIF - Large.workflow
  $HOME/Library/Services/Video to Slides GIF - Max.workflow

Notes:
  - Small = 800 px
  - Medium = 1200 px
  - Large = 1600 px
  - Max = 1920 px
  - Core CLI script remains available at:
    $PREFIX/video_to_slides_gif.sh
  - If the Quick Actions do not appear immediately, relaunch Finder once:
    /System/Library/CoreServices/pbs -flush
    /System/Library/CoreServices/pbs -update
    killall Finder
  - On first use, you may need Finder -> Quick Actions -> Customize... to enable:
    Video to Slides GIF - Small / Medium / Large / Max
  - macOS may ask for permission to access folders; allow access for the script or ffmpeg if prompted
EOF
