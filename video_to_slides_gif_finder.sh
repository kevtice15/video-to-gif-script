#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONVERTER="$SCRIPT_DIR/video_to_slides_gif.sh"
WIDTH="${VIDEO_TO_SLIDES_GIF_WIDTH:-1200}"
SIZE_LABEL="${VIDEO_TO_SLIDES_GIF_LABEL:-}"
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

log "Quick Action start width=${WIDTH:-original} label=${SIZE_LABEL:-none} args=$#"
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
  stem="${base_name%.*}"
  output_path=""
  log "Processing file in directory: $output_dir"

  if [[ -n "$SIZE_LABEL" ]]; then
    output_path="${output_dir}/${stem}_${SIZE_LABEL}.gif"
  fi

  if [[ -n "$WIDTH" ]]; then
    if [[ -n "$output_path" ]]; then
      if "$CONVERTER" --verbose -w "$WIDTH" "$input" "$output_path" >>"$LOG_FILE" 2>&1; then
        log "SUCCESS width=$WIDTH label=${SIZE_LABEL:-none} input=$input output=$output_path"
        notify "Finished: ${stem}_${SIZE_LABEL}.gif"
      else
        log "ERROR conversion failed width=$WIDTH label=${SIZE_LABEL:-none} input=$input output=$output_path"
        notify "Conversion failed. Check ~/Library/Logs/video-to-slides-gif/finder.log"
        exit 1
      fi
    elif "$CONVERTER" --verbose -w "$WIDTH" "$input" >>"$LOG_FILE" 2>&1; then
      log "SUCCESS width=$WIDTH label=${SIZE_LABEL:-none} input=$input"
      notify "Finished: ${base_name%.*}.gif"
    else
      log "ERROR conversion failed width=$WIDTH label=${SIZE_LABEL:-none} input=$input"
      notify "Conversion failed. Check ~/Library/Logs/video-to-slides-gif/finder.log"
      exit 1
    fi
  else
    if [[ -n "$output_path" ]]; then
      if "$CONVERTER" --verbose "$input" "$output_path" >>"$LOG_FILE" 2>&1; then
        log "SUCCESS width=original label=${SIZE_LABEL:-none} input=$input output=$output_path"
        notify "Finished: ${stem}_${SIZE_LABEL}.gif"
      else
        log "ERROR conversion failed width=original label=${SIZE_LABEL:-none} input=$input output=$output_path"
        notify "Conversion failed. Check ~/Library/Logs/video-to-slides-gif/finder.log"
        exit 1
      fi
    elif "$CONVERTER" --verbose "$input" >>"$LOG_FILE" 2>&1; then
      log "SUCCESS width=original label=${SIZE_LABEL:-none} input=$input"
      notify "Finished: ${base_name%.*}.gif"
    else
      log "ERROR conversion failed width=original label=${SIZE_LABEL:-none} input=$input"
      notify "Conversion failed. Check ~/Library/Logs/video-to-slides-gif/finder.log"
      exit 1
    fi
  fi
done
