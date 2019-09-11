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

        let storageListErrorOptional = request.validate()

        XCTAssertNil(storageListErrorOptional)
    }

    func testValidateEmptyTargetIdentityIdError() {
        let request = AWSS3StorageListRequest(accessLevel: .protected,
                                              targetIdentityId: "",
                                              path: testPath,
                                              options: testOptions)

        let storageListErrorOptional = request.validate()

        guard let error = storageListErrorOptional else {
            XCTFail("Missing StorageListError")
            return
        }

        guard case .validation(let description, let recovery) = error else {
            XCTFail("Error does not match validation error")
            return
        }

        XCTAssertEqual(description, StorageErrorConstants.IdentityIdIsEmpty.errorDescription)
        XCTAssertEqual(recovery, StorageErrorConstants.IdentityIdIsEmpty.recoverySuggestion)
    }

    func testValidateTargetIdentityIdWithPrivateAccessLevelError() {
        let request = AWSS3StorageListRequest(accessLevel: .private,
                                              targetIdentityId: testTargetIdentityId,
                                              path: testPath,
                                              options: testOptions)

        let storageListErrorOptional = request.validate()

        guard let error = storageListErrorOptional else {
            XCTFail("Missing StorageListError")
            return
        }

        guard case .validation(let description, let recovery) = error else {
            XCTFail("Error does not match validation error")
            return
        }

        XCTAssertEqual(description, StorageErrorConstants.PrivateWithTarget.errorDescription)
        XCTAssertEqual(recovery, StorageErrorConstants.PrivateWithTarget.recoverySuggestion)
    }

    func testValidateEmptyPathError() {
        let request = AWSS3StorageListRequest(accessLevel: .protected,
                                              targetIdentityId: testTargetIdentityId,
                                              path: "",
                                              options: testOptions)

        let storageListErrorOptional = request.validate()

        guard let error = storageListErrorOptional else {
            XCTFail("Missing StorageListError")
            return
        }

        guard case .validation(let description, let recovery) = error else {
            XCTFail("Error does not match validation error")
            return
        }

        XCTAssertEqual(description, StorageErrorConstants.PathIsEmpty.errorDescription)
        XCTAssertEqual(recovery, StorageErrorConstants.PathIsEmpty.recoverySuggestion)
    }
}
