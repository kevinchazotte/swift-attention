#!/bin/bash
set -e

echo "=== Installing CocoaPods dependencies ==="

export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# Define Ruby version we need
RUBY_VERSION="3.2.2"

# Install rbenv if not already installed
if ! command -v rbenv >/dev/null 2>&1; then
    echo "Installing rbenv via git (skipping Homebrew due to Xcode Cloud network restrictions)..."

    # Clone rbenv if not already installed
    if [ ! -d "$HOME/.rbenv/.git" ]; then
        echo "Cloning rbenv..."
        if [ -d "$HOME/.rbenv" ]; then
            echo "Cleaning up incomplete rbenv installation..."
            rm -rf "$HOME/.rbenv"
        fi
        git clone https://github.com/rbenv/rbenv.git "$HOME/.rbenv"
    else
        echo "rbenv already installed"
    fi

    # Clone ruby-build if not already installed
    mkdir -p "$HOME/.rbenv/plugins"
    if [ ! -d "$HOME/.rbenv/plugins/ruby-build/.git" ]; then
        echo "Cloning ruby-build..."
        if [ -d "$HOME/.rbenv/plugins/ruby-build" ]; then
            echo "Cleaning up incomplete ruby-build installation..."
            rm -rf "$HOME/.rbenv/plugins/ruby-build"
        fi
        git clone https://github.com/rbenv/ruby-build.git "$HOME/.rbenv/plugins/ruby-build"
    else
        echo "ruby-build already installed"
    fi
fi

# Initialize rbenv
echo "Initializing rbenv..."
export PATH="$HOME/.rbenv/bin:$PATH"
export PATH="$HOME/.rbenv/shims:$PATH"
eval "$(rbenv init - bash)"

# Install Ruby if not already installed
if ! rbenv versions 2>/dev/null | grep -q "$RUBY_VERSION"; then
    echo "Installing Ruby $RUBY_VERSION..."
    RUBY_CONFIGURE_OPTS="--disable-install-doc --disable-install-rdoc" \
    MAKE_OPTS="-j$(sysctl -n hw.ncpu)" \
    rbenv install "$RUBY_VERSION"

    sudo chown -R $(whoami):staff "$HOME/.rbenv" 2>/dev/null || sudo chown -R $(whoami) "$HOME/.rbenv"
else
    echo "Ruby $RUBY_VERSION is already installed"
fi

# Set Ruby version
echo "Setting Ruby version to $RUBY_VERSION..."
rbenv global "$RUBY_VERSION"
rbenv rehash

# Ensure shims have proper permissions
sudo chown -R $(whoami):staff "$HOME/.rbenv/shims" 2>/dev/null || sudo chown -R $(whoami) "$HOME/.rbenv/shims"

# Verify Ruby version
echo "Ruby version: $(ruby --version)"
echo "Ruby path: $(which ruby)"

export GEM_HOME="$HOME/.gem"
export PATH="$GEM_HOME/bin:$PATH"

echo "Current Ruby version: $(ruby --version)"
echo "Current gem path: $(gem env home)"

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
