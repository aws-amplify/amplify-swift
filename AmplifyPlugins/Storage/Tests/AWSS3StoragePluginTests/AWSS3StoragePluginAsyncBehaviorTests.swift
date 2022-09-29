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

    func testPluginGetURLListener() {
        let done = expectation(description: "done")
        let input = URL(string: "https://bucket.aws.amazon.com/\(testKey)")!
        storageService.storageServiceGetPreSignedURLEvents = [.completed(input)]
        let operation = storagePlugin.getURL(key: testKey, options: nil) { result in
            do {
                let output = try result.get()
                XCTAssertEqual(input, output)
            } catch {
                XCTFail("Error: \(error)")
            }
            done.fulfill()
        }
        wait(for: [done], timeout: 1.0)

        XCTAssertEqual(1, storageService.getPreSignedURLCalled)

        _ = operation
    }

    func testPluginGetURLAsync() async throws {
        let done = expectation(description: "done")
        let input = URL(string: "https://bucket.aws.amazon.com/\(testKey)")!

        Task {
            storageService.storageServiceGetPreSignedURLEvents = [.completed(input)]
            let output = try await storagePlugin.getURL(key: testKey, options: nil)
            XCTAssertEqual(input, output)
            XCTAssertEqual(1, storageService.getPreSignedURLCalled)
            done.fulfill()
        }

        await waitForExpectations(timeout: 3)
    }

    func testPluginDownloadDataListener() {
        let done = expectation(description: "done")
        let input = "AWS".data(using: .utf8)!
        storageService.storageServiceDownloadEvents = [.completed(input)]
        let operation = storagePlugin.downloadData(key: testKey,
                                                   options: nil,
                                                   progressListener: nil) { result in
            do {
                let output = try result.get()
                XCTAssertEqual(input, output)
            } catch {
                XCTFail("Error: \(error)")
            }
            done.fulfill()
        }

        wait(for: [done], timeout: 1.0)

        XCTAssertEqual(1, storageService.downloadCalled)

        _ = operation
    }

    func testPluginDownloadDataAsync() async throws {
        let done = expectation(description: "done")
        let input = "AWS".data(using: .utf8)!
        storageService.storageServiceDownloadEvents = [.completed(input)]

        Task {
            let task = try await storagePlugin.downloadData(key: testKey,
                                                            options: nil)
            let output = try await task.value
            XCTAssertEqual(input, output)
            done.fulfill()
        }

        await waitForExpectations(timeout: 3)

        XCTAssertEqual(1, storageService.downloadCalled)
    }

    func testPluginDownloadFileListener() {
        let done = expectation(description: "done")
        storageService.storageServiceDownloadEvents = [.completed(nil)]
        let operation = storagePlugin.downloadFile(key: testKey,
                                                   local: testURL,
                                                   options: nil,
                                                   progressListener: nil) { result in
            do {
                _ = try result.get()
            } catch {
                XCTFail("Error: \(error)")
            }
            done.fulfill()
        }

        wait(for: [done], timeout: 1.0)

        XCTAssertEqual(1, storageService.downloadCalled)

        _ = operation
    }

    func testPluginDownloadFileAsync() async throws {
        let done = expectation(description: "done")
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
            done.fulfill()
        }

        await waitForExpectations(timeout: 3)
        XCTAssertEqual(1, storageService.downloadCalled)
    }

    func testPluginUploadDataListener() {
        let done = expectation(description: "done")
        storageService.storageServiceUploadEvents = [.completedVoid]
        let input = testKey

        let operation = storagePlugin.uploadData(key: input,
                                                 data: testData,
                                                 options: nil,
                                                 progressListener: nil) { result in
            do {
                _ = try result.get()
            } catch {
                XCTFail("Error: \(error)")
            }
            done.fulfill()
        }

        wait(for: [done], timeout: 1.0)

        XCTAssertEqual(1, storageService.uploadCalled)

        _ = operation
    }

    func testPluginUploadDataAsync() async throws {
        let done = expectation(description: "done")
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
            done.fulfill()

        }

        await waitForExpectations(timeout: 3)

        XCTAssertEqual(1, storageService.uploadCalled)
    }

    func testPluginUploadFileListener() throws {
        let done = expectation(description: "done")
        storageService.storageServiceUploadEvents = [.completedVoid]
        let input = testKey
        let fileURL = try FileSystem.default.createTemporaryFile(data: "Amplify".data(using: .utf8)!)
        defer {
            FileSystem.default.removeFileIfExists(fileURL: fileURL)
        }

        let operation = storagePlugin.uploadFile(key: input,
                                                 local: fileURL,
                                                 options: nil,
                                                 progressListener: nil) { result in
            do {
                let output = try result.get()
                XCTAssertEqual(input, output)
            } catch {
                XCTFail("Error: \(error)")
            }
            done.fulfill()
        }

        wait(for: [done], timeout: 1.0)

        XCTAssertEqual(1, storageService.uploadCalled)

        _ = operation
    }

    func testPluginUploadFileAsync() async throws {
        let done = expectation(description: "done")
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
            done.fulfill()

        }

        await waitForExpectations(timeout: 3)

        XCTAssertEqual(1, storageService.uploadCalled)
    }

    func testPluginRemoveListener() {
        let done = expectation(description: "done")
        storageService.storageServiceDeleteEvents = [.completed(())]
        let input = testKey
        let operation = storagePlugin.remove(key: input, options: nil) { result in
            do {
                let output = try result.get()
                XCTAssertEqual(input, output)
            } catch {
                XCTFail("Error: \(error)")
            }
            done.fulfill()
        }

        wait(for: [done], timeout: 1.0)

        XCTAssertEqual(1, storageService.deleteCalled)

        _ = operation
    }

    func testPluginRemoveAsync() async throws {
        let done = expectation(description: "done")
        storageService.storageServiceDeleteEvents = [.completed(())]
        let input = testKey

        Task {
            let output = try await storagePlugin.remove(key: input, options: nil)
            XCTAssertEqual(input, output)
            XCTAssertEqual(1, storageService.deleteCalled)
            done.fulfill()
        }

        await waitForExpectations(timeout: 3)
    }

    func testPluginListListener() {
        let done = expectation(description: "done")
        let item = StorageListResult.Item(key: testKey)
        let input = StorageListResult(items: [item])

        storageService.storageServiceListEvents = [.completed(input)]
        let operation = storagePlugin.list(options: nil) { result in
            do {
                let output = try result.get()
                XCTAssertEqual(input.items.first?.key, output.items.first?.key)
            } catch {
                XCTFail("Error: \(error)")
            }
            done.fulfill()
        }

        wait(for: [done], timeout: 1.0)

        XCTAssertEqual(1, storageService.listCalled)

        _ = operation
    }

    func testPluginListAsync() async throws  {
        let done = expectation(description: "done")
        let item = StorageListResult.Item(key: testKey)
        let input = StorageListResult(items: [item])

        Task {
            storageService.storageServiceListEvents = [.completed(input)]
            let output = try await storagePlugin.list(options: nil)
            XCTAssertEqual(input.items.first?.key, output.items.first?.key)
            XCTAssertEqual(1, storageService.listCalled)
            done.fulfill()
        }

        await waitForExpectations(timeout: 3)
    }

}
