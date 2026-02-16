#!/bin/zsh
set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
EXT_DIR="$(dirname "$SCRIPT_DIR")"
cd "$EXT_DIR"
PROJECT_FILE=$(ls -d *.xcodeproj 2>/dev/null | head -1)
if [ -z "$PROJECT_FILE" ]; then
    echo "Error: No Xcode project found. Run generate_xcode_project.rb first."
    exit 1
fi
xcodebuild -project "$PROJECT_FILE" -configuration Release build SYMROOT="$EXT_DIR/build"
