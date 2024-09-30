#!/bin/bash

# Stop on any failed step of this script
set -eo pipefail

# Regenerates the SDK.  For use during development only.
# Arguments passed into this script are passed on to the manifest generator.

# May be used on Mac or Linux.
# When run on Mac, kills Xcode before codegen & restarts it after.

# Run this script from the SDK project root directory.

# If on Mac, quit Xcode so it doesn't get overwhelmed by source file changes.
if [ -x "$(command -v osascript)" ]; then
  osascript -e 'quit app "Xcode"'
fi

# Delete all previous Smithy build products
rm -rf codegen/sdk-codegen/build/smithyprojections/sdk-codegen/*

# Delete all previous staged code
rm -rf ServiceClients/*
rm -rf Sources/Services/*
rm -rf Tests/Services/*

# Regenerate code
./gradlew -p codegen/sdk-codegen build

# Move generated Swift code into place in the Sources/ dir
./gradlew -p codegen/sdk-codegen stageSdks

# Regenerate the package manifest and doc index, with args passed into this script
cd AWSSDKSwiftCLI
unset AWS_SWIFT_SDK_USE_LOCAL_DEPS
swift run AWSSDKSwiftCLI generate-package-manifest "$@" ..
swift run AWSSDKSwiftCLI generate-doc-index ..
cd ..

# If on Mac, open Xcode to the newly refreshed SDK
if [ -x "$(command -v osascript)" ]; then
  open -a Xcode
fi
