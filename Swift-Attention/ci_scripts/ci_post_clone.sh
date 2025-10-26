#!/bin/bash
set -e

echo "=== Installing CocoaPods dependencies ==="

# Initialize rbenv if it exists
if [ -d "$HOME/.rbenv" ]; then
    echo "Initializing rbenv..."
    export PATH="$HOME/.rbenv/bin:$PATH"
    export PATH="$HOME/.rbenv/shims:$PATH"
    eval "$(rbenv init -)"
    echo "Ruby version: $(ruby --version)"
    echo "Ruby path: $(which ruby)"
fi

export GEM_HOME="$HOME/.gem"
export PATH="$GEM_HOME/bin:$PATH"

# Install CocoaPods
echo "Installing CocoaPods..."
gem install cocoapods --no-document

# Navigate to directory with Podfile
cd Swift-Attention

# Run pod install
echo "Running pod install..."
pod install --verbose

# Verify workspace was created
echo "Verifying workspace..."
if [ -f "Swift-Attention.xcworkspace/contents.xcworkspacedata" ]; then
    echo "Workspace created successfully"
    cat Swift-Attention.xcworkspace/contents.xcworkspacedata
else
    echo "ERROR: Workspace not found!"
    exit 1
fi

echo "=== CocoaPods setup complete ==="
