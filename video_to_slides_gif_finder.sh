#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONVERTER="$SCRIPT_DIR/video_to_slides_gif.sh"
WIDTH="${VIDEO_TO_SLIDES_GIF_WIDTH:-1200}"
LOG_DIR="${HOME}/Library/Logs/video-to-slides-gif"
LOG_FILE="${LOG_DIR}/finder.log"
STDIN_CAPTURE=""
INPUTS=()

mkdir -p "$LOG_DIR"

timestamp() {
  date '+%Y-%m-%d %H:%M:%S'
}

log() {
  printf '[%s] %s\n' "$(timestamp)" "$*" >>"$LOG_FILE"
}

notify() {
  local message="$1"
  if command -v osascript >/dev/null 2>&1; then
    osascript -e "display notification \"${message//\"/\\\"}\" with title \"Video to Slides GIF\"" >/dev/null 2>&1 || true
  fi
}

log "Quick Action start width=${WIDTH:-original} args=$#"
log "PWD=${PWD}"
log "PATH=${PATH}"

for arg in "$@"; do
  INPUTS+=("$arg")
done

if [[ ${#INPUTS[@]} -eq 0 ]]; then
  STDIN_CAPTURE="$(cat || true)"
  if [[ -n "$STDIN_CAPTURE" ]]; then
    log "STDIN raw:"
    while IFS= read -r line; do
      log "  $line"
      [[ -n "$line" ]] && INPUTS+=("$line")
    done <<<"$STDIN_CAPTURE"
  else
    log "STDIN raw: <empty>"
  fi
fi

if [[ ! -x "$CONVERTER" ]]; then
  log "ERROR converter missing: $CONVERTER"
  notify "Converter script is missing."
  echo "Error: converter script is missing or not executable: $CONVERTER" >&2
  exit 1
fi

if [[ ${#INPUTS[@]} -eq 0 ]]; then
  log "ERROR no files selected"
  notify "No files were selected."
  echo "No files selected in Finder." >&2
  exit 1
fi

for input in "${INPUTS[@]}"; do
  log "Selected input: $input"
  if [[ ! -f "$input" ]]; then
    log "Skipping non-file: $input"
    echo "Skipping non-file: $input" >&2
    continue
  fi

  output_dir="$(dirname "$input")"
  base_name="$(basename "$input")"
  log "Processing file in directory: $output_dir"

  # Do not pass explicit output:
  # converter defaults to input directory + same basename + .gif,
  # while preserving conflict fallback naming.
  if [[ -n "$WIDTH" ]]; then
    if "$CONVERTER" --verbose -w "$WIDTH" "$input" >>"$LOG_FILE" 2>&1; then
      log "SUCCESS width=$WIDTH input=$input"
      notify "Finished: ${base_name%.*}.gif"
    else
      log "ERROR conversion failed width=$WIDTH input=$input"
      notify "Conversion failed. Check ~/Library/Logs/video-to-slides-gif/finder.log"
      exit 1
    fi
  else
    if "$CONVERTER" --verbose "$input" >>"$LOG_FILE" 2>&1; then
      log "SUCCESS width=original input=$input"
      notify "Finished: ${base_name%.*}.gif"
    else
      log "ERROR conversion failed width=original input=$input"
      notify "Conversion failed. Check ~/Library/Logs/video-to-slides-gif/finder.log"
      exit 1
    fi
  fi
done
