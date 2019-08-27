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

    func testNotConfiguredThrowsExceptionForGet() {
        let storagePlugin = AWSS3StoragePlugin()

        let exception: BadInstructionException? = catchBadInstruction {
            _ = storagePlugin.get(key: "key", options: nil, onComplete: nil)
        }

        XCTAssertNotNil(exception)
    }

    func testNotConfiguredThrowsExceptionForGetWithLocalUrl() {
        let storagePlugin = AWSS3StoragePlugin()
        let url = URL(fileURLWithPath: "path")

        let exception: BadInstructionException? = catchBadInstruction {
            _ = storagePlugin.get(key: "key", local: url, options: nil, onComplete: nil)
        }

        XCTAssertNotNil(exception)
    }

    func testNotConfiguredThrowsExceptionForPut() {
        let storagePlugin = AWSS3StoragePlugin()
        let data = Data()

        let exception: BadInstructionException? = catchBadInstruction {
            _ = storagePlugin.put(key: "key", data: data, options: nil, onComplete: nil)
        }

        XCTAssertNotNil(exception)
    }

    func testNotConfiguredThrowsExceptionForPutWithLocalUrl() {
        let storagePlugin = AWSS3StoragePlugin()
        let url = URL(fileURLWithPath: "path")

        let exception: BadInstructionException? = catchBadInstruction {
            _ = storagePlugin.put(key: "key", local: url, options: nil, onComplete: nil)
        }

        XCTAssertNotNil(exception)
    }

    func testNotConfiguredThrowsExceptionForRemove() {
        let storagePlugin = AWSS3StoragePlugin()

        let exception: BadInstructionException? = catchBadInstruction {
            _ = storagePlugin.remove(key: "key", options: nil, onComplete: nil)
        }

        XCTAssertNotNil(exception)
    }

    func testNotConfiguredThrowsExceptionForList() {
        let storagePlugin = AWSS3StoragePlugin()

        let exception: BadInstructionException? = catchBadInstruction {
            _ = storagePlugin.list(options: nil, onComplete: nil)
        }

        XCTAssertNotNil(exception)
    }

    // MARK: Get API Tests
    func testPluginGet() {
        // Arrange
        storagePlugin.configure(storageService: service, bucket: bucket, queue: queue)
        let expectedKey = "public/" + key

        // Act
        let result = storagePlugin.get(key: key, options: nil, onComplete: nil)

        // Assert
        XCTAssertNotNil(result)
        guard let awss3StorageGetOperation = result as? AWSS3StorageGetOperation else {
            XCTFail("operation could not be cast as AWSS3StorageGetOperation")
            return
        }
        let request = awss3StorageGetOperation.request
        XCTAssertNotNil(request)
        XCTAssertEqual(request.bucket, bucket)
        XCTAssertEqual(request.key, expectedKey)
        XCTAssertNil(request.fileURL)
    }

    func testPluginGetWithOptions() {
        // Arrange
        let accessLevel = AccessLevel.Private
        let options = StorageGetOption(accessLevel: accessLevel, options: nil)
        storagePlugin.configure(storageService: service, bucket: bucket, queue: queue)
        let expectedKey = accessLevel.rawValue + "/" + key

        // Act
        let result = storagePlugin.get(key: key, options: options, onComplete: nil)

        // Assert
        XCTAssertNotNil(result)
        guard let awss3StorageGetOperation = result as? AWSS3StorageGetOperation else {
            XCTFail("operation could not be cast as AWSS3StorageGetOperation")
            return
        }
        let request = awss3StorageGetOperation.request
        XCTAssertNotNil(request)
        XCTAssertEqual(request.bucket, bucket)
        XCTAssertEqual(request.key, expectedKey)
        XCTAssertNil(request.fileURL)
    }

    // MARK: GET to local file API tests
    func testPluginGetLocalFile() {
        // Arrange
        storagePlugin.configure(storageService: service, bucket: bucket, queue: queue)
        let expectedKey = "public/" + key
        let url = URL(fileURLWithPath: "path")

        // Act
        let result = storagePlugin.get(key: key, local: url, options: nil, onComplete: nil)

        // Assert
        XCTAssertNotNil(result)

        guard let awss3StorageGetOperation = result as? AWSS3StorageGetOperation else {
            XCTFail("operation not castable to ")
            return
        }
        let request = awss3StorageGetOperation.request
        XCTAssertNotNil(request)
        XCTAssertEqual(request.bucket, bucket)
        XCTAssertEqual(request.key, expectedKey)
        XCTAssertEqual(request.fileURL, url)
    }

    func testPluginGetLocalFileWithOptions() {
        // Arrange
        let accessLevel = AccessLevel.Protected
        let options = StorageGetOption(accessLevel: .Protected, options: nil)
        storagePlugin.configure(storageService: service, bucket: bucket, queue: queue)
        let expectedKey = accessLevel.rawValue + "/" + key
        let url = URL(fileURLWithPath: "path")

        // Act
        let result = storagePlugin.get(key: key, local: url, options: options, onComplete: nil)

        // Assert
        XCTAssertNotNil(result)

        guard let awss3StorageGetOperation = result as? AWSS3StorageGetOperation else {
            XCTFail("operation not castable to ")
            return
        }
        let request = awss3StorageGetOperation.request
        XCTAssertNotNil(request)
        XCTAssertEqual(request.bucket, bucket)
        XCTAssertEqual(request.key, expectedKey)
        XCTAssertEqual(request.fileURL, url)
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
