#!/bin/bash
set -e

echo "=============================="
echo "  NotchClick Setup"
echo "=============================="

# Check Xcode
if ! xcode-select -p &>/dev/null; then
    echo "Xcode Command Line Tools not found. Installing..."
    xcode-select --install
    echo "Please re-run this script after installation."
    exit 1
fi

# Check Homebrew
if ! command -v brew &>/dev/null; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Check XcodeGen
if ! command -v xcodegen &>/dev/null; then
    echo "Installing XcodeGen..."
    brew install xcodegen
fi

echo ""
echo "Generating Xcode project..."
xcodegen generate

echo ""
echo "Done! Opening in Xcode..."
open NotchClick.xcodeproj

echo ""
echo "=============================="
echo "  Build Steps"
echo "=============================="
echo "1. In Xcode, select your Team in Signing & Capabilities"
echo "2. Set deployment target to macOS 13.0+"
echo "3. Cmd+R to build and run"
echo ""
echo "Required Permissions (will be asked on first run):"
echo "  - Apple Events (Spotify control)"
