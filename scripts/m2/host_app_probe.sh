#!/bin/bash
# Copyright Amazon.com Inc. or its affiliates.
# All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# Type-checks the AuthHostApp integration files that reach plugin internals through `@testable`, from
# outside the SwiftPM package, as the host app's Xcode target compiles them.
#   scripts/m2/host_app_probe.sh    # after `swift build`
# The host app is an Xcode project, not a package target, so it is compiled without the package's
# `-package-name`: `package` declarations of the engine are not visible to it. This probe uses the plugin's
# own compile arguments (scripts/m2/digester_args.py), which carry no `-package-name` either, plus XCTest.
# It exits 1 and lists the errors if any file fails to type-check.
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
HOST="$ROOT/AmplifyPlugins/Auth/Tests/AuthHostApp/AuthIntegrationTests"
STUB="$(mktemp -d)/AWSAuthBaseTestStub.swift"
# The real base class needs the rest of the host app (its async wait helpers); the probed files need only
# the class and its two keychain access groups (copied from AWSAuthBaseTest.swift).
cat > "$STUB" <<'SWIFT'
import XCTest
class AWSAuthBaseTest: XCTestCase, @unchecked Sendable {
    let keychainAccessGroup = "94KV3E626L.com.aws.amplify.auth.AuthHostAppShared"
    let keychainAccessGroup2 = "94KV3E626L.com.aws.amplify.auth.AuthHostAppShared2"
}
SWIFT
FILES=(
    "$STUB"
    "$HOST/Helpers/AuthEnvironmentHelper.swift"
    "$HOST/Helpers/AuthSessionHelper.swift"
    "$HOST/CredentialStore/CredentialStoreConfigurationTests.swift"
)

args=()
while IFS= read -r line; do args+=("$line"); done < <(cd "$ROOT" && python3 scripts/m2/digester_args.py --with-target)
if [ "${#args[@]}" -eq 0 ]; then
    echo "error: no compile arguments for AWSCognitoAuthPlugin; build first" >&2
    exit 2
fi
platform="$(xcrun --show-sdk-platform-path)"
output="$(xcrun swiftc -typecheck -sdk "$(xcrun --show-sdk-path)" -swift-version 6 "${args[@]}" \
    -F "$platform/Developer/Library/Frameworks" -I "$platform/Developer/usr/lib" "${FILES[@]}" 2>&1)"
code=$?
errors="$(printf '%s\n' "$output" | grep -E '\.swift:[0-9]+:[0-9]+: error:' | sed -E 's/^.*\/([^/]+:[0-9]+):[0-9]+: error: /   \1: /' | sort -u)"
if [ $code -eq 0 ] && [ -z "$errors" ]; then
    echo "host-app probe: ${#FILES[@]} files type-check cleanly"
    exit 0
fi
echo "host-app probe FAILED:"
if [ -n "$errors" ]; then printf '%s\n' "$errors"; else printf '%s\n' "$output" | tail -20; fi
exit 1
