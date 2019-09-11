//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import AWSS3StoragePlugin

class AWSS3StorageGetRequestTests: XCTestCase {

    let testTargetIdentityId = "TestTargetIdentityId"
    let testKey = "TestKey"
    let testOptions: Any? = [:]

    func testValidateSuccess() {
        let request = AWSS3StorageGetRequest(accessLevel: .protected,
                                             targetIdentityId: testTargetIdentityId,
                                             key: testKey,
                                             storageGetDestination: .data,
                                             options: testOptions)

        let storageGetErrorOptional = request.validate()

        XCTAssertNil(storageGetErrorOptional)
    }

    func testValidateEmptyTargetIdentityIdError() {
        let request = AWSS3StorageGetRequest(accessLevel: .protected,
                                             targetIdentityId: "",
                                             key: testKey,
                                             storageGetDestination: .data,
                                             options: testOptions)

        let storageGetErrorOptional = request.validate()

        guard let error = storageGetErrorOptional else {
            XCTFail("Missing StorageGetError")
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
        let request = AWSS3StorageGetRequest(accessLevel: .private,
                                             targetIdentityId: testTargetIdentityId,
                                             key: testKey,
                                             storageGetDestination: .data,
                                             options: testOptions)

        let storageGetErrorOptional = request.validate()

        guard let error = storageGetErrorOptional else {
            XCTFail("Missing StorageGetError")
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
        let request = AWSS3StorageGetRequest(accessLevel: .protected,
                                             targetIdentityId: testTargetIdentityId,
                                             key: "",
                                             storageGetDestination: .data,
                                             options: testOptions)

        let storageGetErrorOptional = request.validate()

        guard let error = storageGetErrorOptional else {
            XCTFail("Missing StorageGetError")
            return
        }

        guard case .validation(let description, let recovery) = error else {
            XCTFail("Error does not match validation error")
            return
        }

        XCTAssertEqual(description, StorageErrorConstants.keyIsEmpty.errorDescription)
        XCTAssertEqual(recovery, StorageErrorConstants.keyIsEmpty.recoverySuggestion)
    }

    func testValidateURLStorageGetDestinationWithNonPositiveExpiresError() {
        let request = AWSS3StorageGetRequest(accessLevel: .protected,
                                             targetIdentityId: testTargetIdentityId,
                                             key: testKey,
                                             storageGetDestination: .url(expires: -1),
                                             options: testOptions)

        let storageGetErrorOptional = request.validate()

        guard let error = storageGetErrorOptional else {
            XCTFail("Missing StorageGetError")
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
