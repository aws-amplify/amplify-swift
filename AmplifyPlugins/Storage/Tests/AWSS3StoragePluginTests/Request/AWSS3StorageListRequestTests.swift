//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
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

    /// - Given: A an options parameter containing pagination options
    /// - When: The containing request is validated
    /// - Then: No errors are raised
    func testValidateWithPaginationOptions() {
        let pageSizeOnly = StorageListRequest(options: StorageListRequest.Options(pageSize: UInt.random(in: 1..<1_000)))
        XCTAssertNil(pageSizeOnly.validate())

        let nextTokenOnly = StorageListRequest(options: StorageListRequest.Options(nextToken: UUID().uuidString))
        XCTAssertNil(nextTokenOnly.validate())

        let pageSizeAndNextToken = StorageListRequest(options: StorageListRequest.Options(
            pageSize: UInt.random(in: 1..<1_000),
            nextToken: UUID().uuidString
        ))
        XCTAssertNil(pageSizeAndNextToken.validate())
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

        guard case .validation(let field, let description, let recovery, _) = error else {
            XCTFail("Error does not match validation error")
            return
        }

        XCTAssertEqual(field, StorageErrorConstants.identityIdIsEmpty.field)
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

        guard case .validation(let field, let description, let recovery, _) = error else {
            XCTFail("Error does not match validation error")
            return
        }

        XCTAssertEqual(field, StorageErrorConstants.invalidAccessLevelWithTarget.field)
        XCTAssertEqual(description, StorageErrorConstants.invalidAccessLevelWithTarget.errorDescription)
        XCTAssertEqual(recovery, StorageErrorConstants.invalidAccessLevelWithTarget.recoverySuggestion)
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

        guard case .validation(let field, let description, let recovery, _) = error else {
            XCTFail("Error does not match validation error")
            return
        }

        XCTAssertEqual(field, StorageErrorConstants.pathIsEmpty.field)
        XCTAssertEqual(description, StorageErrorConstants.pathIsEmpty.errorDescription)
        XCTAssertEqual(recovery, StorageErrorConstants.pathIsEmpty.recoverySuggestion)
    }
}
