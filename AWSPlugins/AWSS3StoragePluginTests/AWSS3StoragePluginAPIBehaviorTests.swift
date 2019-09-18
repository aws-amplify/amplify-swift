//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import Amplify
@testable import AWSS3StoragePlugin

class AWSS3StoragePluginAPIBehaviorTests: AWSS3StoragePluginTests {

    // MARK: Get API Tests
    
    func testPluginGet() {
        let operation = storagePlugin.get(key: testKey, options: nil, onEvent: nil)

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
        guard case .url(let expires) = request.storageGetDestination else {
            XCTFail("The request destination should match default storage destination")
            return
        }

        XCTAssertNil(expires)
        XCTAssertEqual(queue.size, 1)
    }

    func testPluginGetWithOptions() {
        let options = StorageGetOptions(accessLevel: .private,
                                       targetIdentityId: testIdentityId,
                                       storageGetDestination: .data,
                                       options: [:])

        let operation = storagePlugin.get(key: testKey, options: options, onEvent: nil)

        XCTAssertNotNil(operation)
        guard let awss3StorageGetOperation = operation as? AWSS3StorageGetOperation else {
            XCTFail("operation could not be cast as AWSS3StorageGetOperation")
            return
        }
        let request = awss3StorageGetOperation.request
        XCTAssertNotNil(request)
        XCTAssertNotEqual(request.accessLevel, defaultAccessLevel)
        XCTAssertEqual(request.accessLevel, .private)
        XCTAssertEqual(request.targetIdentityId, testIdentityId)
        XCTAssertEqual(request.key, testKey)
        guard case .data = request.storageGetDestination else {
            XCTFail("The request destination should match expected storage destination")
            return
        }
        XCTAssertEqual(queue.size, 1)
    }

    // MARK: Put API tests

    func testPluginPut() {
        let operation = storagePlugin.put(key: testKey,
                                          data: testData,
                                          options: nil,
                                          onEvent: nil)

        XCTAssertNotNil(operation)
        guard let awss3StoragePutOperation = operation as? AWSS3StoragePutOperation else {
            XCTFail("operation could not be cast as AWSS3StoragePutOperation")
            return
        }
        let request = awss3StoragePutOperation.request
        XCTAssertNotNil(request)
        XCTAssertEqual(request.accessLevel, defaultAccessLevel)
        XCTAssertEqual(request.key, testKey)
        XCTAssertNil(request.contentType)
        XCTAssertNil(request.metadata)
        XCTAssertNil(request.options)
        guard case .data(let data) = request.uploadSource else {
            XCTFail("The request upload source should be data")
            return
        }
        XCTAssertEqual(data, testData)
        XCTAssertEqual(queue.size, 1)
    }

    func testPluginPutWithOptions() {
        let options = StoragePutOptions(accessLevel: .private,
                                       contentType: testContentType,
                                       metadata: [:],
                                       options: [:])

        let operation = storagePlugin.put(key: testKey,
                                          data: testData,
                                          options: options,
                                          onEvent: nil)

        XCTAssertNotNil(operation)
        guard let awss3StoragePutOperation = operation as? AWSS3StoragePutOperation else {
            XCTFail("operation could not be cast as AWSS3StoragePutOperation")
            return
        }
        let request = awss3StoragePutOperation.request
        XCTAssertNotNil(request)
        XCTAssertNotEqual(request.accessLevel, defaultAccessLevel)
        XCTAssertEqual(request.accessLevel, .private)
        XCTAssertEqual(request.key, testKey)
        XCTAssertNotNil(request.contentType)
        XCTAssertEqual(request.contentType, testContentType)
        XCTAssertNotNil(request.metadata)
        XCTAssertNotNil(request.options)
        guard case .data(let data) = request.uploadSource else {
            XCTFail("The request upload source should be data")
            return
        }
        XCTAssertEqual(data, testData)
        XCTAssertEqual(queue.size, 1)
    }

    // MARK: Put to local file API tests

    func testPluginPutToLocalFile() {
        let operation = storagePlugin.put(key: testKey,
                                          local: testURL,
                                          options: nil,
                                          onEvent: nil)

        XCTAssertNotNil(operation)
        guard let awss3StoragePutOperation = operation as? AWSS3StoragePutOperation else {
            XCTFail("operation could not be cast as AWSS3StoragePutOperation")
            return
        }
        let request = awss3StoragePutOperation.request
        XCTAssertNotNil(request)
        XCTAssertEqual(request.accessLevel, defaultAccessLevel)
        XCTAssertEqual(request.key, testKey)
        XCTAssertNil(request.contentType)
        XCTAssertNil(request.metadata)
        XCTAssertNil(request.options)
        guard case .file(let file) = request.uploadSource else {
            XCTFail("The request upload source should be url")
            return
        }
        XCTAssertEqual(file, testURL)

        XCTAssertEqual(queue.size, 1)
    }

    func testPluginPutToLocalFileWithOptions() {
        let options = StoragePutOptions(accessLevel: .private,
                                       contentType: testContentType,
                                       metadata: [:],
                                       options: [:])

        let operation = storagePlugin.put(key: testKey,
                                          local: testURL,
                                          options: options,
                                          onEvent: nil)

        XCTAssertNotNil(operation)
        guard let awss3StoragePutOperation = operation as? AWSS3StoragePutOperation else {
            XCTFail("operation could not be cast as AWSS3StoragePutOperation")
            return
        }
        let request = awss3StoragePutOperation.request
        XCTAssertNotNil(request)
        XCTAssertNotEqual(request.accessLevel, defaultAccessLevel)
        XCTAssertEqual(request.accessLevel, .private)
        XCTAssertEqual(request.key, testKey)
        XCTAssertNotNil(request.contentType)
        XCTAssertEqual(request.contentType, testContentType)
        XCTAssertNotNil(request.metadata)
        XCTAssertNotNil(request.options)
        guard case .file(let file) = request.uploadSource else {
            XCTFail("The request upload source should be url")
            return
        }
        XCTAssertEqual(file, testURL)

        XCTAssertEqual(queue.size, 1)
    }

    // MARK: Remove API tests

    func testPluginRemove() {
        let operation = storagePlugin.remove(key: testKey, options: nil, onEvent: nil)

        XCTAssertNotNil(operation)
        guard let awss3StorageRemoveOperation = operation as? AWSS3StorageRemoveOperation else {
            XCTFail("operation could not be cast as AWSS3StorageRemoveOperation")
            return
        }
        let request = awss3StorageRemoveOperation.request
        XCTAssertNotNil(request)
        XCTAssertEqual(request.accessLevel, defaultAccessLevel)
        XCTAssertEqual(request.key, testKey)
        XCTAssertNil(request.options)
        XCTAssertEqual(queue.size, 1)
    }

    func testPluginRemoveWithOptions() {
        let options = StorageRemoveOptions(accessLevel: .private, options: [:])

        let operation = storagePlugin.remove(key: testKey, options: options, onEvent: nil)

        XCTAssertNotNil(operation)
        guard let awss3StorageRemoveOperation = operation as? AWSS3StorageRemoveOperation else {
            XCTFail("operation could not be cast as AWSS3StorageRemoveOperation")
            return
        }
        let request = awss3StorageRemoveOperation.request
        XCTAssertNotNil(request)
        XCTAssertNotEqual(request.accessLevel, defaultAccessLevel)
        XCTAssertEqual(request.accessLevel, .private)
        XCTAssertEqual(request.key, testKey)
        XCTAssertNotNil(request.options)
        XCTAssertEqual(queue.size, 1)
    }

    // MARK: List API tests

    func testPluginList() {
        let operation = storagePlugin.list(options: nil, onEvent: nil)

        XCTAssertNotNil(operation)
        guard let awss3StorageListOperation = operation as? AWSS3StorageListOperation else {
            XCTFail("operation could not be cast as AWSS3StoragelistOperation")
            return
        }
        let request = awss3StorageListOperation.request
        XCTAssertNotNil(request)
        XCTAssertEqual(request.accessLevel, defaultAccessLevel)
        XCTAssertNil(request.path)
        XCTAssertNil(request.options)
        XCTAssertEqual(queue.size, 1)
    }

    func testPluginListWithOptions() {
        let options = StorageListOptions(accessLevel: .private,
                                        targetIdentityId: testIdentityId,
                                        path: testPath,
                                        options: [:])

        let operation = storagePlugin.list(options: options, onEvent: nil)

        XCTAssertNotNil(operation)
        guard let awss3StorageListOperation = operation as? AWSS3StorageListOperation else {
            XCTFail("operation could not be cast as AWSS3StoragelistOperation")
            return
        }
        let request = awss3StorageListOperation.request
        XCTAssertNotNil(request)
        XCTAssertNotEqual(request.accessLevel, defaultAccessLevel)
        XCTAssertEqual(request.accessLevel, .private)
        XCTAssertNotNil(request.targetIdentityId, testIdentityId)
        XCTAssertEqual(request.path, testPath)
        XCTAssertNotNil(request.options)
        XCTAssertEqual(queue.size, 1)
    }

    // MARK: Escape hatch

    func testGetEscapeHatch() {
        let awsS3 = storagePlugin.getEscapeHatch()
        XCTAssertNil(awsS3)
    }
}
