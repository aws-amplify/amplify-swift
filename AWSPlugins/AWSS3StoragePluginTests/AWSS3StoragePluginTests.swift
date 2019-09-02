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
    var service: MockAWSS3StorageService!
    var queue: MockOperationQueue!
    let key: String = "key"
    let bucket: String = "bucket"

    override func setUp() {
        storagePlugin = AWSS3StoragePlugin()
        service = MockAWSS3StorageService()
        queue = MockOperationQueue()

    }

    // MARK: configuration tests
    func testConfigureThrowsErrorForMissingBucket() {
    }

    func testConfigureThrowsErrorForMissingRegion() {
    }

    // MARK: Get API Tests
    func testPluginGet() {
        // Arrange
        storagePlugin.configure(storageService: service, bucket: bucket, queue: queue)
        let expectedKey = "public/" + key

        // Act
        let result = storagePlugin.get(key: key, options: nil, onEvent: nil)

        // Assert
        XCTAssertNotNil(result)
        guard let awss3StorageGetOperation = result as? AWSS3StorageGetOperation else {
            XCTFail("operation could not be cast as AWSS3StorageGetOperation")
            return
        }
        let requestBuilder = awss3StorageGetOperation.requestBuilder
        XCTAssertNotNil(requestBuilder)
        XCTAssertEqual(requestBuilder.bucket, bucket)
        XCTAssertEqual(requestBuilder.key, expectedKey)
        XCTAssertNil(requestBuilder.fileURL)
    }

    func testPluginGetWithOptions() {
        // Arrange
        let accessLevel = AccessLevel.Private
        let options = StorageGetOption(local: nil, download: nil, accessLevel: accessLevel, expires: nil,
                                       options: nil, targetUser: nil)
        storagePlugin.configure(storageService: service, bucket: bucket, queue: queue)
        let expectedKey = accessLevel.rawValue + "/" + key

        // Act
        let result = storagePlugin.get(key: key, options: options, onEvent: nil)

        // Assert
        XCTAssertNotNil(result)
        guard let awss3StorageGetOperation = result as? AWSS3StorageGetOperation else {
            XCTFail("operation could not be cast as AWSS3StorageGetOperation")
            return
        }
        let requestBuilder = awss3StorageGetOperation.requestBuilder
        XCTAssertNotNil(requestBuilder)
        XCTAssertEqual(requestBuilder.bucket, bucket)
        XCTAssertEqual(requestBuilder.key, expectedKey)
        XCTAssertNil(requestBuilder.fileURL)
    }

    // MARK: GET to local file API tests
    func testPluginGetLocalFile() {
        // Arrange
        storagePlugin.configure(storageService: service, bucket: bucket, queue: queue)
        let expectedKey = "public/" + key
        let url = URL(fileURLWithPath: "path")
        let options = StorageGetOption(local: url,
                                       download: nil,
                                       accessLevel: nil,
                                       expires: nil,
                                       options: nil,
                                       targetUser: nil)
        // Act
        let result = storagePlugin.get(key: key, options: options, onEvent: nil)

        // Assert
        XCTAssertNotNil(result)

        guard let awss3StorageGetOperation = result as? AWSS3StorageGetOperation else {
            XCTFail("operation not castable to ")
            return
        }
        let requestBuilder = awss3StorageGetOperation.requestBuilder
        XCTAssertNotNil(requestBuilder)
        XCTAssertEqual(requestBuilder.bucket, bucket)
        XCTAssertEqual(requestBuilder.key, expectedKey)
        XCTAssertEqual(requestBuilder.fileURL, url)
    }

    func testPluginGetLocalFileWithOptions() {
        // Arrange
        let accessLevel = AccessLevel.Protected
        let url = URL(fileURLWithPath: "path")
        let options = StorageGetOption(local: url, download: nil, accessLevel: accessLevel,
                                       expires: nil, options: nil, targetUser: nil)
        storagePlugin.configure(storageService: service, bucket: bucket, queue: queue)
        let expectedKey = accessLevel.rawValue + "/" + key

        // Act
        let result = storagePlugin.get(key: key, options: options, onEvent: nil)

        // Assert
        XCTAssertNotNil(result)

        guard let awss3StorageGetOperation = result as? AWSS3StorageGetOperation else {
            XCTFail("operation not castable to ")
            return
        }
        let requestBuilder = awss3StorageGetOperation.requestBuilder
        XCTAssertNotNil(requestBuilder)
        XCTAssertEqual(requestBuilder.bucket, bucket)
        XCTAssertEqual(requestBuilder.key, expectedKey)
        XCTAssertEqual(requestBuilder.fileURL, url)
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
