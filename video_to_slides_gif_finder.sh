#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONVERTER="$SCRIPT_DIR/video_to_slides_gif.sh"
WIDTH="${VIDEO_TO_SLIDES_GIF_WIDTH:-1200}"

if [[ ! -x "$CONVERTER" ]]; then
  echo "Error: converter script is missing or not executable: $CONVERTER" >&2
  exit 1
fi

if [[ $# -eq 0 ]]; then
  echo "No files selected in Finder." >&2
  exit 1
fi

for input in "$@"; do
  if [[ ! -f "$input" ]]; then
    echo "Skipping non-file: $input" >&2
    continue
  fi

  # Do not pass explicit output:
  # converter defaults to input directory + same basename + .gif,
  # while preserving conflict fallback naming.
  if [[ -n "$WIDTH" ]]; then
    "$CONVERTER" -w "$WIDTH" "$input"
  else
    "$CONVERTER" "$input"
  fi
done
