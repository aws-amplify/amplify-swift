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

class AWSS3StoragePluginAsyncBehaviorTests: AWSS3StoragePluginTests {

    override func setUp() {

        storagePlugin = AWSS3StoragePlugin()
        storageService = MockAWSS3StorageService()
        authService = MockAWSAuthService()
        let queue = OperationQueue()

        storagePlugin.configure(storageService: storageService,
                                authService: authService,
                                defaultAccessLevel: defaultAccessLevel,
                                queue: queue)
    }

    func testPluginGetURLAsync() async throws {
        let done = asyncExpectation(description: "done")
        let input = URL(string: "https://bucket.aws.amazon.com/\(testKey)")!

        Task {
            storageService.storageServiceGetPreSignedURLEvents = [.completed(input)]
            let output = try await storagePlugin.getURL(key: testKey, options: nil)
            XCTAssertEqual(input, output)
            XCTAssertEqual(1, storageService.getPreSignedURLCalled)
            await done.fulfill()
        }

        await waitForExpectations([done], timeout: 3.0)
    }

    func testPluginDownloadDataAsync() async throws {
        let done = asyncExpectation(description: "done")
        let input = "AWS".data(using: .utf8)!
        storageService.storageServiceDownloadEvents = [.completed(input)]

        Task {
            let task = try await storagePlugin.downloadData(key: testKey,
                                                            options: nil)
            let output = try await task.value
            XCTAssertEqual(input, output)
            await done.fulfill()
        }

        await waitForExpectations([done], timeout: 3.0)

        XCTAssertEqual(1, storageService.downloadCalled)
    }

    func testPluginDownloadFileAsync() async throws {
        let done = asyncExpectation(description: "done")
        storageService.storageServiceDownloadEvents = [.completed(nil)]
        
        Task {
            let task = try await storagePlugin.downloadFile(key: testKey,
                                                            local: testURL,
                                                            options: nil)
            do {
                _ = try await task.value
            } catch {
                XCTFail("Error: \(error)")
            }
            await done.fulfill()
        }

        await waitForExpectations([done], timeout: 3.0)

        XCTAssertEqual(1, storageService.downloadCalled)
    }

    func testPluginUploadDataAsync() async throws {
        let done = asyncExpectation(description: "done")
        storageService.storageServiceUploadEvents = [.completedVoid]
        let input = testKey

        Task {
            let task = try await storagePlugin.uploadData(key: input,
                                                          data: testData,
                                                          options: nil)
            do {
                let output = try await task.value
                XCTAssertEqual(input, output)
            } catch {
                XCTFail("Error: \(error)")
            }
            await done.fulfill()

        }

        await waitForExpectations([done], timeout: 3.0)

        XCTAssertEqual(1, storageService.uploadCalled)
    }

    func testPluginUploadFileAsync() async throws {
        let done = asyncExpectation(description: "done")
        storageService.storageServiceUploadEvents = [.completedVoid]
        let input = testKey
        let fileURL = try FileSystem.default.createTemporaryFile(data: "Amplify".data(using: .utf8)!)
        defer {
            FileSystem.default.removeFileIfExists(fileURL: fileURL)
        }

        Task {
            let task = try await storagePlugin.uploadFile(key: input,
                                                          local: fileURL,
                                                          options: nil)
            do {
                let output = try await task.value
                XCTAssertEqual(input, output)
            } catch {
                XCTFail("Error: \(error)")
            }
            await done.fulfill()

        }

        await waitForExpectations([done], timeout: 3.0)

        XCTAssertEqual(1, storageService.uploadCalled)
    }

    func testPluginRemoveAsync() async throws {
        let done = asyncExpectation(description: "done")
        storageService.storageServiceDeleteEvents = [.completed(())]
        let input = testKey

        Task {
            let output = try await storagePlugin.remove(key: input, options: nil)
            XCTAssertEqual(input, output)
            XCTAssertEqual(1, storageService.deleteCalled)
            await done.fulfill()
        }

        await waitForExpectations([done])
    }

    func testPluginListAsync() async throws  {
        let done = asyncExpectation(description: "done")
        let item = StorageListResult.Item(key: testKey)
        let input = StorageListResult(items: [item])

        Task {
            storageService.storageServiceListEvents = [.completed(input)]
            let output = try await storagePlugin.list(options: nil)
            XCTAssertEqual(input.items.first?.key, output.items.first?.key)
            XCTAssertEqual(1, storageService.listCalled)
            await done.fulfill()
        }

        await waitForExpectations([done], timeout: 3.0)
    }

}
