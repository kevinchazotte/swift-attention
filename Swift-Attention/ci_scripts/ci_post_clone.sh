#!/bin/bash
set -e

echo "=== Installing CocoaPods dependencies ==="

export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

echo "Using system Ruby: $(ruby --version)"
echo "Gem path: $(gem env home)"

cd "$(dirname "$0")/.."
echo "Current directory: $(pwd)"

if ! command -v bundle >/dev/null 2>&1; then
    echo "Installing bundler..."
    gem install bundler --no-document
fi

echo "Installing gems via Bundler..."
bundle install

echo "Running pod install via Bundler..."
bundle exec pod install --verbose

echo "Verifying workspace..."
if [ -f "Swift-Attention.xcworkspace/contents.xcworkspacedata" ]; then
    echo "Workspace created successfully"
    cat Swift-Attention.xcworkspace/contents.xcworkspacedata
else
    echo "ERROR: Workspace not found!"
    exit 1
fi

echo "=== CocoaPods setup complete ==="
