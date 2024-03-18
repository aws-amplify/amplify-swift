//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
@testable import AWSS3StoragePlugin

class StorageDownloadDataRequestTests: XCTestCase {

    let testTargetIdentityId = "TestTargetIdentityId"
    let testKey = "TestKey"
    let testPluginOptions: Any? = [:]

    func testValidateSuccess() {
        let options = StorageDownloadDataRequest.Options(accessLevel: .protected,
                                                    targetIdentityId: testTargetIdentityId,
                                                    pluginOptions: testPluginOptions)
        let request = StorageDownloadDataRequest(key: testKey, options: options)

        let storageErrorOptional = request.validate()

        XCTAssertNil(storageErrorOptional)
    }

    func testValidateEmptyTargetIdentityIdError() {
        let options = StorageDownloadDataRequest.Options(accessLevel: .protected,
                                                    targetIdentityId: "",
                                                    pluginOptions: testPluginOptions)
        let request = StorageDownloadDataRequest(key: testKey, options: options)

        let storageErrorOptional = request.validate()

        guard let error = storageErrorOptional else {
            XCTFail("Missing StorageError")
            return
        }

        guard case .validation(let field, let description, let recovery, _) = error else {
            XCTFail("Error does not match validation error")
            return
        }

        XCTAssertEqual(field, StorageErrorConstants.identityIdIsEmpty.field)
        XCTAssertEqual(description, StorageErrorConstants.identityIdIsEmpty.errorDescription)
        XCTAssertEqual(recovery, StorageErrorConstants.identityIdIsEmpty.recoverySuggestion)
    }

    func testValidateTargetIdentityIdWithPrivateAccessLevelError() {
        let options = StorageDownloadDataRequest.Options(accessLevel: .private,
                                                    targetIdentityId: testTargetIdentityId,
                                                    pluginOptions: testPluginOptions)
        let request = StorageDownloadDataRequest(key: testKey, options: options)

        let storageErrorOptional = request.validate()

        guard let error = storageErrorOptional else {
            XCTFail("Missing StorageError")
            return
        }

        guard case .validation(let field, let description, let recovery, _) = error else {
            XCTFail("Error does not match validation error")
            return
        }

        XCTAssertEqual(field, StorageErrorConstants.invalidAccessLevelWithTarget.field)
        XCTAssertEqual(description, StorageErrorConstants.invalidAccessLevelWithTarget.errorDescription)
        XCTAssertEqual(recovery, StorageErrorConstants.invalidAccessLevelWithTarget.recoverySuggestion)
    }

    func testValidateKeyIsEmptyError() {
        let options = StorageDownloadDataRequest.Options(accessLevel: .protected,
                                                    targetIdentityId: testTargetIdentityId,
                                                    pluginOptions: testPluginOptions)
        let request = StorageDownloadDataRequest(key: "", options: options)

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

    /// Given: StorageDownloadDataRequest with an invalid StringStoragePath
    /// When: Request validation is executed
    /// Then: There is no error returned even though the storage path is invalid
    /// There is no error because the path validation is done at operation execution time and not part of the request
    func testValidateWithStoragePath() {
        let options = StorageDownloadDataRequest.Options(accessLevel: .private,
                                                    targetIdentityId: "",
                                                    pluginOptions: testPluginOptions)
        let path = StringStoragePath(resolve: { input in return "my/path/"})
        let request = StorageDownloadDataRequest(path: path, options: options)

        let storageErrorOptional = request.validate()

        XCTAssertNil(storageErrorOptional)
    }
}
