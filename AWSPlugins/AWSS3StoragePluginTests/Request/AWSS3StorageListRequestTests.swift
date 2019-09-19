//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import AWSS3StoragePlugin

class AWSS3StorageListRequestTests: XCTestCase {

    let testTargetIdentityId = "TestTargetIdentityId"
    let testPath = "TestPath"
    let testOptions: Any? = [:]

    func testValidateSuccess() {
        let request = AWSS3StorageListRequest(accessLevel: .protected,
                                              targetIdentityId: testTargetIdentityId,
                                              path: testPath,
                                              options: testOptions)

        let storageErrorOptional = request.validate()

        XCTAssertNil(storageErrorOptional)
    }

    func testValidateEmptyTargetIdentityIdError() {
        let request = AWSS3StorageListRequest(accessLevel: .protected,
                                              targetIdentityId: "",
                                              path: testPath,
                                              options: testOptions)

        let storageErrorOptional = request.validate()

        guard let error = storageErrorOptional else {
            XCTFail("Missing StorageError")
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
        let request = AWSS3StorageListRequest(accessLevel: .private,
                                              targetIdentityId: testTargetIdentityId,
                                              path: testPath,
                                              options: testOptions)

        let storageErrorOptional = request.validate()

        guard let error = storageErrorOptional else {
            XCTFail("Missing StorageError")
            return
        }

        guard case .validation(let description, let recovery) = error else {
            XCTFail("Error does not match validation error")
            return
        }

        XCTAssertEqual(description, StorageErrorConstants.privateWithTarget.errorDescription)
        XCTAssertEqual(recovery, StorageErrorConstants.privateWithTarget.recoverySuggestion)
    }

    func testValidateEmptyPathError() {
        let request = AWSS3StorageListRequest(accessLevel: .protected,
                                              targetIdentityId: testTargetIdentityId,
                                              path: "",
                                              options: testOptions)

        let storageErrorOptional = request.validate()

        guard let error = storageErrorOptional else {
            XCTFail("Missing StorageError")
            return
        }

        guard case .validation(let description, let recovery) = error else {
            XCTFail("Error does not match validation error")
            return
        }

        XCTAssertEqual(description, StorageErrorConstants.pathIsEmpty.errorDescription)
        XCTAssertEqual(recovery, StorageErrorConstants.pathIsEmpty.recoverySuggestion)
    }
}
