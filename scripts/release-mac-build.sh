#!/bin/bash

# Build a universal release for publishing on Mac. Only works on Macs.
# Assumes that TAG_NAME is in the forma "$BINARY_NAME-version",
# e.g. sunshowers-test-binary-release-0.1.0.
# Outputs an archive under the output parameter "archive-name"

set -e -o pipefail

BINARY_NAME="$1"
TAG_NAME="$2"

VERSION=${TAG_NAME#"$BINARY_NAME"}

echo "SDK version: "
xcrun --show-sdk-version
echo "SDK path: "
xcrun --show-sdk-path
echo "Platform version: "
xcrun --show-sdk-platform-version

# Parameters to use
CROSSBUILD_MACOS_SDK="macosx12.1"

export CARGO_PROFILE_RELEASE_LTO=true

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

ARCHIVE_NAME="$BINARY_NAME-$VERSION-universal-apple-darwin.tar.gz"
# Use gtar on Mac because Mac's tar is broken: https://github.com/actions/cache/issues/403
gtar acf "$ARCHIVE_NAME" "target/$BINARY_NAME"

echo "::set-output name=archive-name::$ARCHIVE_NAME"
