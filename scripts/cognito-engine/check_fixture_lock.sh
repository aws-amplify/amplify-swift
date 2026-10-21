#!/bin/bash
#
# Copyright Amazon.com Inc. or its affiliates.
# All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#
# The golden-fixture lock: the Auth plugin's behaviour snapshots (stored format, G2; error catalogue, G4;
# log transcript, G5; keychain queries; configuration). No change
# may edit, add or delete a file under them, so `AMPLIFY_GENERATE_GOLDEN=1` regenerating one in place also
# fails here.
#
# What they record. Each tree was captured on the development branch with the plugin's own code, while the
# Cognito engine was moved out of the plugin step by step (scripts/cognito-engine/error_match_gate.sh):
# the stored format, the errors and the logs before the move; the keychain queries before the
# credential store moved; the configuration before its production change. The plugin fixes that ship
# with the engine move were already in, so the trees record the plugin as of the engine extraction (the
# re-pinned trees, as of their re-pin below), not as last released. A green run means no drift from that
# plugin. These fixtures hold deliberate differences from the released plugin, each a row of the pending
# release notes (RELEASE-NOTES-PENDING.md):
#   - GoldenStoredFormat/AWSMobileClient: `locked-keychain` (a failed legacy read keeps the legacy stores and
#     clears nothing) and `existing-session-present` (legacy data never overwrites a newer saved session);
#   - GoldenLogs: scenario 4's sign-out line masks the refresh token (re-pinned below);
#   - GoldenKeychainQueries (the released plugin has no keychain seam to record): sign-out and delete user also
#     clear the three AWSMobileClient services; the legacy migration reads the saved session first, never
#     writes over a saved login, keeps everything after a failed read, and clears the legacy services only
#     after all its reads, where the released plugin cleared each one right after reading it; the access-group
#     migration moves item by item; and the client default session's label item and interrupted sign-in
#     move and are removed with the plugin's login.
# The notes inside the fixture files ("Recorded at M2 step S0b", ...) are locked bytes too, so they keep the
# capture-time wording.
#
#   scripts/cognito-engine/check_fixture_lock.sh [head-ref] [base-ref]
#
# 1. Each locked directory's git tree at head-ref (default HEAD) must equal the tree hash pinned below,
#    whatever the base. A PR based on an older branch, or a merge into another branch, cannot claim an
#    exemption.
# 2. When base-ref is given, head-ref must not change this script or its workflow since its merge base with
#    base-ref (`git diff base-ref...head-ref`, so a change base-ref made after the branch point does not fail
#    a PR that never touched either file), so a PR that changes fixtures cannot also loosen this script. CI
#    runs the base branch's copy of this script, but a PR's own copy of the workflow decides whether it runs
#    at all, so a PR that edits the workflow to skip it is caught only by the admin review .github/CODEOWNERS
#    requires for both files (see .github/workflows/auth_golden_fixture_lock.yml).
#
# test_check_fixture_lock.sh runs this script in a scratch repository.
#
# Lifting the lock (a reviewed change that needs admin approval, see .github/CODEOWNERS) means editing a pinned hash
# below; `StoredFormatGoldenTests.pinnedManifestSHA256`, `LegacyMigrationGoldenTests.pinnedFilesSHA256`,
# `ErrorCatalogueSnapshotTests.pinnedCatalogueSHA256`, `LogTranscriptSnapshotTests.pinnedTranscriptSHA256`,
# `KeychainQueryParityTests.pinnedBaselineSHA256` and `ConfigurationGoldenTests.pinnedManifestSHA256` are the
# matching in-test pins, so the unit tests enforce the lock on their own. That PR fails this check by design
# (the base copy still has the old pins, and this script changed), so an admin merges it past the failure, and
# the push run of the merge on main fails once; the workflow's header has the steps.
set -euo pipefail

HEAD_REF="${1:-HEAD}"
BASE_REF="${2:-}"

# directory  pinned tree hash (git rev-parse <commit>:<directory>), at its capture commit except for these
# re-pins, each a reviewed plugin change:
#   - GoldenKeychainQueries: when the plugin's reader of the client's records was removed and the default
#     session's label item and interrupted sign-in started to move with the plugin's login, and to be cleared
#     from the access-group migration's destination; again when the plugin's deleting configuration change
#     also removed the old configuration's default-session items;
#   - GoldenConfiguration: the Gen1 and no-sign-in-redirect inputs added, every earlier file unchanged;
#   - GoldenLogs: the sign-out line's refresh token masked (security review).
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
            && ! git diff --quiet "$BASE_REF...$HEAD_REF" -- "$file"; then
            echo "error: $file changed; the lock's own script and workflow are locked too" >&2
            status=1
        fi
    done
fi
exit $status
