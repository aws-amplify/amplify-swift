//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import CwlPreconditionTesting
import Amplify
@testable import AWSS3StoragePlugin

class AWSS3StoragePluginTests: XCTestCase {
    var storagePlugin: AWSS3StoragePlugin!
    var storageService: MockAWSS3StorageService!
    var authService: MockAWSAuthService!
    var queue: MockOperationQueue!
    let testKey = "key"
    let bucket = "bucket"
    let defaultAccessLevel: StorageAccessLevel = .public
    let testIdentityId = "TestIdentityId"

    override func setUp() {
        storagePlugin = AWSS3StoragePlugin()
        storageService = MockAWSS3StorageService()
        authService = MockAWSAuthService()
        queue = MockOperationQueue()

        storagePlugin.configure(bucket: bucket,
                                storageService: storageService,
                                authService: authService,
                                queue: queue,
                                defaultAccessLevel: defaultAccessLevel)
    }

    // MARK: configuration tests
    func testConfigureThrowsErrorForMissingBucket() {
    }

    func testConfigureThrowsErrorForMissingRegion() {
    }

    // MARK: Get API Tests
    func testPluginGet() {
        // Act
        let operation = storagePlugin.get(key: testKey, options: nil, onEvent: nil)

        // Assert
        XCTAssertNotNil(operation)
        guard let awss3StorageGetOperation = operation as? AWSS3StorageGetOperation else {
            XCTFail("operation could not be cast as AWSS3StorageGetOperation")
            return
        }
        let request = awss3StorageGetOperation.request

        XCTAssertNotNil(request)
        XCTAssertEqual(request.accessLevel, defaultAccessLevel)
        XCTAssertNil(request.targetIdentityId)
        XCTAssertEqual(request.key, testKey)
        //XCTAssertEqual(request.storageGetDestination, StorageGetDestination.url(expires: nil))
        XCTAssertNil(request.options)
    }

    func testPluginGetWithOptions() {
        // Arrange
        let privateAccessLevel = StorageAccessLevel.private
        let storageDestination = StorageGetDestination.data
        // TODO: test adding options.options.
        let options = StorageGetOption(accessLevel: privateAccessLevel,
                                       targetIdentityId: testIdentityId,
                                       storageGetDestination: storageDestination,
                                       options: nil)
        // Act
        let operation = storagePlugin.get(key: testKey, options: options, onEvent: nil)

        // Assert
        XCTAssertNotNil(operation)
        guard let awss3StorageGetOperation = operation as? AWSS3StorageGetOperation else {
            XCTFail("operation could not be cast as AWSS3StorageGetOperation")
            return
        }
        let request = awss3StorageGetOperation.request

        XCTAssertNotNil(request)
        XCTAssertNotEqual(request.accessLevel, defaultAccessLevel)
        XCTAssertEqual(request.accessLevel, privateAccessLevel)
        XCTAssertEqual(request.targetIdentityId, testIdentityId)
        XCTAssertEqual(request.key, testKey)
        //XCTAssertEqual(request.storageGetDestination, StorageGetDestination.url(expires: nil))
        //XCTAssertNotNil(request.options)
    }

    // MARK: GetURL API tests
    func testPluginGetUrl() {
    }

    func testPluginGetUrlWithOptions() {
    }

    // MARK: Put API tests
    func testPluginPut() {

    }

    func testPluginPutWithOptions() {

    }

    // MARK: Put to local file API tests
    func testPluginPutToLocalFile() {

    }

    func testPluginPutToLocalFileWithOptions() {

    }

    // MARK: Remove API tests
    func testPluginRemove() {

    }

    func testPluginRemoveWithOptions() {

    }

    // MARK: List API tests
    func testPluginList() {

    }

    func testPluginListWithOptions() {

    }
}
