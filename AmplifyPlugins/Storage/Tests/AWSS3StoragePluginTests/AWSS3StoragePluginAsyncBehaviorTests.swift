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
