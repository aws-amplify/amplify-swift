#!/bin/bash

set -e

# Delete all generated services & their tests
rm -rf Sources/Services/*
rm -rf Tests/Services/*

# Code-generate and stage the SDK, then shut down Gradle
./gradlew -p codegen/sdk-codegen build
./gradlew -p codegen/sdk-codegen stageSdks
./gradlew --stop

# Regenerate the SDK Package.swift with all services
cd AWSSDKSwiftCLI
swift run AWSSDKSwiftCLI generate-package-manifest ..
cd ..

# Dump the Package.swift contents to the logs
cat Package.swift

# Run aws-sdk-swift unit tests as a separate step
# (allows for use of either Xcode or pure Swift toolchains)
