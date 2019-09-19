//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import AWSS3StoragePlugin

class AWSS3StorageRemoveRequestTests: XCTestCase {

    let testTargetIdentityId = "TestTargetIdentityId"
    let testKey = "TestKey"
    let testOptions: Any? = [:]
    let testData = Data()
    let testContentType = "TestContentType"
    let testMetadata: [String: String] = [:]

    func testValidateSuccess() {
        let request = AWSS3StorageRemoveRequest(accessLevel: .protected,
                                                key: testKey,
                                                options: testOptions)

        let storageErrorOptional = request.validate()

        XCTAssertNil(storageErrorOptional)
    }

    func testValidateEmptyKeyError() {
        let request = AWSS3StorageRemoveRequest(accessLevel: .protected,
                                                key: "",
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

        XCTAssertEqual(description, StorageErrorConstants.keyIsEmpty.errorDescription)
        XCTAssertEqual(recovery, StorageErrorConstants.keyIsEmpty.recoverySuggestion)
    }

}
