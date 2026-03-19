#!/usr/bin/env bash
set -euo pipefail

WORKFLOW_NAME="Video to Slides GIF"
WORKFLOW_PATH="$HOME/Library/Services/${WORKFLOW_NAME}.workflow"
LAUNCHER_PATH=""
TEMPLATE_DIR=""

xml_escape() {
  local value="${1:-}"
  value="${value//&/&amp;}"
  value="${value//</&lt;}"
  value="${value//>/&gt;}"
  value="${value//\"/&quot;}"
  value="${value//\'/&apos;}"
  printf '%s' "$value"
}

usage() {
  cat <<'USAGE'
Usage:
  ./create_quick_action.sh --launcher PATH --template-dir PATH [--workflow-path PATH] [--name NAME]

Options:
  --launcher PATH       Script or launcher that the Quick Action should run
  --template-dir PATH   Template workflow directory to copy and patch
  --workflow-path PATH  Destination workflow bundle path
  --name NAME           Quick Action display name
  -h, --help            Show this help
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --launcher)
      LAUNCHER_PATH="${2:-}"
      shift 2
      ;;
    --workflow-path)
      WORKFLOW_PATH="${2:-}"
      shift 2
      ;;
    --template-dir)
      TEMPLATE_DIR="${2:-}"
      shift 2
      ;;
    --name)
      WORKFLOW_NAME="${2:-}"
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

if [[ -z "$LAUNCHER_PATH" ]]; then
  echo "Error: --launcher is required." >&2
  exit 1
fi

if [[ ! -f "$LAUNCHER_PATH" ]]; then
  echo "Error: launcher does not exist: $LAUNCHER_PATH" >&2
  exit 1
fi

if [[ -z "$TEMPLATE_DIR" || ! -d "$TEMPLATE_DIR" ]]; then
  echo "Error: --template-dir must point to an existing template directory." >&2
  exit 1
fi

if [[ -z "$WORKFLOW_PATH" || "$WORKFLOW_PATH" == "/" ]]; then
  echo "Error: refusing unsafe workflow path: $WORKFLOW_PATH" >&2
  exit 1
fi

CONTENTS_DIR="$WORKFLOW_PATH/Contents"
INFO_PLIST="$CONTENTS_DIR/Info.plist"
DOCUMENT_WFLOW="$CONTENTS_DIR/document.wflow"
ESCAPED_NAME="$(xml_escape "$WORKFLOW_NAME")"

if ! command -v uuidgen >/dev/null 2>&1; then
  echo "Error: uuidgen is required to create the Quick Action bundle." >&2
  exit 1
fi

WORKFLOW_UUID="$(uuidgen)"
ACTION_UUID="$(uuidgen)"
INPUT_UUID="$(uuidgen)"
OUTPUT_UUID="$(uuidgen)"
COMMAND_STRING="\"$LAUNCHER_PATH\" \"\$@\""
ESCAPED_COMMAND_STRING="$(xml_escape "$COMMAND_STRING")"

rm -rf "$WORKFLOW_PATH"
mkdir -p "$WORKFLOW_PATH"
cp -R "$TEMPLATE_DIR"/. "$WORKFLOW_PATH"/

python3 - <<'PY' "$INFO_PLIST" "$DOCUMENT_WFLOW" "$WORKFLOW_NAME" "$ESCAPED_COMMAND_STRING" "$ACTION_UUID" "$INPUT_UUID" "$OUTPUT_UUID"
from pathlib import Path
import sys

info_path = Path(sys.argv[1])
document_path = Path(sys.argv[2])
workflow_name = sys.argv[3]
command_string = sys.argv[4]
action_uuid = sys.argv[5]
input_uuid = sys.argv[6]
output_uuid = sys.argv[7]

replacements = {
    "__WORKFLOW_NAME__": workflow_name,
    "__COMMAND_STRING__": command_string,
    "__ACTION_UUID__": action_uuid,
    "__INPUT_UUID__": input_uuid,
    "__OUTPUT_UUID__": output_uuid,
}

for path in (info_path, document_path):
    content = path.read_text()
    for old, new in replacements.items():
        content = content.replace(old, new)
    path.write_text(content)
PY

plutil -lint "$INFO_PLIST" >/dev/null
plutil -lint "$DOCUMENT_WFLOW" >/dev/null

echo "Created Quick Action:"
echo "  $WORKFLOW_PATH"
