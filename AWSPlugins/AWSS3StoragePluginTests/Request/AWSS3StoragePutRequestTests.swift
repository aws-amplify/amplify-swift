//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import AWSS3StoragePlugin

class AWSS3StoragePutRequestTests: XCTestCase {

    let testTargetIdentityId = "TestTargetIdentityId"
    let testKey = "TestKey"
    let testOptions: Any? = [:]
    let testData = Data()
    let testContentType = "TestContentType"
    let testMetadata: [String: String] = [:]

    // TODO: Success test with upload source .file and is an existing file
    
    func testValidateSuccess() {
        let request = AWSS3StoragePutRequest(accessLevel: .protected,
                                             key: testKey,
                                             uploadSource: .data(data: testData),
                                             contentType: testContentType,
                                             metadata: testMetadata,
                                             options: testOptions)

        let storagePutErrorOptional = request.validate()

        XCTAssertNil(storagePutErrorOptional)
    }

    func testValidateEmptyKeyError() {
        let request = AWSS3StoragePutRequest(accessLevel: .protected,
                                             key: "",
                                             uploadSource: .data(data: testData),
                                             contentType: testContentType,
                                             metadata: testMetadata,
                                             options: testOptions)

        let storagePutErrorOptional = request.validate()

        guard let error = storagePutErrorOptional else {
            XCTFail("Missing StoragePutError")
            return
        }

        guard case .validation(let description, let recovery) = error else {
            XCTFail("Error does not match validation error")
            return
        }

        XCTAssertEqual(description, StorageErrorConstants.keyIsEmpty.errorDescription)
        XCTAssertEqual(recovery, StorageErrorConstants.keyIsEmpty.recoverySuggestion)
    }

    func testValidateEmptyContentTypeError() {
        let request = AWSS3StoragePutRequest(accessLevel: .protected,
                                             key: testKey,
                                             uploadSource: .data(data: testData),
                                             contentType: "",
                                             metadata: testMetadata,
                                             options: testOptions)

        let storagePutErrorOptional = request.validate()

        guard let error = storagePutErrorOptional else {
            XCTFail("Missing StoragePutError")
            return
        }

        guard case .validation(let description, let recovery) = error else {
            XCTFail("Error does not match validation error")
            return
        }

        XCTAssertEqual(description, StorageErrorConstants.contentTypeIsEmpty.errorDescription)
        XCTAssertEqual(recovery, StorageErrorConstants.contentTypeIsEmpty.recoverySuggestion)
    }

    func testValidateMetadataKeyIsInvalid() {
        let metadata = ["InvalidKeyNotLowerCase": "someValue"]
        let request = AWSS3StoragePutRequest(accessLevel: .protected,
                                             key: testKey,
                                             uploadSource: .data(data: testData),
                                             contentType: testContentType,
                                             metadata: metadata,
                                             options: testOptions)

        let storagePutErrorOptional = request.validate()

        guard let error = storagePutErrorOptional else {
            XCTFail("Missing StoragePutError")
            return
        }

        guard case .validation(let description, let recovery) = error else {
            XCTFail("Error does not match validation error")
            return
        }

        XCTAssertEqual(description, StorageErrorConstants.metadataKeysInvalid.errorDescription)
        XCTAssertEqual(recovery, StorageErrorConstants.metadataKeysInvalid.recoverySuggestion)
    }

    // TODO: testValidateMetadataValuesTooLarge
//    func testValidateMetadataValuesTooLarge() {
//
//    }

    func testValidateFileExists() {
        let url = URL(fileURLWithPath: "path")
        let request = AWSS3StoragePutRequest(accessLevel: .protected,
                                             key: testKey,
                                             uploadSource: .file(file: url),
                                             contentType: testContentType,
                                             metadata: testMetadata,
                                             options: testOptions)

        let storagePutErrorOptional = request.validate()

        guard let error = storagePutErrorOptional else {
            XCTFail("Missing StoragePutError")
            return
        }

        guard case .validation(let description, let recovery) = error else {
            XCTFail("Error does not match validation error")
            return
        }

        XCTAssertEqual(description, StorageErrorConstants.missingFile.errorDescription)
        XCTAssertEqual(recovery, StorageErrorConstants.missingFile.recoverySuggestion)
    }
}
