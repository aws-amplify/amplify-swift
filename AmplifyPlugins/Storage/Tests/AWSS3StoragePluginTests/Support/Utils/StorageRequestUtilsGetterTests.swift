//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import AWSS3StoragePlugin
import Amplify

class StorageRequestUtilsGetterTests: XCTestCase {

    let testIdentityId = "TestIdentityId"
    let testTargetIdentityId = "TestTargetIdentityId"
    let guestAccessLevel = StorageAccessLevel.guest
    let protectedAccessLevel = StorageAccessLevel.protected
    let privateAccessLevel = StorageAccessLevel.private

    // MARK: GetAccessLevelPrefix tests

    func testGetAccessLevelPrefixWithPublic() {
        let expected = guestAccessLevel.serviceAccessPrefix + "/"
        let result = StorageRequestUtils.getAccessLevelPrefix(accessLevel: guestAccessLevel,
                                                              identityId: testIdentityId,
                                                              targetIdentityId: nil)
        XCTAssertEqual(result, expected)
    }

    func testGetAccessLevelPrefixWithProtected() {
        let expected = protectedAccessLevel.serviceAccessPrefix + "/" + testIdentityId + "/"
        let result = StorageRequestUtils.getAccessLevelPrefix(accessLevel: protectedAccessLevel,
                                                              identityId: testIdentityId,
                                                              targetIdentityId: nil)
        XCTAssertEqual(result, expected)
    }

    func testGetAccessLevelPrefixWithPrivate() {
        let expected = privateAccessLevel.serviceAccessPrefix + "/" + testIdentityId + "/"
        let result = StorageRequestUtils.getAccessLevelPrefix(accessLevel: privateAccessLevel,
                                                              identityId: testIdentityId,
                                                              targetIdentityId: nil)
        XCTAssertEqual(result, expected)
    }

    func testGetAccessLevelPrefixWithPublicAndTargetIdentityId() {
        let expected = guestAccessLevel.serviceAccessPrefix + "/"
        let result = StorageRequestUtils.getAccessLevelPrefix(accessLevel: guestAccessLevel,
                                                              identityId: testIdentityId,
                                                              targetIdentityId: testTargetIdentityId)
        XCTAssertEqual(result, expected)
    }

    func testGetAccessLevelPrefixWithProtectedAndTargetIdentityId() {
        let expected = protectedAccessLevel.serviceAccessPrefix + "/" + testTargetIdentityId + "/"
        let result = StorageRequestUtils.getAccessLevelPrefix(accessLevel: protectedAccessLevel,
                                                              identityId: testIdentityId,
                                                              targetIdentityId: testTargetIdentityId)
        XCTAssertEqual(result, expected)
    }

    func testGetAccessLevelPrefixWithPrivateAndTargetIdentityId() {
        let expected = privateAccessLevel.serviceAccessPrefix + "/" + testTargetIdentityId + "/"
        let result = StorageRequestUtils.getAccessLevelPrefix(accessLevel: privateAccessLevel,
                                                              identityId: testIdentityId,
                                                              targetIdentityId: testTargetIdentityId)
        XCTAssertEqual(result, expected)
    }

    // MARK: GetServiceMetadata tests

    func testGetServiceMetadataConstructsMetadataKeysWithS3Prefix() {
        let metadata = ["key1": "value1", "key2": "value2"]
        let results = StorageRequestUtils.getServiceMetadata(metadata)
        XCTAssertNotNil(results)

        for (key, value) in results! {
            XCTAssertNotNil(key)
            XCTAssertNotNil(value)
            XCTAssertTrue(key.contains(StorageRequestUtils.metadataKeyPrefix))
        }
    }

    // MARK: GetSize tests

    func testGetSizeForFileUploadSourceReturnsSize() throws {
        let key = "testGetSizeForFileUploadSourceReturnsSize"
        let filePath = NSTemporaryDirectory() + key + ".tmp"
        let fileURL = URL(fileURLWithPath: filePath)
        FileManager.default.createFile(atPath: filePath, contents: key.data(using: .utf8), attributes: nil)
        let result = try StorageRequestUtils.getSize(fileURL)
        XCTAssertNotNil(result)
    }

    func testGetSizeForMissingFileReturnsError() {
        let fileURL = URL(fileURLWithPath: "path")

        XCTAssertThrowsError(try StorageRequestUtils.getSize(fileURL),
                             "GetSize for missing file should throw") { error in
            guard case StorageError.localFileNotFound = error else {
                XCTFail("Expected StorageError.StorageError")
                return
            }
        }
    }
}
