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
    let testOptions: Any? = [:]
    let testExpires = 10

    func testValidateSuccess() {
        let request = AWSS3StorageGetURLRequest(accessLevel: .protected,
                                                targetIdentityId: testTargetIdentityId,
                                                key: testKey,
                                                expires: testExpires,
                                                options: testOptions)

        let storageErrorOptional = request.validate()

        XCTAssertNil(storageErrorOptional)
    }

    func testValidateEmptyTargetIdentityIdError() {
        let request = AWSS3StorageGetURLRequest(accessLevel: .protected,
                                                targetIdentityId: "",
                                                key: testKey,
                                                expires: testExpires,
                                                options: testOptions)

        let storageErrorOptional = request.validate()

        guard let error = storageErrorOptional else {
            XCTFail("Missing storageError")
            return
        }

        guard case .validation(let description, let recovery) = error else {
            XCTFail("Error does not match validation error")
            return
        }

        XCTAssertEqual(description, StorageErrorConstants.identityIdIsEmpty.errorDescription)
        XCTAssertEqual(recovery, StorageErrorConstants.identityIdIsEmpty.recoverySuggestion)
    }

    func testValidateTargetIdentityIdWithPrivateAccessLevelError() {
        let request = AWSS3StorageGetURLRequest(accessLevel: .private,
                                             targetIdentityId: testTargetIdentityId,
                                             key: testKey,
                                             expires: testExpires,
                                             options: testOptions)

        let storageErrorOptional = request.validate()

        guard let error = storageErrorOptional else {
            XCTFail("Missing storageError")
            return
        }

        guard case .validation(let description, let recovery) = error else {
            XCTFail("Error does not match validation error")
            return
        }

        XCTAssertEqual(description, StorageErrorConstants.privateWithTarget.errorDescription)
        XCTAssertEqual(recovery, StorageErrorConstants.privateWithTarget.recoverySuggestion)
    }

    func testValidateKeyIsEmptyError() {
        let request = AWSS3StorageGetURLRequest(accessLevel: .protected,
                                             targetIdentityId: testTargetIdentityId,
                                             key: "",
                                             expires: testExpires,
                                             options: testOptions)

        let storageErrorOptional = request.validate()

        guard let error = storageErrorOptional else {
            XCTFail("Missing storageError")
            return
        }

        guard case .validation(let description, let recovery) = error else {
            XCTFail("Error does not match validation error")
            return
        }

        XCTAssertEqual(description, StorageErrorConstants.keyIsEmpty.errorDescription)
        XCTAssertEqual(recovery, StorageErrorConstants.keyIsEmpty.recoverySuggestion)
    }

    func testValidateURLNonPositiveExpiresError() {
        let request = AWSS3StorageGetURLRequest(accessLevel: .protected,
                                             targetIdentityId: testTargetIdentityId,
                                             key: testKey,
                                             expires: -1,
                                             options: testOptions)

        let storageErrorOptional = request.validate()

        guard let error = storageErrorOptional else {
            XCTFail("Missing storageError")
            return
        }

        guard case .validation(let description, let recovery) = error else {
            XCTFail("Error does not match validation error")
            return
        }

        XCTAssertEqual(description, StorageErrorConstants.expiresIsInvalid.errorDescription)
        XCTAssertEqual(recovery, StorageErrorConstants.expiresIsInvalid.recoverySuggestion)
    }
}
