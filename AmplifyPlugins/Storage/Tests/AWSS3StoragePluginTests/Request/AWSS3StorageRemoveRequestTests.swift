//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import XCTest
@testable import AWSS3StoragePlugin

// `@unchecked Sendable`: `XCTestCase` is not `Sendable`, but the test body is captured by the
// `@Sendable` closures the API now takes. XCTest runs one test at a time.
class AWSS3StorageRemoveRequestTests: XCTestCase, @unchecked Sendable {

    let testTargetIdentityId = "TestTargetIdentityId"
    let testKey = "TestKey"
    let testPluginOptions: Any? = [:]
    let testData = Data()
    let testContentType = "TestContentType"
    let testMetadata: [String: String] = [:]

    func testValidateSuccess() {
        let options = StorageRemoveRequest.Options(
            accessLevel: .protected,
            pluginOptions: testPluginOptions
        )
        let request = StorageRemoveRequest(key: testKey, options: options)

        let storageErrorOptional = request.validate()

        XCTAssertNil(storageErrorOptional)
    }

    func testValidateEmptyKeyError() {
        let options = StorageRemoveRequest.Options(
            accessLevel: .protected,
            pluginOptions: testPluginOptions
        )
        let request = StorageRemoveRequest(key: "", options: options)

        let storageErrorOptional = request.validate()

        guard let error = storageErrorOptional else {
            XCTFail("Missing StorageError")
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
