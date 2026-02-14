#!/bin/zsh
set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
EXT_DIR="$(dirname "$SCRIPT_DIR")"
COMPONENT="foo_jl_effects_dsp.component"
BUILD_DIR="$EXT_DIR/build/Release"
INSTALL_DIR="$HOME/Library/foobar2000-v2/user-components/foo_jl_effects_dsp"

if [ ! -d "$BUILD_DIR/$COMPONENT" ]; then
    echo "Error: Build not found at $BUILD_DIR/$COMPONENT"
    echo "Run ./Scripts/build.sh first"
    exit 1
fi

mkdir -p "$INSTALL_DIR"
rm -rf "$INSTALL_DIR/$COMPONENT"
cp -R "$BUILD_DIR/$COMPONENT" "$INSTALL_DIR/"
echo "Installed to $INSTALL_DIR/$COMPONENT"
