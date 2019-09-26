//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import AWSS3StoragePlugin

class AWSS3StorageGetURLRequestTests: XCTestCase {

    let testTargetIdentityId = "TestTargetIdentityId"
    let testKey = "TestKey"
    let testPluginOptions: Any? = [:]
    let testExpires = 10

    func testValidateSuccess() {
        let request = AWSS3StorageGetURLRequest(accessLevel: .protected,
                                                targetIdentityId: testTargetIdentityId,
                                                key: testKey,
                                                expires: testExpires,
                                                pluginOptions: testPluginOptions)

        let storageErrorOptional = request.validate()

        XCTAssertNil(storageErrorOptional)
    }

    func testValidateEmptyTargetIdentityIdError() {
        let request = AWSS3StorageGetURLRequest(accessLevel: .protected,
                                                targetIdentityId: "",
                                                key: testKey,
                                                expires: testExpires,
                                                pluginOptions: testPluginOptions)

        let storageErrorOptional = request.validate()

        guard let error = storageErrorOptional else {
            XCTFail("Missing storageError")
            return
        }

        guard case .validation(let field, let description, let recovery) = error else {
            XCTFail("Error does not match validation error")
            return
        }

        XCTAssertEqual(field, StorageErrorConstants.identityIdIsEmpty.field)
        XCTAssertEqual(description, StorageErrorConstants.identityIdIsEmpty.errorDescription)
        XCTAssertEqual(recovery, StorageErrorConstants.identityIdIsEmpty.recoverySuggestion)
    }

    func testValidateTargetIdentityIdWithPrivateAccessLevelError() {
        let request = AWSS3StorageGetURLRequest(accessLevel: .private,
                                                targetIdentityId: testTargetIdentityId,
                                                key: testKey,
                                                expires: testExpires,
                                                pluginOptions: testPluginOptions)

        let storageErrorOptional = request.validate()

        guard let error = storageErrorOptional else {
            XCTFail("Missing storageError")
            return
        }

        guard case .validation(let field, let description, let recovery) = error else {
            XCTFail("Error does not match validation error")
            return
        }

        XCTAssertEqual(field, StorageErrorConstants.invalidAccessLevelWithTarget.field)
        XCTAssertEqual(description, StorageErrorConstants.invalidAccessLevelWithTarget.errorDescription)
        XCTAssertEqual(recovery, StorageErrorConstants.invalidAccessLevelWithTarget.recoverySuggestion)
    }

    func testValidateKeyIsEmptyError() {
        let request = AWSS3StorageGetURLRequest(accessLevel: .protected,
                                                targetIdentityId: testTargetIdentityId,
                                                key: "",
                                                expires: testExpires,
                                                pluginOptions: testPluginOptions)

        let storageErrorOptional = request.validate()

        guard let error = storageErrorOptional else {
            XCTFail("Missing storageError")
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

    func testValidateURLNonPositiveExpiresError() {
        let request = AWSS3StorageGetURLRequest(accessLevel: .protected,
                                                targetIdentityId: testTargetIdentityId,
                                                key: testKey,
                                                expires: -1,
                                                pluginOptions: testPluginOptions)

        let storageErrorOptional = request.validate()

        guard let error = storageErrorOptional else {
            XCTFail("Missing storageError")
            return
        }

        guard case .validation(let field, let description, let recovery) = error else {
            XCTFail("Error does not match validation error")
            return
        }

        XCTAssertEqual(field, StorageErrorConstants.expiresIsInvalid.field)
        XCTAssertEqual(description, StorageErrorConstants.expiresIsInvalid.errorDescription)
        XCTAssertEqual(recovery, StorageErrorConstants.expiresIsInvalid.recoverySuggestion)
    }
}
