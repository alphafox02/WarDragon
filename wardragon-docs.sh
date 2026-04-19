#!/bin/bash
# WarDragon Documentation Viewer Launcher
# Opens the local HTML documentation in your default browser

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HTML_FILE="$SCRIPT_DIR/index.html"

if [ ! -f "$HTML_FILE" ]; then
    echo "Error: index.html not found at $HTML_FILE"
    exit 1
fi

# Open in default browser
if command -v xdg-open &>/dev/null; then
    xdg-open "file://$HTML_FILE"
elif command -v firefox &>/dev/null; then
    firefox "file://$HTML_FILE" &
elif command -v chromium-browser &>/dev/null; then
    chromium-browser "file://$HTML_FILE" &
elif command -v google-chrome &>/dev/null; then
    google-chrome "file://$HTML_FILE" &
else
    echo "No browser found. Open this file manually:"
    echo "  file://$HTML_FILE"
    exit 1
fi
