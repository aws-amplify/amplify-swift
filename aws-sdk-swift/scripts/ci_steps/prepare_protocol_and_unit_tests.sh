#!/bin/bash

set -e

# Get rid of the generated services
rm -rf Sources/Services/*

# Regenerate the SDK manifest, with only runtime included
cd AWSSDKSwiftCLI
swift run AWSSDKSwiftCLI generate-package-manifest ..
cd ..

# Dump the Package.swift contents to the logs
cat Package.swift

# Code-generate protocol tests
./gradlew -p codegen/smithy-aws-swift-codegen build
./gradlew -p codegen/protocol-test-codegen build
./gradlew -p codegen/protocol-test-codegen-local build
./gradlew --stop

# Run aws-sdk-swift protocol and unit tests as a separate step
# (allows for use of either Xcode or pure Swift toolchains)
