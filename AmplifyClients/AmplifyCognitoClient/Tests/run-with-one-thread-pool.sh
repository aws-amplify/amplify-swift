#!/bin/sh
#
# Copyright Amazon.com Inc. or its affiliates.
# All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#
# Runs AmplifyCognitoClient's unit tests with Swift's cooperative thread pool narrowed to one thread.
#
# The session core keeps blocking keychain calls off the cooperative pool so the restore bound can fire
# even when every cooperative thread is busy (see Sources/Core/SessionRecordIO.swift). With a one-thread
# pool, any blocking call that slips back onto the pool pins the only thread, and a bounded test such as
# SessionRestoreTests.testStalledRestoreSurfacesUnavailableAndRecovers hangs instead of passing. That hang
# is the regression this script exists to catch, so run it under a timeout.
#
# Usage, from the repository root:
#   swift build --build-tests --target AmplifyCognitoClientTests   # or any `swift test` run
#   AmplifyClients/AmplifyCognitoClient/Tests/run-with-one-thread-pool.sh
#
# LIBDISPATCH_COOPERATIVE_POOL_STRICT must be set before the test process starts, which is why this runs
# xctest directly rather than setting it from a test.

set -eu

bundle="${1:-.build/debug/AmplifyPackageTests.xctest}"
tests_dir="$(dirname "$0")/UnitTests"

suites=$(grep -h '^final class .*XCTestCase' "$tests_dir"/*.swift \
    | sed 's/final class \([A-Za-z0-9_]*\).*/AmplifyCognitoClientTests.\1/' \
    | paste -sd, -)

LIBDISPATCH_COOPERATIVE_POOL_STRICT=1 exec xcrun xctest -XCTest "$suites" "$bundle"
