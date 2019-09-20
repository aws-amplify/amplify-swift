//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import AWSS3StoragePlugin
import Amplify

class StorageRequestUtilsGetterTests: XCTestCase {

    let testIdentityId = "TestIdentityId"
    let testTargetIdentityId = "TestTargetIdentityId"
    let testKey = "TestKey"
    let publicAccessLevel = StorageAccessLevel.public
    let protectedAccessLevel = StorageAccessLevel.protected
    let privateAccessLevel = StorageAccessLevel.private

    // MARK: GetServiceKey tests

    func testGetServiceKeyWithPublic() {
        let expected = publicAccessLevel.rawValue + "/" + testKey
        let result = StorageRequestUtils.getServiceKey(accessLevel: publicAccessLevel,
                                                       identityId: testIdentityId,
                                                       key: testKey,
                                                       targetIdentityId: nil)
        XCTAssertEqual(result, expected)
    }

    func testGetServiceKeyWithProtected() {
        let expected = protectedAccessLevel.rawValue + "/" + testIdentityId + "/" + testKey
        let result = StorageRequestUtils.getServiceKey(accessLevel: protectedAccessLevel,
                                                       identityId: testIdentityId,
                                                       key: testKey,
                                                       targetIdentityId: nil)
        XCTAssertEqual(result, expected)
    }

    func testGetServiceKeyWithPrivate() {
        let expected = privateAccessLevel.rawValue + "/" + testIdentityId + "/" + testKey
        let result = StorageRequestUtils.getServiceKey(accessLevel: privateAccessLevel,
                                                       identityId: testIdentityId,
                                                       key: testKey,
                                                       targetIdentityId: nil)
        XCTAssertEqual(result, expected)
    }

    func testGetServiceKeyWithPublicAndTargetIdentityId() {
        let expected = publicAccessLevel.rawValue + "/" + testKey
        let result = StorageRequestUtils.getServiceKey(accessLevel: publicAccessLevel,
                                                       identityId: testIdentityId,
                                                       key: testKey,
                                                       targetIdentityId: testTargetIdentityId)
        XCTAssertEqual(result, expected)
    }

    func testGetServiceKeyWithProtectedAndTargetIdentityId() {
        let expected = protectedAccessLevel.rawValue + "/" + testTargetIdentityId + "/" + testKey
        let result = StorageRequestUtils.getServiceKey(accessLevel: protectedAccessLevel,
                                                       identityId: testIdentityId,
                                                       key: testKey,
                                                       targetIdentityId: testTargetIdentityId)
        XCTAssertEqual(result, expected)
    }

    func testGetServiceKeywithPrivateAndTargetIdentityId() {
        let expected = privateAccessLevel.rawValue + "/" + testTargetIdentityId + "/" + testKey
        let result = StorageRequestUtils.getServiceKey(accessLevel: privateAccessLevel,
                                                       identityId: testIdentityId,
                                                       key: testKey,
                                                       targetIdentityId: testTargetIdentityId)
        XCTAssertEqual(result, expected)
    }

    // MARK: GetAccessLevelPrefix tests

    func testGetAccessLevelPrefixWithPublic() {
        let expected = publicAccessLevel.rawValue + "/"
        let result = StorageRequestUtils.getAccessLevelPrefix(accessLevel: publicAccessLevel,
                                                              identityId: testIdentityId,
                                                              targetIdentityId: nil)
        XCTAssertEqual(result, expected)
    }

    func testGetAccessLevelPrefixWithProtected() {
        let expected = protectedAccessLevel.rawValue + "/" + testIdentityId + "/"
        let result = StorageRequestUtils.getAccessLevelPrefix(accessLevel: protectedAccessLevel,
                                                              identityId: testIdentityId,
                                                              targetIdentityId: nil)
        XCTAssertEqual(result, expected)
    }

    func testGetAccessLevelPrefixWithPrivate() {
        let expected = privateAccessLevel.rawValue + "/" + testIdentityId + "/"
        let result = StorageRequestUtils.getAccessLevelPrefix(accessLevel: privateAccessLevel,
                                                              identityId: testIdentityId,
                                                              targetIdentityId: nil)
        XCTAssertEqual(result, expected)
    }

    func testGetAccessLevelPrefixWithPublicAndTargetIdentityId() {
        let expected = publicAccessLevel.rawValue + "/"
        let result = StorageRequestUtils.getAccessLevelPrefix(accessLevel: publicAccessLevel,
                                                              identityId: testIdentityId,
                                                              targetIdentityId: testTargetIdentityId)
        XCTAssertEqual(result, expected)
    }

    func testGetAccessLevelPrefixWithProtectedAndTargetIdentityId() {
        let expected = protectedAccessLevel.rawValue + "/" + testTargetIdentityId + "/"
        let result = StorageRequestUtils.getAccessLevelPrefix(accessLevel: protectedAccessLevel,
                                                              identityId: testIdentityId,
                                                              targetIdentityId: testTargetIdentityId)
        XCTAssertEqual(result, expected)
    }

    func testGetAccessLevelPrefixWithPrivateAndTargetIdentityId() {
        let expected = privateAccessLevel.rawValue + "/" + testTargetIdentityId + "/"
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

    func testGetSizeForFileUploadSourceReturnsSize() {
        let key = "testGetSizeForFileUploadSourceReturnsSize"
        let filePath = NSTemporaryDirectory() + key + ".tmp"
        let fileURL = URL(fileURLWithPath: filePath)
        FileManager.default.createFile(atPath: filePath, contents: key.data(using: .utf8), attributes: nil)
        let uploadSource = UploadSource.file(file: fileURL)
        let result = StorageRequestUtils.getSize(uploadSource)
        guard case let .success(size) = result else {
            XCTFail("Valid file should return success result")
            return
        }

        XCTAssertNotNil(size)
    }

    func testGetSizeForMissingFileReturnsError() {
        let fileURL = URL(fileURLWithPath: "path")
        let uploadSource = UploadSource.file(file: fileURL)
        let result = StorageRequestUtils.getSize(uploadSource)
        guard case let .failure(error) = result else {
            XCTFail("missing file should return error result")
            return
        }

        XCTAssertNotNil(error)
        XCTAssertTrue(error.errorDescription.contains(StorageErrorConstants.missingLocalFile.errorDescription))
    }

    func testGetSizeForDataReturnsSize() {
        let uploadSource = UploadSource.data(data: Data())
        let result = StorageRequestUtils.getSize(uploadSource)
        guard case let .success(size) = result else {
            XCTFail("Valid data should return success result")
            return
        }

        XCTAssertNotNil(size)
    }
}
