//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import Amplify
@testable import AWSS3StoragePlugin

class StorageGetURLRequestTests: XCTestCase {

    let testTargetIdentityId = "TestTargetIdentityId"
    let testKey = "TestKey"
    let testPluginOptions: Any? = [:]
    let testExpires = 10

    func testValidateSuccess() {
        let options = StorageGetURLRequest.Options(accessLevel: .protected,
                                                   targetIdentityId: testTargetIdentityId,
                                                   expires: testExpires,
                                                   pluginOptions: testPluginOptions)
        let request = StorageGetURLRequest(key: testKey, options: options)

        let storageErrorOptional = request.validate()

        XCTAssertNil(storageErrorOptional)
    }

    func testValidateEmptyTargetIdentityIdError() {
        let options = StorageGetURLRequest.Options(accessLevel: .protected,
                                                   targetIdentityId: "",
                                                   expires: testExpires,
                                                   pluginOptions: testPluginOptions)
        let request = StorageGetURLRequest(key: testKey, options: options)

        let storageErrorOptional = request.validate()

        guard let error = storageErrorOptional else {
            XCTFail("Missing storageError")
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
        let options = StorageGetURLRequest.Options(accessLevel: .private,
                                                   targetIdentityId: testTargetIdentityId,
                                                   expires: testExpires,
                                                   pluginOptions: testPluginOptions)
        let request = StorageGetURLRequest(key: testKey, options: options)

        let storageErrorOptional = request.validate()

        guard let error = storageErrorOptional else {
            XCTFail("Missing storageError")
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
        let options = StorageGetURLRequest.Options(accessLevel: .protected,
                                                   targetIdentityId: testTargetIdentityId,
                                                   expires: testExpires,
                                                   pluginOptions: testPluginOptions)
        let request = StorageGetURLRequest(key: "", options: options)

        let storageErrorOptional = request.validate()

        guard let error = storageErrorOptional else {
            XCTFail("Missing storageError")
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

    func testValidateURLNonPositiveExpiresError() {
        let options = StorageGetURLRequest.Options(accessLevel: .protected,
                                                   targetIdentityId: testTargetIdentityId,
                                                   expires: -1,
                                                   pluginOptions: testPluginOptions)
        let request = StorageGetURLRequest(key: testKey, options: options)

        let storageErrorOptional = request.validate()

        guard let error = storageErrorOptional else {
            XCTFail("Missing storageError")
            return
        }

        guard case .validation(let field, let description, let recovery, _) = error else {
            XCTFail("Error does not match validation error")
            return
        }

        XCTAssertEqual(field, StorageErrorConstants.expiresIsInvalid.field)
        XCTAssertEqual(description, StorageErrorConstants.expiresIsInvalid.errorDescription)
        XCTAssertEqual(recovery, StorageErrorConstants.expiresIsInvalid.recoverySuggestion)
    }
}
