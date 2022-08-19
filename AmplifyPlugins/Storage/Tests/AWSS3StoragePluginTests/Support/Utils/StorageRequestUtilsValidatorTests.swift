//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import AWSS3StoragePlugin
import Amplify

class StorageRequestUtilsValidatorTests: XCTestCase {

    let testIdentityId = "TestIdentityId"
    let testTargetIdentityId = "TestTargetIdentityId"
    let testKey = "TestKey"
    let testPath = "TestPath"
    let testContentType = "TestContentType"

    // MARK: ValidateTargetIdentityId tests

    func testValidateTargetIdentityIdForEmptyTargetIdentityIdSuccess() {
        let result = StorageRequestUtils.validateTargetIdentityId(nil, accessLevel: .guest)
        XCTAssertNil(result)
    }

    func testValidateTargetIdentityIdWithPublicAccessLevelReturnsError() {
        let result = StorageRequestUtils.validateTargetIdentityId(testIdentityId, accessLevel: .guest)
        XCTAssertNotNil(result)
        XCTAssertTrue(result!
            .errorDescription
            .contains(StorageErrorConstants.invalidAccessLevelWithTarget.errorDescription))
    }

    func testValidateTargetIdentityIdWithProtectedAccessLevelSuccess() {
        let result = StorageRequestUtils.validateTargetIdentityId(testIdentityId, accessLevel: .protected)
        XCTAssertNil(result)
    }

    func testValidateTargetIdentityIdWithPrivateAccessLevelReturnsError() {
        let result = StorageRequestUtils.validateTargetIdentityId(testIdentityId, accessLevel: .private)
        XCTAssertNotNil(result)
        XCTAssertTrue(result!
            .errorDescription
            .contains(StorageErrorConstants.invalidAccessLevelWithTarget.errorDescription))
    }

    func testValidateTargetIdentityIdForEmpyTargetIdReturnsError() {
        let result = StorageRequestUtils.validateTargetIdentityId("", accessLevel: .guest)
        XCTAssertNotNil(result)
        XCTAssertTrue(result!.errorDescription.contains(StorageErrorConstants.identityIdIsEmpty.errorDescription))
    }

    // MARK: ValidateKey tests

    func testValidateKeySuccess() {
        let result = StorageRequestUtils.validateKey(testKey)
        XCTAssertNil(result)
    }

    func testValidateKeyForEmptyKeyReturnsError() {
        let result = StorageRequestUtils.validateKey("")
        XCTAssertNotNil(result)
        XCTAssertTrue(result!.errorDescription.contains(StorageErrorConstants.keyIsEmpty.errorDescription))
    }

    // MARK: ValidatePath tests

    func testValidatePathSuccess() {
        let result = StorageRequestUtils.validatePath(testPath)
        XCTAssertNil(result)
    }

    func testValidatePathForEmptyPathReturnsError() {
        let result = StorageRequestUtils.validatePath("")
        XCTAssertNotNil(result)
        XCTAssertTrue(result!.errorDescription.contains(StorageErrorConstants.pathIsEmpty.errorDescription))
    }

    // MARK: ValidateContentType tests

    func testValidateContentTypeSuccess() {
        let result = StorageRequestUtils.validateContentType(testContentType)
        XCTAssertNil(result)
    }

    func testValidateContentTypeForEmptyContentTypeReturnsError() {
        let result = StorageRequestUtils.validateContentType("")
        XCTAssertNotNil(result)
        XCTAssertTrue(result!.errorDescription.contains(StorageErrorConstants.contentTypeIsEmpty.errorDescription))
    }

    // MARK: ValidateMetadata tests

    func testValidateMetadataSuccess() {
        let metadata = ["key1": "value1", "key2": "value2"]
        let result = StorageRequestUtils.validateMetadata(metadata)
        XCTAssertNil(result)
    }

    func testValidateMetadataWithNonLowercasedKeysReturnsError() {
        let metadata = ["NonLowerCasedKey": "value1"]
        let result = StorageRequestUtils.validateMetadata(metadata)
        XCTAssertNotNil(result)
        XCTAssertTrue(result!.errorDescription.contains(StorageErrorConstants.metadataKeysInvalid.errorDescription))
    }

    // MARK: ValidateFileExists tests

    func testValidateFileExistsForUrlSuccess() {
        let key = "testValidateFileExistsForUrlSuccess"
        let filePath = NSTemporaryDirectory() + key + ".tmp"
        let fileURL = URL(fileURLWithPath: filePath)
        FileManager.default.createFile(atPath: filePath, contents: key.data(using: .utf8), attributes: nil)

        let result = StorageRequestUtils.validateFileExists(fileURL)
        XCTAssertNil(result)
    }

    func testValidateFileExistsForEmptyFileReturnsError() {
        let fileURL = URL(fileURLWithPath: "path")
        let result = StorageRequestUtils.validateFileExists(fileURL)
        XCTAssertNotNil(result)
        XCTAssertTrue(result!.errorDescription.contains(StorageErrorConstants.localFileNotFound.errorDescription))
    }
}
