//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import Amplify
@testable import AWSS3StoragePlugin

class AWSS3StorageUploadFileRequestTests: XCTestCase {

    let testTargetIdentityId = "TestTargetIdentityId"
    let testKey = "TestKey"
    let testPluginOptions: Any? = [:]
    let testData = Data()
    let testContentType = "TestContentType"
    let testMetadata: [String: String] = [:]

    func testValidateSuccess() {
        let filePath = NSTemporaryDirectory() + UUID().uuidString + ".tmp"
        let fileURL = URL(fileURLWithPath: filePath)
        FileManager.default.createFile(atPath: filePath, contents: testData, attributes: nil)
        let options = StorageUploadFileRequest.Options(accessLevel: .protected,
                                                       metadata: testMetadata,
                                                       contentType: testContentType,
                                                       pluginOptions: testPluginOptions)
        let request = StorageUploadFileRequest(key: testKey, local: fileURL, options: options)

        let storageErrorOptional = request.validate()

        XCTAssertNil(storageErrorOptional)
    }

    func testValidateEmptyKeyError() {
        let filePath = NSTemporaryDirectory() + UUID().uuidString + ".tmp"
        let fileURL = URL(fileURLWithPath: filePath)
        FileManager.default.createFile(atPath: filePath, contents: testData, attributes: nil)
        let options = StorageUploadFileRequest.Options(accessLevel: .protected,
                                                       metadata: testMetadata,
                                                       contentType: testContentType,
                                                       pluginOptions: testPluginOptions)
        let request = StorageUploadFileRequest(key: "", local: fileURL, options: options)

        let storageErrorOptional = request.validate()

        guard let error = storageErrorOptional else {
            XCTFail("Missing StorageError")
            return
        }

        guard case .validation(let field, let description, let recovery, _) = error else {
            XCTFail("Error does not match validation error")
            return
        }

        XCTAssertEqual(field, StorageErrorConstants.keyIsEmpty.field)
        XCTAssertEqual(description, StorageErrorConstants.keyIsEmpty.errorDescription)
        XCTAssertEqual(recovery, StorageErrorConstants.keyIsEmpty.recoverySuggestion)
    }

    func testValidateEmptyContentTypeError() {
        let filePath = NSTemporaryDirectory() + UUID().uuidString + ".tmp"
        let fileURL = URL(fileURLWithPath: filePath)
        FileManager.default.createFile(atPath: filePath, contents: testData, attributes: nil)
        let options = StorageUploadFileRequest.Options(accessLevel: .protected,
                                                       metadata: testMetadata,
                                                       contentType: "",
                                                       pluginOptions: testPluginOptions)
        let request = StorageUploadFileRequest(key: testKey, local: fileURL, options: options)

        let storageErrorOptional = request.validate()

        guard let error = storageErrorOptional else {
            XCTFail("Missing StorageError")
            return
        }

        guard case .validation(let field, let description, let recovery, _) = error else {
            XCTFail("Error does not match validation error")
            return
        }

        XCTAssertEqual(field, StorageErrorConstants.contentTypeIsEmpty.field)
        XCTAssertEqual(description, StorageErrorConstants.contentTypeIsEmpty.errorDescription)
        XCTAssertEqual(recovery, StorageErrorConstants.contentTypeIsEmpty.recoverySuggestion)
    }

    func testValidateMetadataKeyIsInvalid() {
        let filePath = NSTemporaryDirectory() + UUID().uuidString + ".tmp"
        let fileURL = URL(fileURLWithPath: filePath)
        FileManager.default.createFile(atPath: filePath, contents: testData, attributes: nil)
        let metadata = ["InvalidKeyNotLowerCase": "someValue"]
        let options = StorageUploadFileRequest.Options(accessLevel: .protected,
                                                       metadata: metadata,
                                                       contentType: testContentType,
                                                       pluginOptions: testPluginOptions)
        let request = StorageUploadFileRequest(key: testKey, local: fileURL, options: options)

        let storageErrorOptional = request.validate()

        guard let error = storageErrorOptional else {
            XCTFail("Missing StorageError")
            return
        }

        guard case .validation(let field, let description, let recovery, _) = error else {
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
