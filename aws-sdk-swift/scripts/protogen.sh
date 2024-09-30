#!/bin/bash

# Stop on any failed step of this script
set -eo pipefail

# This script may be used to regenerate protocol tests during development.

# May be used on Mac or Linux.
# When run on Mac, kills Xcode before codegen & restarts it after.

# Run this script from the SDK project's root dir.

# If on Mac, quit Xcode so it doesn't get overwhelmed by source file changes.
if [ -x "$(command -v osascript)" ]; then
  osascript -e 'quit app "Xcode"'
fi

# Delete the build products from any previous run of protocol tests.
rm -rf codegen/protocol-test-codegen/build
rm -rf codegen/protocol-test-codegen-local/build

# Regenerate protocol tests
./gradlew -p codegen/protocol-test-codegen build
./gradlew -p codegen/protocol-test-codegen-local build

# Delete the generated Package.swift for protocol test packages so they may be seen in Xcode
rm -f codegen/protocol-test-codegen/build/smithyprojections/protocol-test-codegen/aws-restjson/swift-codegen/Package.swift
rm -f codegen/protocol-test-codegen/build/smithyprojections/protocol-test-codegen/aws-restjson-validation/swift-codegen/Package.swift
rm -f codegen/protocol-test-codegen/build/smithyprojections/protocol-test-codegen/aws-json-10/swift-codegen/Package.swift
rm -f codegen/protocol-test-codegen/build/smithyprojections/protocol-test-codegen/aws-json-11/swift-codegen/Package.swift
rm -f codegen/protocol-test-codegen/build/smithyprojections/protocol-test-codegen/rest-xml/swift-codegen/Package.swift
rm -f codegen/protocol-test-codegen/build/smithyprojections/protocol-test-codegen/rest-xml-xmlns/swift-codegen/Package.swift
rm -f codegen/protocol-test-codegen/build/smithyprojections/protocol-test-codegen/ec2-query/swift-codegen/Package.swift
rm -f codegen/protocol-test-codegen/build/smithyprojections/protocol-test-codegen/aws-query/swift-codegen/Package.swift
rm -f codegen/protocol-test-codegen/build/smithyprojections/protocol-test-codegen/apigateway/swift-codegen/Package.swift
rm -f codegen/protocol-test-codegen/build/smithyprojections/protocol-test-codegen/glacier/swift-codegen/Package.swift
rm -f codegen/protocol-test-codegen/build/smithyprojections/protocol-test-codegen/machinelearning/swift-codegen/Package.swift
rm -f codegen/protocol-test-codegen/build/smithyprojections/protocol-test-codegen/s3/swift-codegen/Package.swift

# Now do the same for local protocol tests
rm -f codegen/protocol-test-codegen-local/build/smithyprojections/protocol-test-codegen-local/rest_json_extras/swift-codegen/Package.swift
rm -f codegen/protocol-test-codegen-local/build/smithyprojections/protocol-test-codegen-local/AwsQueryExtras/swift-codegen/Package.swift
rm -f codegen/protocol-test-codegen-local/build/smithyprojections/protocol-test-codegen-local/EventStream/swift-codegen/Package.swift
rm -f codegen/protocol-test-codegen-local/build/smithyprojections/protocol-test-codegen-local/RPCEventStream/swift-codegen/Package.swift
rm -f codegen/protocol-test-codegen-local/build/smithyprojections/protocol-test-codegen-local/Waiters/swift-codegen/Package.swift

# If on Mac, reopen Xcode to the refreshed tests
if [ -x "$(command -v osascript)" ]; then
  open -a Xcode codegen/
fi
