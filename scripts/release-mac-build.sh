#!/bin/bash

# Build a universal release for publishing on Mac. Only works on Macs.
# Assumes that TAG_NAME is in the forma "$BINARY_NAME-version",
# e.g. sunshowers-test-binary-release-0.1.0.
# Outputs a file by the name "$BINARY_NAME-apple-darwin.tar.gz"

set -e -o pipefail

BINARY_NAME="$1"
TAG_NAME="$2"

VERSION=${TAG_NAME#"$BINARY_NAME"}

export CARGO_PROFILE_RELEASE_LTO=1

targets="aarch64-apple-darwin x86_64-apple-darwin"
for target in $targets; do
  rustup target add $target
  # From: https://stackoverflow.com/a/66875783/473672
  SDKROOT=$(xcrun -sdk $CROSSBUILD_MACOS_SDK --show-sdk-path) \
  MACOSX_DEPLOYMENT_TARGET=$(xcrun -sdk $CROSSBUILD_MACOS_SDK --show-sdk-platform-version) \
    cargo build --release "--target=$target"
done

# From: https://developer.apple.com/documentation/apple-silicon/building-a-universal-macos-binary#Update-the-Architecture-List-of-Custom-Makefiles
lipo -create \
  -output "target/$BINARY_NAME" \
  "target/aarch64-apple-darwin/release/$BINARY_NAME" \
  "target/x86_64-apple-darwin/release/$BINARY_NAME"

# Use gtar on Mac because Mac's tar is broken: https://github.com/actions/cache/issues/403
gtar acf "$BINARY_NAME-apple-darwin.tar.gz" "target/$BINARY_NAME"
