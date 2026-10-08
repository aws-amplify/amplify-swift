//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

@testable import Amplify

// `@unchecked Sendable`: `XCTestCase` is not `Sendable`, but the test body is captured by the
// `@Sendable` closures the API now takes. XCTest runs one test at a time.
class StorageLegacyValueTests: XCTestCase, @unchecked Sendable {

    /// Test that the package mirror of `StorageAccessLevel` round-trips every case
    ///
    /// - Given: Each `LegacyStorageAccessLevel` case
    /// - When:
    ///    - It's converted to `StorageAccessLevel` and back
    /// - Then:
    ///    - The value and raw value are unchanged
    ///
    @available(*, deprecated, message: "Tests the deprecated access-level API")
    func testLegacyAccessLevel_roundTrip_isLossless() {
        for legacy in [LegacyStorageAccessLevel.guest, .protected, .private] {
            let accessLevel = StorageAccessLevel(legacy)
            XCTAssertEqual(accessLevel.rawValue, legacy.rawValue)
            XCTAssertEqual(accessLevel.legacyValue, legacy)
        }
    }

    /// Test that the deprecated request members return what the key-based initializers were given
    ///
    /// - Given: A key-based download request with a protected access level and a target identity
    /// - When:
    ///    - Its deprecated members are read
    /// - Then:
    ///    - They return the values passed in, which are also what the package storage holds
    ///
    @available(*, deprecated, message: "Tests the deprecated key-based API")
    func testKeyBasedRequest_deprecatedMembers_forwardToLegacyStorage() {
        let options = StorageDownloadDataRequest.Options(accessLevel: .protected, targetIdentityId: "identity")
        let request = StorageDownloadDataRequest(key: "key", options: options)

        XCTAssertEqual(request.key, "key")
        XCTAssertEqual(request.legacyKey, "key")
        XCTAssertEqual(request.options.accessLevel, .protected)
        XCTAssertEqual(request.options.legacyAccessLevel, .protected)
        XCTAssertEqual(request.options.targetIdentityId, "identity")
        XCTAssertEqual(request.options.legacyTargetIdentityId, "identity")
    }

    /// Test that path-based requests keep the defaults the deprecated members used to report
    ///
    /// - Given: A path-based download request and list options
    /// - When:
    ///    - Their deprecated members are read
    /// - Then:
    ///    - The key is empty, the access level is guest, and there's no target identity or path
    ///
    @available(*, deprecated, message: "Tests the deprecated key-based API")
    func testPathBasedRequest_deprecatedMembers_keepDefaults() {
        let request = StorageDownloadDataRequest(path: StringStoragePath.fromString("public/key"), options: .init())
        XCTAssertEqual(request.key, "")
        XCTAssertEqual(request.options.accessLevel, .guest)
        XCTAssertNil(request.options.targetIdentityId)

        let listOptions = StorageListRequest.Options()
        XCTAssertEqual(listOptions.accessLevel, .guest)
        XCTAssertNil(listOptions.targetIdentityId)
        XCTAssertNil(listOptions.path)
    }
}
