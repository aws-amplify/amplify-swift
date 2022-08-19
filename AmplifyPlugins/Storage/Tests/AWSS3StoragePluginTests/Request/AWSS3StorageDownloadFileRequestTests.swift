//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import Amplify
@testable import AWSS3StoragePlugin

class StorageDownloadFileRequestTests: XCTestCase {

    let testTargetIdentityId = "TestTargetIdentityId"
    let testKey = "TestKey"
    let testPluginOptions: Any? = [:]
    let testURL = URL(fileURLWithPath: "path")

    func testValidateSuccess() {
        let options = StorageDownloadFileRequest.Options(accessLevel: .protected,
                                                         targetIdentityId: testTargetIdentityId,
                                                         pluginOptions: testPluginOptions)
        let request = StorageDownloadFileRequest(key: testKey, local: testURL, options: options)

        let storageErrorOptional = request.validate()

        XCTAssertNil(storageErrorOptional)
    }

    func testValidateEmptyTargetIdentityIdError() {
        let options = StorageDownloadFileRequest.Options(accessLevel: .protected,
                                                         targetIdentityId: "",
                                                         pluginOptions: testPluginOptions)
        let request = StorageDownloadFileRequest(key: testKey, local: testURL, options: options)

        let storageErrorOptional = request.validate()

        guard let error = storageErrorOptional else {
            XCTFail("Missing StorageDownloadFile")
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
        let options = StorageDownloadFileRequest.Options(accessLevel: .private,
                                                         targetIdentityId: testTargetIdentityId,
                                                         pluginOptions: testPluginOptions)
        let request = StorageDownloadFileRequest(key: testKey, local: testURL, options: options)

        let storageErrorOptional = request.validate()

        guard let error = storageErrorOptional else {
            XCTFail("Missing StorageDownloadFile")
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
        let options = StorageDownloadFileRequest.Options(accessLevel: .protected,
                                                         targetIdentityId: testTargetIdentityId,
                                                         pluginOptions: testPluginOptions)
        let request = StorageDownloadFileRequest(key: "", local: testURL, options: options)

        let storageErrorOptional = request.validate()

        guard let error = storageErrorOptional else {
            XCTFail("Missing StorageDownloadFile")
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
}
