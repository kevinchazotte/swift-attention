#!/bin/bash
echo "Installing CocoaPods dependencies..."
export GEM_HOME="$HOME/.gem"
export PATH="$GEM_HOME/bin:$PATH"
gem install cocoapods --no-document
pod install
