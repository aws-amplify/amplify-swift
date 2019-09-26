//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import Amplify
@testable import AWSS3StoragePlugin

class AWSS3StoragePutRequestTests: XCTestCase {

    let testTargetIdentityId = "TestTargetIdentityId"
    let testKey = "TestKey"
    let testPluginOptions: Any? = [:]
    let testData = Data()
    let testContentType = "TestContentType"
    let testMetadata: [String: String] = [:]

    func testValidateSuccessWithDataUploadSource() {
        let options = StoragePutRequest.Options(accessLevel: .protected,
                                                metadata: testMetadata,
                                                contentType: testContentType,
                                                pluginOptions: testPluginOptions)
        let request = StoragePutRequest(key: testKey, source: .data(testData), options: options)

        let storageErrorOptional = request.validate()

        XCTAssertNil(storageErrorOptional)
    }

    func testValidateSuccessWithFileUploadSource() {
        let key = "testValidateSuccessWithFileUploadSource"
        let filePath = NSTemporaryDirectory() + key + ".tmp"
        let fileURL = URL(fileURLWithPath: filePath)
        FileManager.default.createFile(atPath: filePath, contents: key.data(using: .utf8), attributes: nil)
        let options = StoragePutRequest.Options(accessLevel: .protected,
                                                metadata: testMetadata,
                                                contentType: testContentType,
                                                pluginOptions: testPluginOptions)
        let request = StoragePutRequest(key: testKey, source: .local(fileURL), options: options)

        let storageErrorOptional = request.validate()

        XCTAssertNil(storageErrorOptional)
    }

    func testValidateEmptyKeyError() {
        let options = StoragePutRequest.Options(accessLevel: .protected,
                                                metadata: testMetadata,
                                                contentType: testContentType,
                                                pluginOptions: testPluginOptions)
        let request = StoragePutRequest(key: "", source: .data(testData), options: options)

        let storageErrorOptional = request.validate()

        guard let error = storageErrorOptional else {
            XCTFail("Missing StorageError")
            return
        }

        guard case .validation(let field, let description, let recovery) = error else {
            XCTFail("Error does not match validation error")
            return
        }

        XCTAssertEqual(field, StorageErrorConstants.keyIsEmpty.field)
        XCTAssertEqual(description, StorageErrorConstants.keyIsEmpty.errorDescription)
        XCTAssertEqual(recovery, StorageErrorConstants.keyIsEmpty.recoverySuggestion)
    }

    func testValidateEmptyContentTypeError() {
        let options = StoragePutRequest.Options(accessLevel: .protected,
                                                metadata: testMetadata,
                                                contentType: "",
                                                pluginOptions: testPluginOptions)
        let request = StoragePutRequest(key: testKey, source: .data(testData), options: options)

        let storageErrorOptional = request.validate()

        guard let error = storageErrorOptional else {
            XCTFail("Missing StorageError")
            return
        }

        guard case .validation(let field, let description, let recovery) = error else {
            XCTFail("Error does not match validation error")
            return
        }

        XCTAssertEqual(field, StorageErrorConstants.contentTypeIsEmpty.field)
        XCTAssertEqual(description, StorageErrorConstants.contentTypeIsEmpty.errorDescription)
        XCTAssertEqual(recovery, StorageErrorConstants.contentTypeIsEmpty.recoverySuggestion)
    }

    func testValidateMetadataKeyIsInvalid() {
        let metadata = ["InvalidKeyNotLowerCase": "someValue"]
        let options = StoragePutRequest.Options(accessLevel: .protected,
                                                metadata: metadata,
                                                contentType: testContentType,
                                                pluginOptions: testPluginOptions)
        let request = StoragePutRequest(key: testKey, source: .data(testData), options: options)

        let storageErrorOptional = request.validate()

        guard let error = storageErrorOptional else {
            XCTFail("Missing StorageError")
            return
        }

        guard case .validation(let field, let description, let recovery) = error else {
            XCTFail("Error does not match validation error")
            return
        }

        XCTAssertEqual(field, StorageErrorConstants.metadataKeysInvalid.field)
        XCTAssertEqual(description, StorageErrorConstants.metadataKeysInvalid.errorDescription)
        XCTAssertEqual(recovery, StorageErrorConstants.metadataKeysInvalid.recoverySuggestion)
    }

    // TODO: testValidateMetadataValuesTooLarge
//    func testValidateMetadataValuesTooLarge() {
//
//    }
}
