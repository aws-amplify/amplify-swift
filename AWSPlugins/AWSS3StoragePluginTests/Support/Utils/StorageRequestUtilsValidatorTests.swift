//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
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
        let result = StorageRequestUtils.validateTargetIdentityId(nil, accessLevel: .public)
        XCTAssertNil(result)
    }

    func testValidateTargetIdentityIdWithPublicAccessLevelSuccess() {
        let result = StorageRequestUtils.validateTargetIdentityId(testIdentityId, accessLevel: .public)
        XCTAssertNil(result)
    }

    func testValidateTargetIdentityIdWithProtectedAccessLevelSuccess() {
        let result = StorageRequestUtils.validateTargetIdentityId(testIdentityId, accessLevel: .protected)
        XCTAssertNil(result)
    }

    func testValidateTargetIdentityIdWithPrivateAccessLevelSuccess() {
        let result = StorageRequestUtils.validateTargetIdentityId(testIdentityId, accessLevel: .private)
        XCTAssertNotNil(result)
        XCTAssertEqual(result!.errorDescription, StorageErrorConstants.privateWithTarget.errorDescription)
    }

    func testValidateTargetIdentityIdForEmpyTargetIdReturnsError() {
        let result = StorageRequestUtils.validateTargetIdentityId("", accessLevel: .public)
        XCTAssertNotNil(result)
        XCTAssertEqual(result!.errorDescription, StorageErrorConstants.identityIdIsEmpty.errorDescription)
    }

    // MARK: ValidateKey tests

    func testValidateKeySuccess() {
        let result = StorageRequestUtils.validateKey(testKey)
        XCTAssertNil(result)
    }

    func testValidateKeyForEmptyKeyReturnsError() {
        let result = StorageRequestUtils.validateKey("")
        XCTAssertNotNil(result)
        XCTAssertEqual(result!.errorDescription, StorageErrorConstants.keyIsEmpty.errorDescription)
    }

    // MARK: ValidateStorageDestination tests

    func testValidateUrlStorageDestinationWithNonPositiveExpiresReturnsError() {
        let result = StorageRequestUtils.validate(StorageGetDestination.url(expires: -1))
        XCTAssertNotNil(result)
        XCTAssertEqual(result!.errorDescription, StorageErrorConstants.expiresIsInvalid.errorDescription)
    }

    func testValidateUrlStorageDestinationWithPositiveExpiresSuccess() {
        let result = StorageRequestUtils.validate(StorageGetDestination.url(expires: 10))
        XCTAssertNil(result)
    }

    func testValidateFileStorageDestinationSuccess() {
        let url = URL(fileURLWithPath: "path")
        let result = StorageRequestUtils.validate(StorageGetDestination.file(local: url))
        XCTAssertNil(result)
    }

    func testValidateDataStorageDestinationSuccess() {
        let result = StorageRequestUtils.validate(StorageGetDestination.data)
        XCTAssertNil(result)
    }

    // MARK: ValidatePath tests

    func testValidatePathSuccess() {
        let result = StorageRequestUtils.validatePath(testPath)
        XCTAssertNil(result)
    }

    func testValidatePathForEmptyPathReturnsError() {
        let result = StorageRequestUtils.validatePath("")
        XCTAssertNotNil(result)
        XCTAssertEqual(result!.errorDescription, StorageErrorConstants.pathIsEmpty.errorDescription)
    }

    // MARK: ValidateContentType tests

    func testValidateContentTypeSuccess() {
        let result = StorageRequestUtils.validateContentType(testContentType)
        XCTAssertNil(result)
    }

    func testValidateContentTypeForEmptyContentTypeReturnsError() {
        let result = StorageRequestUtils.validateContentType("")
        XCTAssertNotNil(result)
        XCTAssertEqual(result!.errorDescription, StorageErrorConstants.contentTypeIsEmpty.errorDescription)
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
        XCTAssertEqual(result!.errorDescription, StorageErrorConstants.metadataKeysInvalid.errorDescription)
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
        XCTAssertEqual(result!.errorDescription, StorageErrorConstants.missingFile.errorDescription)
    }
}
