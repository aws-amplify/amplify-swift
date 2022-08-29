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

        XCTAssertNotNil(operation)

        wait(for: [done], timeout: 1.0)
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
}
