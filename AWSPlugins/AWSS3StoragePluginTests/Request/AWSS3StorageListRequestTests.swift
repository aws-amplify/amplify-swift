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
    let testPrefix = "TestPrefix"
    let testLimit = 5
    let testOptions: Any? = [:]

    func testValidateSuccess() {
        let request = AWSS3StorageListRequest(accessLevel: .protected,
                                              targetIdentityId: testTargetIdentityId,
                                              prefix: testPrefix,
                                              limit: testLimit,
                                              options: testOptions)

        let storageListErrorOptional = request.validate()

        XCTAssertNil(storageListErrorOptional)
    }

    func testValidateEmptyTargetIdentityIdError() {
        let request = AWSS3StorageListRequest(accessLevel: .protected,
                                              targetIdentityId: "",
                                              prefix: testPrefix,
                                              limit: testLimit,
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

        XCTAssertEqual(description, StorageErrorConstants.IdentityIdIsEmpty.ErrorDescription)
        XCTAssertEqual(recovery, StorageErrorConstants.IdentityIdIsEmpty.RecoverySuggestion)
    }

    func testValidateEmptyPrefixError() {
        let request = AWSS3StorageListRequest(accessLevel: .protected,
                                              targetIdentityId: testTargetIdentityId,
                                              prefix: "",
                                              limit: testLimit,
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

        XCTAssertEqual(description, StorageErrorConstants.PrefixIsEmpty.ErrorDescription)
        XCTAssertEqual(recovery, StorageErrorConstants.PrefixIsEmpty.RecoverySuggestion)
    }

    func testValidateLimitIsInvalidError() {
        let request = AWSS3StorageListRequest(accessLevel: .protected,
                                              targetIdentityId: testTargetIdentityId,
                                              prefix: testPrefix,
                                              limit: -1,
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

        XCTAssertEqual(description, StorageErrorConstants.LimitIsInvalid.ErrorDescription)
        XCTAssertEqual(recovery, StorageErrorConstants.LimitIsInvalid.RecoverySuggestion)
    }
}
