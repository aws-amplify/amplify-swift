//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import Amplify
@testable import AWSS3StoragePlugin

class StorageListRequestTests: XCTestCase {

    let testTargetIdentityId = "TestTargetIdentityId"
    let testPath = "TestPath"
    let testPluginOptions: Any? = [:]

    func testValidateSuccess() {
        let options = StorageListRequest.Options(accessLevel: .protected,
                                                 targetIdentityId: testTargetIdentityId,
                                                 path: testPath,
                                                 pluginOptions: testPluginOptions)
        let request = StorageListRequest(options: options)

        let storageErrorOptional = request.validate()

        XCTAssertNil(storageErrorOptional)
    }

    func testValidateEmptyTargetIdentityIdError() {
        let options = StorageListRequest.Options(accessLevel: .protected,
                                                 targetIdentityId: "",
                                                 path: testPath,
                                                 pluginOptions: testPluginOptions)
        let request = StorageListRequest(options: options)

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
        let options = StorageListRequest.Options(accessLevel: .private,
                                                 targetIdentityId: testTargetIdentityId,
                                                 path: testPath,
                                                 pluginOptions: testPluginOptions)
        let request = StorageListRequest(options: options)

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
        let options = StorageListRequest.Options(accessLevel: .protected,
                                                 targetIdentityId: testTargetIdentityId,
                                                 path: "",
                                                 pluginOptions: testPluginOptions)
        let request = StorageListRequest(options: options)

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
