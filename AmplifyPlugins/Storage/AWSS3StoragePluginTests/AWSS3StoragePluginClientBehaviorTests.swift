//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import Amplify
@testable import AWSS3StoragePlugin

// swiftlint:disable:next type_body_length
class AWSS3StoragePluginClientBehaviorTests: AWSS3StoragePluginTests {

    // MARK: GetURL API Tests

    func testPluginGetURL() {
        let operation = storagePlugin.getURL(key: testKey, options: nil)

        XCTAssertNotNil(operation)
        guard let awss3StorageGetURLOperation = operation as? AWSS3StorageGetURLOperation else {
            XCTFail("operation could not be cast as AWSS3StorageGetURLOperation")
            return
        }

        let request = awss3StorageGetURLOperation.request
        XCTAssertNotNil(request)
        XCTAssertEqual(request.options.accessLevel, defaultAccessLevel)
        XCTAssertNil(request.options.targetIdentityId)
        XCTAssertEqual(request.key, testKey)
        XCTAssertEqual(request.options.expires, StorageGetURLRequest.Options.defaultExpireInSeconds)
        XCTAssertEqual(queue.size, 1)
    }

    func testPluginGetURLWithOptions() {
        let options = StorageGetURLRequest.Options(accessLevel: .private,
                                                   targetIdentityId: testIdentityId,
                                                   expires: testExpires,
                                                   pluginOptions: [:])

        let operation = storagePlugin.getURL(key: testKey, options: options)

        XCTAssertNotNil(operation)
        guard let awss3StorageGetURLOperation = operation as? AWSS3StorageGetURLOperation else {
            XCTFail("operation could not be cast as AWSS3StorageGetURLOperation")
            return
        }
        let request = awss3StorageGetURLOperation.request
        XCTAssertNotNil(request)
        XCTAssertNotEqual(request.options.accessLevel, defaultAccessLevel)
        XCTAssertEqual(request.options.accessLevel, .private)
        XCTAssertEqual(request.options.targetIdentityId, testIdentityId)
        XCTAssertEqual(request.key, testKey)
        XCTAssertEqual(request.options.expires, testExpires)

        XCTAssertEqual(queue.size, 1)
    }

    // MARK: DownloadData API Tests

    func testPluginDownloadData() {
        let operation = storagePlugin.downloadData(key: testKey,
                                                   options: nil,
                                                   progressListener: nil,
                                                   resultListener: nil)

        XCTAssertNotNil(operation)
        guard let awss3StorageDownloadDataOperation = operation as? AWSS3StorageDownloadDataOperation else {
            XCTFail("operation could not be cast as AWSS3StorageDownloadDataOperation")
            return
        }

        let request = awss3StorageDownloadDataOperation.request
        XCTAssertNotNil(request)
        XCTAssertEqual(request.options.accessLevel, defaultAccessLevel)
        XCTAssertNil(request.options.targetIdentityId)
        XCTAssertEqual(request.key, testKey)
        XCTAssertEqual(queue.size, 1)
    }

    func testPluginGetWithOptions() {
        let options = StorageDownloadDataRequest.Options(accessLevel: .private,
                                                         targetIdentityId: testIdentityId,
                                                         pluginOptions: [:])

        let operation = storagePlugin.downloadData(key: testKey,
                                                   options: options,
                                                   progressListener: nil,
                                                   resultListener: nil)

        XCTAssertNotNil(operation)
        guard let awss3StorageDownloadDataOperation = operation as? AWSS3StorageDownloadDataOperation else {
            XCTFail("operation could not be cast as AWSS3StorageDownloadDataOperation")
            return
        }
        let request = awss3StorageDownloadDataOperation.request
        XCTAssertNotNil(request)
        XCTAssertNotEqual(request.options.accessLevel, defaultAccessLevel)
        XCTAssertEqual(request.options.accessLevel, .private)
        XCTAssertEqual(request.options.targetIdentityId, testIdentityId)
        XCTAssertEqual(request.key, testKey)
        XCTAssertEqual(queue.size, 1)
    }

    // MARK: DownloadFile API Tests

    func testPluginDownloadFile() {
        let operation = storagePlugin.downloadFile(key: testKey,
                                                   local: testURL,
                                                   options: nil,
                                                   progressListener: nil,
                                                   resultListener: nil)

        XCTAssertNotNil(operation)
        guard let awss3StorageDownloadFileOperation = operation as? AWSS3StorageDownloadFileOperation else {
            XCTFail("operation could not be cast as AWSS3StorageDownloadFileOperation")
            return
        }

        let request = awss3StorageDownloadFileOperation.request
        XCTAssertNotNil(request)
        XCTAssertEqual(request.options.accessLevel, defaultAccessLevel)
        XCTAssertNil(request.options.targetIdentityId)
        XCTAssertEqual(request.key, testKey)
        XCTAssertEqual(request.local, testURL)
        XCTAssertEqual(queue.size, 1)
    }

    func testPluginDownloadFileWithOptions() {
        let options = StorageDownloadFileRequest.Options(accessLevel: .private,
                                                         targetIdentityId: testIdentityId,
                                                         pluginOptions: [:])

        let operation = storagePlugin.downloadFile(key: testKey,
                                                   local: testURL,
                                                   options: options,
                                                   progressListener: nil,
                                                   resultListener: nil)

        XCTAssertNotNil(operation)
        guard let awss3StorageDownloadFileOperation = operation as? AWSS3StorageDownloadFileOperation else {
            XCTFail("operation could not be cast as AWSS3StorageDownloadFileOperation")
            return
        }
        let request = awss3StorageDownloadFileOperation.request
        XCTAssertNotNil(request)
        XCTAssertNotEqual(request.options.accessLevel, defaultAccessLevel)
        XCTAssertEqual(request.options.accessLevel, .private)
        XCTAssertEqual(request.options.targetIdentityId, testIdentityId)
        XCTAssertEqual(request.key, testKey)
        XCTAssertEqual(request.local, testURL)
        XCTAssertEqual(queue.size, 1)
    }

    // MARK: UploadData API tests

    func testPluginUploadData() {
        let operation = storagePlugin.uploadData(key: testKey,
                                                 data: testData,
                                                 options: nil,
                                                 progressListener: nil,
                                                 resultListener: nil)

        XCTAssertNotNil(operation)
        guard let awss3StorageUploadDataOperation = operation as? AWSS3StorageUploadDataOperation else {
            XCTFail("operation could not be cast as AWSS3StorageUploadDataOperation")
            return
        }
        let request = awss3StorageUploadDataOperation.request
        XCTAssertNotNil(request)
        XCTAssertEqual(request.options.accessLevel, defaultAccessLevel)
        XCTAssertEqual(request.key, testKey)
        XCTAssertNil(request.options.contentType)
        XCTAssertNil(request.options.metadata)
        XCTAssertNil(request.options.pluginOptions)
        XCTAssertEqual(request.data, testData)
        XCTAssertEqual(queue.size, 1)
    }

    func testPluginUploadDataWithOptions() {
        let options = StorageUploadDataRequest.Options(accessLevel: .private,
                                                       metadata: [:],
                                                       contentType: testContentType,
                                                       pluginOptions: [:])

        let operation = storagePlugin.uploadData(key: testKey,
                                                 data: testData,
                                                 options: options,
                                                 progressListener: nil,
                                                 resultListener: nil)

        XCTAssertNotNil(operation)
        guard let awss3StorageUploadDataOperation = operation as? AWSS3StorageUploadDataOperation else {
            XCTFail("operation could not be cast as AWSS3StorageUploadDataOperation")
            return
        }
        let request = awss3StorageUploadDataOperation.request
        XCTAssertNotNil(request)
        XCTAssertNotEqual(request.options.accessLevel, defaultAccessLevel)
        XCTAssertEqual(request.options.accessLevel, .private)
        XCTAssertEqual(request.key, testKey)
        XCTAssertNotNil(request.options.contentType)
        XCTAssertEqual(request.options.contentType, testContentType)
        XCTAssertNotNil(request.options.metadata)
        XCTAssertNotNil(request.options.pluginOptions)
        XCTAssertEqual(request.data, testData)
        XCTAssertEqual(queue.size, 1)
    }

    // MARK: UploadFile API tests

    func testPluginUploadFile() {
        let operation = storagePlugin.uploadFile(key: testKey,
                                                 local: testURL,
                                                 options: nil,
                                                 progressListener: nil,
                                                 resultListener: nil)

        XCTAssertNotNil(operation)
        guard let awss3StorageUploadFileOperation = operation as? AWSS3StorageUploadFileOperation else {
            XCTFail("operation could not be cast as AWSS3StorageUploadDataOperation")
            return
        }
        let request = awss3StorageUploadFileOperation.request
        XCTAssertNotNil(request)
        XCTAssertEqual(request.options.accessLevel, defaultAccessLevel)
        XCTAssertEqual(request.key, testKey)
        XCTAssertNil(request.options.contentType)
        XCTAssertNil(request.options.metadata)
        XCTAssertNil(request.options.pluginOptions)
        XCTAssertEqual(request.local, testURL)

        XCTAssertEqual(queue.size, 1)
    }

    func testPluginUploadFileWithOptions() {
        let options = StorageUploadFileRequest.Options(accessLevel: .private,
                                                       metadata: [:],
                                                       contentType: testContentType,
                                                       pluginOptions: [:])

        let operation = storagePlugin.uploadFile(key: testKey,
                                                 local: testURL,
                                                 options: options,
                                                 progressListener: nil,
                                                 resultListener: nil)

        XCTAssertNotNil(operation)
        guard let awss3StorageUploadFileOperation = operation as? AWSS3StorageUploadFileOperation else {
            XCTFail("operation could not be cast as AWSS3StorageUploadDataOperation")
            return
        }
        let request = awss3StorageUploadFileOperation.request
        XCTAssertNotNil(request)
        XCTAssertNotEqual(request.options.accessLevel, defaultAccessLevel)
        XCTAssertEqual(request.options.accessLevel, .private)
        XCTAssertEqual(request.key, testKey)
        XCTAssertNotNil(request.options.contentType)
        XCTAssertEqual(request.options.contentType, testContentType)
        XCTAssertNotNil(request.options.metadata)
        XCTAssertNotNil(request.options.pluginOptions)
        XCTAssertEqual(request.local, testURL)

        XCTAssertEqual(queue.size, 1)
    }

    // MARK: Remove API tests

    func testPluginRemove() {
        let operation = storagePlugin.remove(key: testKey, options: nil)

        XCTAssertNotNil(operation)
        guard let awss3StorageRemoveOperation = operation as? AWSS3StorageRemoveOperation else {
            XCTFail("operation could not be cast as AWSS3StorageRemoveOperation")
            return
        }
        let request = awss3StorageRemoveOperation.request
        XCTAssertNotNil(request)
        XCTAssertEqual(request.options.accessLevel, defaultAccessLevel)
        XCTAssertEqual(request.key, testKey)
        XCTAssertNil(request.options.pluginOptions)
        XCTAssertEqual(queue.size, 1)
    }

    func testPluginRemoveWithOptions() {
        let options = StorageRemoveRequest.Options(accessLevel: .private, pluginOptions: [:])

        let operation = storagePlugin.remove(key: testKey, options: options)

        XCTAssertNotNil(operation)
        guard let awss3StorageRemoveOperation = operation as? AWSS3StorageRemoveOperation else {
            XCTFail("operation could not be cast as AWSS3StorageRemoveOperation")
            return
        }
        let request = awss3StorageRemoveOperation.request
        XCTAssertNotNil(request)
        XCTAssertNotEqual(request.options.accessLevel, defaultAccessLevel)
        XCTAssertEqual(request.options.accessLevel, .private)
        XCTAssertEqual(request.key, testKey)
        XCTAssertNotNil(request.options.pluginOptions)
        XCTAssertEqual(queue.size, 1)
    }

    // MARK: List API tests

    func testPluginList() {
        let operation = storagePlugin.list(options: nil)

        XCTAssertNotNil(operation)
        guard let awss3StorageListOperation = operation as? AWSS3StorageListOperation else {
            XCTFail("operation could not be cast as AWSS3StoragelistOperation")
            return
        }
        let request = awss3StorageListOperation.request
        XCTAssertNotNil(request)
        XCTAssertEqual(request.options.accessLevel, defaultAccessLevel)
        XCTAssertNil(request.options.path)
        XCTAssertNil(request.options.pluginOptions)
        XCTAssertEqual(queue.size, 1)
    }

    func testPluginListWithOptions() {
        let options = StorageListRequest.Options(accessLevel: .private,
                                                 targetIdentityId: testIdentityId,
                                                 path: testPath,
                                                 pluginOptions: [:])

        let operation = storagePlugin.list(options: options)

        XCTAssertNotNil(operation)
        guard let awss3StorageListOperation = operation as? AWSS3StorageListOperation else {
            XCTFail("operation could not be cast as AWSS3StoragelistOperation")
            return
        }
        let request = awss3StorageListOperation.request
        XCTAssertNotNil(request)
        XCTAssertNotEqual(request.options.accessLevel, defaultAccessLevel)
        XCTAssertEqual(request.options.accessLevel, .private)
        XCTAssertNotNil(request.options.targetIdentityId, testIdentityId)
        XCTAssertEqual(request.options.path, testPath)
        XCTAssertNotNil(request.options.pluginOptions)
        XCTAssertEqual(queue.size, 1)
    }
}
