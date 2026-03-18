#!/usr/bin/env bash
set -euo pipefail

APP_NAME="Video to Slides GIF"
PACKAGE_ID="com.kevtice15.video-to-slides-gif"
INSTALL_ROOT="/usr/local/lib/video-to-slides-gif"
OUTPUT_DIR="$(pwd)/dist"
VERSION="${VERSION:-1.0.0}"

usage() {
  cat <<'USAGE'
Usage:
  ./build-pkg.sh [--output-dir DIR] [--version VERSION]

Options:
  --output-dir DIR   Directory for the built pkg (default: ./dist)
  --version VERSION  Package version (default: env VERSION or 1.0.0)
  -h, --help         Show this help
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --output-dir)
      OUTPUT_DIR="${2:-}"
      shift 2
      ;;
    --version)
      VERSION="${2:-}"
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

if [[ ! "$VERSION" =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$ ]]; then
  echo "Error: invalid package version: $VERSION" >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

PKG_ROOT="$TMP_DIR/pkgroot"
PKG_SCRIPTS="$TMP_DIR/scripts"
LIB_DIR="$PKG_ROOT$INSTALL_ROOT"
BIN_DIR="$PKG_ROOT/usr/local/bin"
PKG_PATH="$OUTPUT_DIR/video-to-slides-gif-${VERSION}.pkg"

mkdir -p "$LIB_DIR" "$BIN_DIR" "$PKG_SCRIPTS" "$OUTPUT_DIR"

cp "$SCRIPT_DIR/video_to_slides_gif.sh" "$LIB_DIR/video_to_slides_gif.sh"
cp "$SCRIPT_DIR/video_to_slides_gif_finder.sh" "$LIB_DIR/video_to_slides_gif_finder.sh"
cp "$SCRIPT_DIR/create_quick_action.sh" "$LIB_DIR/create_quick_action.sh"
cp "$SCRIPT_DIR/VIDEO_TO_SLIDES_GUIDE.md" "$LIB_DIR/VIDEO_TO_SLIDES_GUIDE.md"

cat > "$LIB_DIR/quick_action_small.zsh" <<'EOF'
#!/bin/zsh
VIDEO_TO_SLIDES_GIF_WIDTH="800" "/usr/local/lib/video-to-slides-gif/video_to_slides_gif_finder.sh" "$@"
EOF

cat > "$LIB_DIR/quick_action_medium.zsh" <<'EOF'
#!/bin/zsh
VIDEO_TO_SLIDES_GIF_WIDTH="1200" "/usr/local/lib/video-to-slides-gif/video_to_slides_gif_finder.sh" "$@"
EOF

cat > "$LIB_DIR/quick_action_large.zsh" <<'EOF'
#!/bin/zsh
VIDEO_TO_SLIDES_GIF_WIDTH="1600" "/usr/local/lib/video-to-slides-gif/video_to_slides_gif_finder.sh" "$@"
EOF

cat > "$LIB_DIR/quick_action_max.zsh" <<'EOF'
#!/bin/zsh
VIDEO_TO_SLIDES_GIF_WIDTH="1920" "/usr/local/lib/video-to-slides-gif/video_to_slides_gif_finder.sh" "$@"
EOF

chmod 755 \
  "$LIB_DIR/video_to_slides_gif.sh" \
  "$LIB_DIR/video_to_slides_gif_finder.sh" \
  "$LIB_DIR/create_quick_action.sh" \
  "$LIB_DIR/quick_action_small.zsh" \
  "$LIB_DIR/quick_action_medium.zsh" \
  "$LIB_DIR/quick_action_large.zsh" \
  "$LIB_DIR/quick_action_max.zsh"

ln -s ../lib/video-to-slides-gif/video_to_slides_gif.sh "$BIN_DIR/video-to-slides-gif"

cat > "$PKG_SCRIPTS/postinstall" <<'EOF'
#!/bin/zsh
set -euo pipefail

INSTALL_ROOT="/usr/local/lib/video-to-slides-gif"
CREATE_SCRIPT="$INSTALL_ROOT/create_quick_action.sh"

console_user="$(stat -f '%Su' /dev/console)"
if [[ -z "$console_user" || "$console_user" == "root" ]]; then
  echo "Installed scripts, but no logged-in user was detected for Quick Action setup."
  exit 0
fi

user_home="$(dscl . -read "/Users/$console_user" NFSHomeDirectory | awk '{print $2}')"
if [[ -z "$user_home" ]]; then
  echo "Installed scripts, but could not determine the home directory for $console_user."
  exit 0
fi

create_action() {
  local name="$1"
  local launcher="$2"
  local workflow_path="$user_home/Library/Services/${name}.workflow"

  "$CREATE_SCRIPT" --launcher "$launcher" --workflow-path "$workflow_path" --name "$name"
  chown -R "$console_user":staff "$workflow_path"
}

create_action "Video to Slides GIF - Small" "$INSTALL_ROOT/quick_action_small.zsh"
create_action "Video to Slides GIF - Medium" "$INSTALL_ROOT/quick_action_medium.zsh"
create_action "Video to Slides GIF - Large" "$INSTALL_ROOT/quick_action_large.zsh"
create_action "Video to Slides GIF - Max" "$INSTALL_ROOT/quick_action_max.zsh"

if [[ -x /System/Library/CoreServices/pbs ]]; then
  /System/Library/CoreServices/pbs -update >/dev/null 2>&1 || true
fi
EOF

chmod 755 "$PKG_SCRIPTS/postinstall"

pkgbuild \
  --root "$PKG_ROOT" \
  --scripts "$PKG_SCRIPTS" \
  --identifier "$PACKAGE_ID" \
  --version "$VERSION" \
  --install-location / \
  "$PKG_PATH"

echo "Built package:"
echo "  $PKG_PATH"
