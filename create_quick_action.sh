#!/usr/bin/env bash
set -euo pipefail

WORKFLOW_NAME="Video to Slides GIF"
WORKFLOW_PATH="$HOME/Library/Services/${WORKFLOW_NAME}.workflow"
LAUNCHER_PATH=""

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
  ./create_quick_action.sh --launcher PATH [--workflow-path PATH] [--name NAME]

Options:
  --launcher PATH       Script or launcher that the Quick Action should run
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

if [[ -z "$WORKFLOW_PATH" || "$WORKFLOW_PATH" == "/" ]]; then
  echo "Error: refusing unsafe workflow path: $WORKFLOW_PATH" >&2
  exit 1
fi

CONTENTS_DIR="$WORKFLOW_PATH/Contents"
INFO_PLIST="$CONTENTS_DIR/Info.plist"
DOCUMENT_WFLOW="$CONTENTS_DIR/document.wflow"
ESCAPED_NAME="$(xml_escape "$WORKFLOW_NAME")"
ESCAPED_LAUNCHER="$(xml_escape "$LAUNCHER_PATH")"

rm -rf "$WORKFLOW_PATH"
mkdir -p "$CONTENTS_DIR"

cat > "$INFO_PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>NSServices</key>
    <array>
        <dict>
            <key>NSMenuItem</key>
            <dict>
                <key>default</key>
                <string>${ESCAPED_NAME}</string>
            </dict>
            <key>NSMessage</key>
            <string>runWorkflowAsService</string>
            <key>NSRequiredContext</key>
            <dict/>
            <key>NSSendFileTypes</key>
            <array>
                <string>public.movie</string>
            </array>
        </dict>
    </array>
</dict>
</plist>
EOF

cat > "$DOCUMENT_WFLOW" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>AMApplicationBuild</key>
    <string>523</string>
    <key>AMApplicationVersion</key>
    <string>2.10</string>
    <key>AMDocumentVersion</key>
    <string>2</string>
    <key>actions</key>
    <array>
        <dict>
            <key>action</key>
            <dict>
                <key>AMAccepts</key>
                <dict>
                    <key>Container</key>
                    <string>List</string>
                    <key>Optional</key>
                    <true/>
                    <key>Types</key>
                    <array>
                        <string>com.apple.cocoa.string</string>
                    </array>
                </dict>
                <key>AMActionVersion</key>
                <string>2.0.3</string>
                <key>AMApplication</key>
                <array>
                    <string>Automator</string>
                </array>
                <key>AMBundleIdentifier</key>
                <string>com.apple.RunShellScript</string>
                <key>AMCategory</key>
                <array>
                    <string>AMCategoryUtilities</string>
                </array>
                <key>AMIconName</key>
                <string>Automator</string>
                <key>AMName</key>
                <string>Run Shell Script</string>
                <key>AMProvides</key>
                <dict>
                    <key>Container</key>
                    <string>List</string>
                    <key>Types</key>
                    <array>
                        <string>com.apple.cocoa.string</string>
                    </array>
                </dict>
                <key>ActionBundlePath</key>
                <string>/System/Library/Automator/Run Shell Script.action</string>
                <key>ActionName</key>
                <string>Run Shell Script</string>
                <key>ActionParameters</key>
                <dict>
                    <key>COMMAND_STRING</key>
                    <string>${ESCAPED_LAUNCHER}</string>
                    <key>CheckedForUserDefaultShell</key>
                    <true/>
                    <key>inputMethod</key>
                    <integer>1</integer>
                    <key>shell</key>
                    <string>/bin/zsh</string>
                    <key>source</key>
                    <string></string>
                </dict>
                <key>BundleIdentifier</key>
                <string>com.apple.RunShellScript</string>
                <key>CFBundleVersion</key>
                <string>2.0.3</string>
            </dict>
            <key>isViewVisible</key>
            <true/>
        </dict>
    </array>
    <key>connectors</key>
    <dict/>
    <key>workflowMetaData</key>
    <dict>
        <key>workflowTypeIdentifier</key>
        <string>com.apple.Automator.servicesMenu</string>
    </dict>
</dict>
</plist>
EOF

plutil -lint "$INFO_PLIST" >/dev/null
plutil -lint "$DOCUMENT_WFLOW" >/dev/null

echo "Created Quick Action:"
echo "  $WORKFLOW_PATH"
