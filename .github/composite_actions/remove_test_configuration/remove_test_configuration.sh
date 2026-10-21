#!/bin/bash
#
# Copyright Amazon.com Inc. or its affiliates.
# All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#
# Deletes the integration-test configuration from a build (DerivedData) directory, then fails if any of it is
# still there, so the caller does not cache that build. See action.yml for why.
#
#   remove_test_configuration.sh <build-path>
#
# A failed delete is not fatal by itself: the check that follows looks for every name the deletes cover, and
# fails on whatever is left, or when it cannot search the whole directory.
# test_remove_test_configuration.sh runs this over a fake build directory.
set -uo pipefail

BUILD_PATH="${1:?usage: remove_test_configuration.sh <build-path>}"

if [ ! -d "$BUILD_PATH" ]; then
    echo "No build directory at $BUILD_PATH."
    exit 0
fi

# The names the host apps' copy phases give the configuration files outside a testconfiguration/ directory:
#   - the Cognito client's apps copy the plugin's files by name (<suite>-amplify_outputs.json,
#     <suite>-amplifyconfiguration.json, <suite>-credentials.json, <suite>-capabilities.json) into the bundle's
#     resources, and clear the retired amplify_outputs.json and cognito-client-integ-*.json;
#   - the Predictions and Storage apps copy theirs into the source root as amplifyconfiguration.json (Storage
#     also as amplify_outputs.json), which Copy Bundle Resources puts into the app and test bundles.
CONFIGURATION_NAMES=(
    '*-credentials.json'
    '*-amplify_outputs.json'
    '*-amplifyconfiguration.json'
    '*-capabilities.json'
    'amplify_outputs.json'
    'amplifyconfiguration.json'
    'cognito-client-integ-*.json'
)
name_test=()
for name in "${CONFIGURATION_NAMES[@]}"; do
    if [ ${#name_test[@]} -gt 0 ]; then
        name_test+=(-o)
    fi
    name_test+=(-name "$name")
done

find "$BUILD_PATH" -type d -name testconfiguration -prune -exec rm -rf {} + || true
find "$BUILD_PATH" -type f \( "${name_test[@]}" \) -delete || true

left="$(find "$BUILD_PATH" \( -type d -name testconfiguration -o -type f \( "${name_test[@]}" \) \) -print)"
search_status=$?
if [ -n "$left" ]; then
    echo "::error::The test configuration is still in the build (${left%%$'\n'*}); the build is not cached."
    exit 1
fi
if [ "$search_status" -ne 0 ]; then
    echo "::error::Could not search all of $BUILD_PATH for the test configuration; the build is not cached."
    exit 1
fi
echo "Removed the test configuration from $BUILD_PATH."
