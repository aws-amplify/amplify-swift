//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import Amplify
@testable import AWSS3StoragePlugin
@testable import AmplifyTestCommon
@testable import AWSPluginsTestCommon

class AWSS3StoragePluginAsyncBehaviorTests: XCTestCase {

    var storagePlugin: AWSS3StoragePlugin!
    var storageService: MockAWSS3StorageService!
    var authService: MockAWSAuthService!
    var testKey: String!
    var testURL: URL!
    var testData: Data!
    var queue: OperationQueue!

    let defaultAccessLevel: StorageAccessLevel = .guest

    override func setUpWithError() throws {
        storagePlugin = AWSS3StoragePlugin()
        storageService = MockAWSS3StorageService()
        authService = MockAWSAuthService()
        testKey = UUID().uuidString
        testURL = URL(fileURLWithPath: NSTemporaryDirectory().appendingPathComponent(UUID().uuidString))
        testData = Data(UUID().uuidString.utf8)
        queue = OperationQueue()
        storagePlugin.configure(storageService: storageService,
                                authService: authService,
                                defaultAccessLevel: defaultAccessLevel,
                                queue: queue)
    }

    override func tearDownWithError() throws {
        queue.cancelAllOperations()

        storagePlugin = nil
        storageService = nil
        authService = nil
        testKey = nil
        queue = nil
    }

    func testPluginDownloadDataAsync() async throws {
        let input = "AWS".data(using: .utf8)!
        storageService.storageServiceDownloadEvents = [.completed(input)]

        let task = storagePlugin.downloadData(key: testKey, options: nil)
        let output = try await task.value
        XCTAssertEqual(input, output)
        XCTAssertEqual(1, storageService.downloadCalled)
    }

    func testPluginDownloadFileAsync() async throws {
        storageService.storageServiceDownloadEvents = [.completed(nil)]
        
        let task = storagePlugin.downloadFile(key: testKey,
                                              local: testURL,
                                              options: nil)
        _ = try await task.value
        XCTAssertEqual(1, storageService.downloadCalled)
    }

    func testPluginUploadDataAsync() async throws {
        storageService.storageServiceUploadEvents = [.completedVoid]
        let input = try XCTUnwrap(testKey)
        let task = storagePlugin.uploadData(key: input,
                                            data: testData,
                                            options: nil)
        let output = try await task.value
        XCTAssertEqual(input, output)
        XCTAssertEqual(1, storageService.uploadCalled)
    }

    func testPluginUploadFileAsync() async throws {
        storageService.storageServiceUploadEvents = [.completedVoid]
        let key = try XCTUnwrap(testKey)
        let fileURL = try FileSystem.default.createTemporaryFile(data: Data("Amplify".utf8))
        defer {
            FileSystem.default.removeFileIfExists(fileURL: fileURL)
        }

        let task = storagePlugin.uploadFile(key: key,
                                            local: fileURL,
                                            options: nil)
        let output = try await task.value
        XCTAssertEqual(key, output)
        XCTAssertEqual(1, storageService.uploadCalled)
    }

    func testPluginRemoveAsync() async throws {
        storageService.storageServiceDeleteEvents = [.completed(())]
        let key = try XCTUnwrap(testKey)
        let output = try await storagePlugin.remove(key: key, options: nil)
        XCTAssertEqual(key, output)
        XCTAssertEqual(1, storageService.deleteCalled)
    }

    func testPluginListAsync() async throws  {
        let testKey = UUID().uuidString
        let item = StorageListResult.Item(key: testKey)
        storageService.listHandler = { (_, _) in
            return .init(items: [item])
        }
        let output = try await storagePlugin.list(options: nil)
        XCTAssertEqual(1, output.items.count, String(describing: output))
        XCTAssertEqual(testKey, output.items.first?.key)
        XCTAssertEqual(1, storageService.interactions.count)
    }

}
