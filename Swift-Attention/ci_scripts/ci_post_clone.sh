#!/bin/bash
set -e

export RBENV_ROOT="$HOME/.rbenv"
export PATH="$RBENV_ROOT/bin:$PATH"
RUBY_VERSION="3.2.2"

cd "$(dirname "$0")/.."
echo "Current directory: $(pwd)"

echo "=== Installing User-Scoped Ruby ($RUBY_VERSION) via rbenv ==="

if [ ! -d "$RBENV_ROOT" ]; then
    echo "Cloning rbenv..."
    git clone https://github.com/rbenv/rbenv.git "$RBENV_ROOT"
    mkdir -p "$RBENV_ROOT/plugins"
    git clone https://github.com/rbenv/ruby-build.git "$RBENV_ROOT/plugins/ruby-build"
fi

# Initialize rbenv functions
eval "$(rbenv init -)"

if ! rbenv versions --bare | grep -q "$RUBY_VERSION"; then
    echo "Installing Ruby $RUBY_VERSION (This may take a few minutes)..."
    RUBY_CONFIGURE_OPTS="--disable-install-doc --disable-install-rdoc" \
    MAKE_OPTS="-j$(sysctl -n hw.ncpu)" \
    rbenv install "$RUBY_VERSION"
fi

echo "Setting local Ruby version to $RUBY_VERSION"
rbenv local "$RUBY_VERSION"

export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export RUBYOPT="-rlogger"

echo "Using rbenv Ruby: $(ruby --version)"
echo "Which Ruby: $(which ruby)"
echo "Current LANG: $LANG"

echo "=== Installing CocoaPods dependencies ==="

# Define GEM_HOME for the current user's Ruby installation
export GEM_HOME="$(rbenv prefix)/lib/ruby/gems/$RUBY_VERSION"
export PATH="$GEM_HOME/bin:$PATH"

echo "Verifying Ruby version: $(ruby --version)"
echo "Which Ruby: $(which ruby)"

# Install Bundler (ensuring it uses the rbenv-installed Ruby)
if ! command -v bundle >/dev/null 2>&1; then
    echo "Installing bundler..."
    gem install bundler --no-document
fi

echo "Installing gems via Bundler..."
# This command installs gems into vendor/bundle, which the build user owns
bundle config set --local path 'vendor/bundle'
bundle install

echo "Running pod install via Bundler..."
# This will now use the latest CocoaPods (1.15.2) and the working Ruby 3.2.2
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