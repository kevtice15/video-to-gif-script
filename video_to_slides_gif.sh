#!/usr/bin/env bash
set -euo pipefail

# Finder/Automator runs with a minimal PATH. Add common Homebrew locations.
for bin_dir in /opt/homebrew/bin /opt/homebrew/sbin /usr/local/bin /usr/local/sbin; do
  if [[ -d "$bin_dir" && ":$PATH:" != *":$bin_dir:"* ]]; then
    PATH="$bin_dir:$PATH"
  fi
done
export PATH

show_help() {
  cat <<'USAGE'
Usage:
  video_to_slides_gif.sh [options] <input_video> [output.gif]

Creates an optimized GIF for Google Slides from a video.

Options:
  -s, --start TIME        Start time (e.g. 00:00:02.5)
  -d, --duration TIME     Duration (e.g. 5 or 00:00:05)
  -f, --fps FPS           Frames per second (default: 10)
  -w, --width PX          Output width in pixels (default: 800)
  -c, --colors N          Max colors (default: 128)
  --no-dither             Disable dithering (smaller, lower quality)
  --loop N                Loop count (default: 0 = infinite)
  --overwrite             Overwrite output path instead of auto-suffix fallback
  --verbose               Print ffmpeg logs and extra diagnostics
  -h, --help              Show this help
  -o, --output PATH       Output path (file or directory). Defaults to input dir.

Examples:
  video_to_slides_gif.sh input.mp4
  video_to_slides_gif.sh input.mp4 /tmp/out.gif
  video_to_slides_gif.sh -o /tmp input.mp4
  video_to_slides_gif.sh -s 00:00:03 -d 5 -f 12 -w 900 input.mov output.gif
USAGE
}

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Error: '$1' not found." >&2
    return 1
  }
}

need_value() {
  local opt="$1"
  local val="${2:-}"
  if [[ -z "$val" || "$val" == -* ]]; then
    echo "Error: option '$opt' requires a value." >&2
    exit 1
  fi
}

is_positive_int() {
  [[ "$1" =~ ^[1-9][0-9]*$ ]]
}

is_non_negative_int() {
  [[ "$1" =~ ^[0-9]+$ ]]
}

next_available_path() {
  local path="$1"
  local dir file stem ext candidate i

  if [[ ! -e "$path" ]]; then
    printf '%s\n' "$path"
    return
  fi

  dir=$(dirname "$path")
  file=$(basename "$path")
  stem="${file%.*}"
  ext=""
  if [[ "$file" == *.* ]]; then
    ext=".${file##*.}"
  fi

  i=1
  while :; do
    candidate="${dir}/${stem}_${i}${ext}"
    if [[ ! -e "$candidate" ]]; then
      printf '%s\n' "$candidate"
      return
    fi
    i=$((i + 1))
  done
}

# Defaults tuned for Google Slides: smaller, smooth enough, good quality
START=""
DURATION=""
FPS=10
WIDTH=800
COLORS=128
DITHER="bayer"
BAYER_SCALE=5
LOOP=0
OVERWRITE=0
VERBOSE=0
OUTPUT=""

ARGS=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    -s|--start)
      need_value "$1" "${2:-}"
      START="$2"
      shift 2
      ;;
    -d|--duration)
      need_value "$1" "${2:-}"
      DURATION="$2"
      shift 2
      ;;
    -f|--fps)
      need_value "$1" "${2:-}"
      FPS="$2"
      shift 2
      ;;
    -w|--width)
      need_value "$1" "${2:-}"
      WIDTH="$2"
      shift 2
      ;;
    -c|--colors)
      need_value "$1" "${2:-}"
      COLORS="$2"
      shift 2
      ;;
    -o|--output)
      need_value "$1" "${2:-}"
      OUTPUT="$2"
      shift 2
      ;;
    --no-dither) DITHER="none"; shift;;
    --loop)
      need_value "$1" "${2:-}"
      LOOP="$2"
      shift 2
      ;;
    --overwrite) OVERWRITE=1; shift;;
    --verbose) VERBOSE=1; shift;;
    -h|--help) show_help; exit 0;;
    --)
      shift
      ARGS+=("$@")
      break
      ;;
    -*) echo "Unknown option: $1" >&2; show_help; exit 1;;
    *) ARGS+=("$1"); shift;;
  esac
done

if [[ ${#ARGS[@]} -lt 1 ]]; then
  show_help
  exit 1
fi

INPUT=${ARGS[0]}
OUTPUT=${OUTPUT:-${ARGS[1]:-}}

if [[ ! -f "$INPUT" ]]; then
  echo "Error: input file not found: $INPUT" >&2
  exit 1
fi

if ! is_positive_int "$FPS"; then
  echo "Error: --fps must be a positive integer." >&2
  exit 1
fi

if ! is_positive_int "$WIDTH"; then
  echo "Error: --width must be a positive integer." >&2
  exit 1
fi

if ! is_positive_int "$COLORS"; then
  echo "Error: --colors must be a positive integer." >&2
  exit 1
fi

if ! is_non_negative_int "$LOOP"; then
  echo "Error: --loop must be a non-negative integer." >&2
  exit 1
fi

need_cmd ffmpeg || {
  echo "Install with: brew install ffmpeg" >&2
  exit 1
}

# Default output: same directory as input, same base name with .gif extension
if [[ -z "$OUTPUT" ]]; then
  INPUT_DIR=$(dirname "$INPUT")
  INPUT_FILE=$(basename "$INPUT")
  BASE_NAME="${INPUT_FILE%.*}"
  OUTPUT="$INPUT_DIR/${BASE_NAME}.gif"
elif [[ -d "$OUTPUT" ]]; then
  INPUT_FILE=$(basename "$INPUT")
  BASE_NAME="${INPUT_FILE%.*}"
  OUTPUT="${OUTPUT%/}/${BASE_NAME}.gif"
fi

OUTPUT_DIR=$(dirname "$OUTPUT")
mkdir -p "$OUTPUT_DIR"

if [[ "$OVERWRITE" -eq 0 ]]; then
  FINAL_OUTPUT="$OUTPUT"
  OUTPUT=$(next_available_path "$OUTPUT")
  if [[ "$OUTPUT" != "$FINAL_OUTPUT" ]]; then
    echo "Output exists. Writing to: $OUTPUT"
  fi
fi

TMP_DIR=$(mktemp -d)
PALETTE="$TMP_DIR/palette.png"
trap 'rm -rf "$TMP_DIR"' EXIT

FFMPEG_IN_ARGS=()
[[ -n "$START" ]] && FFMPEG_IN_ARGS+=( -ss "$START" )
FFMPEG_IN_ARGS+=( -i "$INPUT" )
[[ -n "$DURATION" ]] && FFMPEG_IN_ARGS+=( -t "$DURATION" )

# Build filter chain
SCALE="scale=${WIDTH}:-1:flags=lanczos"
FPS_FILTER="fps=${FPS}"

FFMPEG_LOGLEVEL="error"
if [[ "$VERBOSE" -eq 1 ]]; then
  FFMPEG_LOGLEVEL="warning"
  echo "Input:  $INPUT"
  echo "Output: $OUTPUT"
  echo "Config: fps=$FPS width=$WIDTH colors=$COLORS dither=$DITHER loop=$LOOP overwrite=$OVERWRITE"
fi

# Palette generation
ffmpeg -hide_banner -loglevel "$FFMPEG_LOGLEVEL" \
  "${FFMPEG_IN_ARGS[@]}" \
  -vf "$FPS_FILTER,$SCALE,palettegen=max_colors=${COLORS}:stats_mode=diff" \
  -y "$PALETTE"

# Apply palette with filter_complex (paletteuse needs 2 inputs)
if [[ "$DITHER" == "none" ]]; then
  PALETTEUSE="paletteuse=dither=none"
else
  PALETTEUSE="paletteuse=dither=${DITHER}:bayer_scale=${BAYER_SCALE}"
fi

ffmpeg -hide_banner -loglevel "$FFMPEG_LOGLEVEL" \
  "${FFMPEG_IN_ARGS[@]}" \
  -i "$PALETTE" \
  -filter_complex "[0:v]$FPS_FILTER,$SCALE[x];[x][1:v]$PALETTEUSE" \
  -loop "$LOOP" \
  -y "$OUTPUT"

# Optional post-optimization if gifsicle is available
if command -v gifsicle >/dev/null 2>&1; then
  gifsicle -O3 -b "$OUTPUT" >/dev/null 2>&1 || true
fi

echo "Wrote $OUTPUT"
