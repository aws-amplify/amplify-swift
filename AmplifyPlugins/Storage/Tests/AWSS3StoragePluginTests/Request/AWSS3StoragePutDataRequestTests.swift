//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
@testable import AWSS3StoragePlugin

class AWSS3StorageUploadDataRequestTests: XCTestCase {

    let testTargetIdentityId = "TestTargetIdentityId"
    let testKey = "TestKey"
    let testPluginOptions: Any? = [:]
    let testData = Data()
    let testContentType = "TestContentType"
    let testMetadata: [String: String] = [:]

    func testValidateSuccess() {
        let options = StorageUploadDataRequest.Options(accessLevel: .protected,
                                                    metadata: testMetadata,
                                                    contentType: testContentType,
                                                    pluginOptions: testPluginOptions)
        let request = StorageUploadDataRequest(key: testKey, data: testData, options: options)

        let storageErrorOptional = request.validate()

        XCTAssertNil(storageErrorOptional)
    }

    func testValidateEmptyKeyError() {
        let options = StorageUploadDataRequest.Options(accessLevel: .protected,
                                                    metadata: testMetadata,
                                                    contentType: testContentType,
                                                    pluginOptions: testPluginOptions)
        let request = StorageUploadDataRequest(key: "", data: testData, options: options)

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
        let options = StorageUploadDataRequest.Options(accessLevel: .protected,
                                                    metadata: testMetadata,
                                                    contentType: "",
                                                    pluginOptions: testPluginOptions)
        let request = StorageUploadDataRequest(key: testKey, data: testData, options: options)

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
        let metadata = ["InvalidKeyNotLowerCase": "someValue"]
        let options = StorageUploadDataRequest.Options(accessLevel: .protected,
                                                    metadata: metadata,
                                                    contentType: testContentType,
                                                    pluginOptions: testPluginOptions)
        let request = StorageUploadDataRequest(key: testKey, data: testData, options: options)

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

    /// Given: StorageUploadDataRequest with an invalid StringStoragePath
    /// When: Request validation is executed
    /// Then: There is no error returned even though the storage path is invalid
    /// There is no error because the path validation is done at operation execution time and not part of the request
    func testValidateWithStoragePath() {
        let path = StringStoragePath(resolve: {_ in "my/path"})
        let options = StorageUploadDataRequest.Options(accessLevel: .protected,
                                                    metadata: testMetadata,
                                                    contentType: testContentType,
                                                    pluginOptions: testPluginOptions)
        let request = StorageUploadDataRequest(path: path, data: testData, options: options)

        let storageErrorOptional = request.validate()

        XCTAssertNil(storageErrorOptional)
    }

    // TODO: testValidateMetadataValuesTooLarge
//    func testValidateMetadataValuesTooLarge() {
//
//    }
}
