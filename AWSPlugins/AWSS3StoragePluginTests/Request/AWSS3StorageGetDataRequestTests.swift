//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import AWSS3StoragePlugin

class AWSS3StorageGetDataRequestTests: XCTestCase {

    let testTargetIdentityId = "TestTargetIdentityId"
    let testKey = "TestKey"
    let testOptions: Any? = [:]

    func testValidateSuccess() {
        let request = AWSS3StorageGetDataRequest(accessLevel: .protected,
                                                 targetIdentityId: testTargetIdentityId,
                                                 key: testKey,
                                                 options: testOptions)

        let storageGetDataErrorOptional = request.validate()

        XCTAssertNil(storageGetDataErrorOptional)
    }

    func testValidateEmptyTargetIdentityIdError() {
        let request = AWSS3StorageGetDataRequest(accessLevel: .protected,
                                             targetIdentityId: "",
                                             key: testKey,
                                             options: testOptions)

        let storageGetDataErrorOptional = request.validate()

        guard let error = storageGetDataErrorOptional else {
            XCTFail("Missing StorageGetDataError")
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
        let request = AWSS3StorageGetDataRequest(accessLevel: .private,
                                             targetIdentityId: testTargetIdentityId,
                                             key: testKey,
                                             options: testOptions)

        let storageGetDataErrorOptional = request.validate()

        guard let error = storageGetDataErrorOptional else {
            XCTFail("Missing StorageGetDataError")
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
        let request = AWSS3StorageGetDataRequest(accessLevel: .protected,
                                                 targetIdentityId: testTargetIdentityId,
                                                 key: "",
                                                 options: testOptions)

        let storageGetDataErrorOptional = request.validate()

        guard let error = storageGetDataErrorOptional else {
            XCTFail("Missing StorageGetDataError")
            return
        }

        guard case .validation(let description, let recovery) = error else {
            XCTFail("Error does not match validation error")
            return
        }

        XCTAssertEqual(description, StorageErrorConstants.keyIsEmpty.errorDescription)
        XCTAssertEqual(recovery, StorageErrorConstants.keyIsEmpty.recoverySuggestion)
    }
}
