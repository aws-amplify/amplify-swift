#!/bin/bash
#
# Copyright Amazon.com Inc. or its affiliates.
# All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#
# The lock on AWSCognitoAuthPlugin's golden baselines. The stored-format (G2), error-catalogue (G4) and
# log-transcript (G5) baselines were captured once, before the Cognito engine moved out of the plugin, and no
# later change may edit, add or delete a file under them. G4 and G5 must be identical to base at every change,
# so `AMPLIFY_GENERATE_GOLDEN=1` regenerating them in place also fails here. The keychain query-parity
# baseline and the configuration golden were captured the same way and are locked the same way: every later
# change to the engine or the plugin must reproduce them exactly.
#
#   scripts/cognito-engine/check_fixture_lock.sh [head-ref] [base-ref]
#
# 1. Each locked directory's git tree at head-ref (default HEAD) must equal the tree hash pinned below,
#    whatever the base. A PR based on an older branch, or a merge into another branch, cannot claim an
#    exemption.
# 2. When base-ref is given, this script and its workflow must be unchanged between base-ref and head-ref,
#    so one PR cannot weaken the lock and change fixtures together. CI runs the base branch's copy of
#    this script (see .github/workflows/auth_golden_fixture_lock.yml).
#
# Lifting the lock (a reviewed change that needs admin approval, see .github/CODEOWNERS) means editing a pinned hash
# below; `StoredFormatGoldenTests.pinnedManifestSHA256`, `KeychainQueryParityTests.pinnedBaselineSHA256` and
# `ConfigurationGoldenTests.pinnedManifestSHA256` are the matching in-test pins.
set -euo pipefail

HEAD_REF="${1:-HEAD}"
BASE_REF="${2:-}"

# directory  pinned tree hash (git rev-parse <capture commit>:<directory>; GoldenLogs was re-pinned when the
# sign-out line's refresh token was masked, and GoldenKeychainQueries when the plugin's reader of the client's
# records was removed and the default session's sidecar and challenge began moving with the plugin's session, and
# again when the plugin's deleting configuration change began removing the old namespace's default-session sidecar
# and challenge)
LOCKED_TREES=(
    "AmplifyPlugins/Auth/Tests/AWSCognitoAuthPluginUnitTests/TestResources/GoldenStoredFormat 00adb7ec49b1c25ad64bea2e2e30bbd2d818ad1c"
    "AmplifyPlugins/Auth/Tests/AWSCognitoAuthPluginUnitTests/TestResources/GoldenErrors bd2e1e15435e04d3153beac98f8370729e8038d6"
    "AmplifyPlugins/Auth/Tests/AWSCognitoAuthPluginUnitTests/TestResources/GoldenLogs 14aefeb712286ee38af02d883a50f3bcc774a610"
    "AmplifyPlugins/Auth/Tests/AWSCognitoAuthPluginUnitTests/TestResources/GoldenKeychainQueries 68c9aaedba0002aed68630be394c9fabb1caa03e"
    "AmplifyPlugins/Auth/Tests/AWSCognitoAuthPluginUnitTests/TestResources/GoldenConfiguration 5f07437e77f8c64dfe7b3a83c598e4be7c2475b7"
)
SELF_FILES=(
    "scripts/cognito-engine/check_fixture_lock.sh"
    ".github/workflows/auth_golden_fixture_lock.yml"
)

cd "$(dirname "$0")/../.."
status=0
for entry in "${LOCKED_TREES[@]}"; do
    directory="${entry% *}"
    pinned="${entry##* }"
    actual="$(git rev-parse "$HEAD_REF:$directory" 2> /dev/null || echo missing)"
    if [ "$actual" != "$pinned" ]; then
        echo "error: $directory is locked (tree $pinned), but $HEAD_REF has $actual" >&2
        git diff --name-status "$pinned" "$HEAD_REF:$directory" 2> /dev/null | sed 's/^/  /' >&2 || true
        status=1
    else
        echo "fixture lock: $directory unchanged ($pinned)"
    fi
done
if [ -n "$BASE_REF" ]; then
    for file in "${SELF_FILES[@]}"; do
        if git cat-file -e "$BASE_REF:$file" 2> /dev/null \
            && ! git diff --quiet "$BASE_REF" "$HEAD_REF" -- "$file"; then
            echo "error: $file changed; the lock's own script and workflow are locked too" >&2
            status=1
        fi
    done
fi
exit $status
