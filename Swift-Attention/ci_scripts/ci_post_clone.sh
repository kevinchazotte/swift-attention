#!/bin/bash
set -e

echo "=== Installing CocoaPods dependencies ==="

export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# Initialize rbenv if it exists
if [ -d "$HOME/.rbenv" ]; then
    echo "Initializing rbenv..."
    export PATH="$HOME/.rbenv/bin:$PATH"
    export PATH="$HOME/.rbenv/shims:$PATH"
    if command -v rbenv >/dev/null 2>&1; then
        eval "$(rbenv init - bash)"
        echo "Ruby version: $(ruby --version)"
        echo "Ruby path: $(which ruby)"
    else
        echo "Warning: rbenv not found in PATH, using system Ruby"
    fi
else
    echo "rbenv not installed, using system Ruby"
fi

export GEM_HOME="$HOME/.gem"
export PATH="$GEM_HOME/bin:$PATH"

echo "Current Ruby version: $(ruby --version 2>&1 || echo 'Ruby not found')"
echo "Current gem path: $(gem env home 2>&1 || echo 'gem not found')"

echo "Installing CocoaPods..."
gem install cocoapods --no-document

# Navigate to directory with Podfile
cd "$(dirname "$0")/.."
echo "Current directory: $(pwd)"
ls -la Podfile 2>/dev/null || echo "ERROR: Podfile not found in $(pwd)"

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
