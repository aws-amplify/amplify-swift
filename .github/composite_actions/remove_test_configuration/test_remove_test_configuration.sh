#!/bin/bash
#
# Copyright Amazon.com Inc. or its affiliates.
# All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#
# Self-test for remove_test_configuration.sh, over a fake build directory seeded with every file name the host
# apps' copy phases give the test configuration, beside files a build keeps:
#   - every configuration file is removed, every other file is kept, and the step passes;
#   - a configuration file the delete cannot remove fails the step, naming the file;
#   - a directory the step cannot search fails it;
#   - no build directory passes.
#
#   bash .github/composite_actions/remove_test_configuration/test_remove_test_configuration.sh
set -euo pipefail

SCRIPT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/remove_test_configuration.sh"
WORK="$(mktemp -d)"
cleanup() {
    chmod -R u+rwx "$WORK" 2> /dev/null || true
    rm -rf "$WORK"
}
trap cleanup EXIT

failures=0
fail() {
    echo "FAIL $1"
    failures=$((failures + 1))
}

PRODUCTS=Build/Build/Products/Debug-iphonesimulator
# One entry per file a copy phase puts into a bundle outside a testconfiguration/ directory.
CONFIGURATION_FILES=(
    "$PRODUCTS/PredictionsHostApp.app/amplifyconfiguration.json"
    "$PRODUCTS/PredictionsHostApp.app/PlugIns/AWSPredictionsPluginIntegrationTests.xctest/amplifyconfiguration.json"
    "$PRODUCTS/StorageHostApp.app/amplifyconfiguration.json"
    "$PRODUCTS/StorageHostApp.app/amplify_outputs.json"
    "$PRODUCTS/StorageHostApp.app/PlugIns/AWSS3StoragePluginIntegrationTests.xctest/amplifyconfiguration.json"
    "$PRODUCTS/StorageHostApp.app/PlugIns/AWSS3StoragePluginIntegrationTests.xctest/amplify_outputs.json"
    "$PRODUCTS/CognitoClientHostApp.app/PlugIns/AmplifyCognitoClientIntegrationTests.xctest/AWSCognitoAuthPluginIntegrationTests-amplify_outputs.json"
    "$PRODUCTS/CognitoClientHostApp.app/PlugIns/AmplifyCognitoClientIntegrationTests.xctest/AWSCognitoAuthPluginIntegrationTests-amplifyconfiguration.json"
    "$PRODUCTS/CognitoClientHostApp.app/PlugIns/AmplifyCognitoClientIntegrationTests.xctest/AWSCognitoAuthPluginIntegrationTests-credentials.json"
    "$PRODUCTS/CognitoClientHostApp.app/PlugIns/AmplifyCognitoClientIntegrationTests.xctest/AmplifyCognitoClientIntegrationTests-capabilities.json"
    "$PRODUCTS/CognitoClientHostApp.app/PlugIns/AmplifyCognitoClientIntegrationTests.xctest/cognito-client-integ-state.json"
    "$PRODUCTS/CognitoClientHostApp.app/PlugIns/AmplifyCognitoClientIntegrationTests.xctest/cognito-client-integ-users.json"
)
# The copies of the whole testconfiguration/ directory, with whatever the download holds.
CONFIGURATION_DIRECTORIES=(
    "$PRODUCTS/AuthHostApp.app/PlugIns/AuthIntegrationTests.xctest/testconfiguration"
    "$PRODUCTS/PushNotificationHostApp.app/testconfiguration"
)
# Files a build keeps.
KEPT_FILES=(
    "$PRODUCTS/PredictionsHostApp.app/Info.plist"
    "$PRODUCTS/PredictionsHostApp.app/PlugIns/AWSPredictionsPluginIntegrationTests.xctest/testImageText.jpg"
    "$PRODUCTS/StorageHostApp.app/StorageHostApp"
    "$PRODUCTS/CognitoClientHostApp.app/PlugIns/AmplifyCognitoClientIntegrationTests.xctest/Info.plist"
    "Build/Build/Intermediates.noindex/XCBuildData/build.db"
    "Build/SourcePackages/checkouts/aws-sdk-swift/Package.json"
)

seed() {
    rm -rf "$WORK/Build"
    local path
    for path in "${CONFIGURATION_FILES[@]}" "${KEPT_FILES[@]}"; do
        mkdir -p "$(dirname "$WORK/$path")"
        echo '{}' > "$WORK/$path"
    done
    for path in "${CONFIGURATION_DIRECTORIES[@]}"; do
        mkdir -p "$WORK/$path"
        echo '{}' > "$WORK/$path/AWSCognitoAuthPluginIntegrationTests-amplifyconfiguration.json"
        echo '{}' > "$WORK/$path/GoogleService-Info.plist"
    done
}

# Every configuration file and directory is removed, every other file is kept, and the step passes.
seed
before=$failures
if output="$(bash "$SCRIPT" "$WORK/Build" 2>&1)"; then
    echo "ok removal passes"
else
    fail "removal exited non-zero: $output"
fi
for path in "${CONFIGURATION_FILES[@]}" "${CONFIGURATION_DIRECTORIES[@]}"; do
    if [ -e "$WORK/$path" ]; then
        fail "still in the build: $path"
    fi
done
for path in "${KEPT_FILES[@]}"; do
    if [ ! -f "$WORK/$path" ]; then
        fail "a file the build keeps was removed: $path"
    fi
done
if [ "$failures" -eq "$before" ]; then
    echo "ok every configuration file removed, every other file kept"
fi

# Permissions do not stop root, so the next two cases need another user.
if [ "$(id -u)" -ne 0 ]; then
    # A configuration file the delete cannot remove fails the step, naming the file.
    seed
    locked="$PRODUCTS/PredictionsHostApp.app"
    chmod a-w "$WORK/$locked"
    if output="$(bash "$SCRIPT" "$WORK/Build" 2>&1)"; then
        fail "a configuration file left in the build passed: $output"
    elif [[ "$output" != *"::error::The test configuration is still in the build ($WORK/$locked/amplifyconfiguration.json)"* ]]; then
        fail "the error does not name the file left in the build: $output"
    else
        echo "ok a file left in the build fails, named"
    fi
    chmod u+w "$WORK/$locked"

    # A directory the step cannot search fails it.
    seed
    hidden="$PRODUCTS/StorageHostApp.app/PlugIns"
    chmod a-rx "$WORK/$hidden"
    if output="$(bash "$SCRIPT" "$WORK/Build" 2>&1)"; then
        fail "a directory the step cannot search passed: $output"
    elif [[ "$output" != *"::error::Could not search all of $WORK/Build"* ]]; then
        fail "the error does not say the search was incomplete: $output"
    else
        echo "ok a directory the step cannot search fails"
    fi
    chmod u+rx "$WORK/$hidden"
else
    echo "skipped the permission cases (running as root)"
fi

# No build directory passes.
if output="$(bash "$SCRIPT" "$WORK/no-such-build" 2>&1)" && [[ "$output" == "No build directory at "* ]]; then
    echo "ok no build directory passes"
else
    fail "no build directory: $output"
fi

if [ "$failures" -ne 0 ]; then
    echo "$failures failure(s)"
    exit 1
fi
echo "all remove_test_configuration.sh tests passed"
