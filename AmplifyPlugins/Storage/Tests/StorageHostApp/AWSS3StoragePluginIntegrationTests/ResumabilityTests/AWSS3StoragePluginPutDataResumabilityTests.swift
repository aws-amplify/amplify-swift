//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import Amplify
import AWSS3StoragePlugin
import AWSS3
import Combine

// swiftlint:disable:next type_name
class AWSS3StoragePluginUploadDataResumabilityTests: AWSS3StoragePluginTestBase {
    /// Given: A large data object to upload
    /// When: Call the put API and pause the operation
    /// Then: The operation is stalled (no progress, completed, or failed event)
    func testUploadLargeDataThenPause() async throws {
        let key = UUID().uuidString
        Self.logger.debug("Uploading data")
        let task = Amplify.Storage.uploadData(key: key, data: AWSS3StoragePluginTestBase.largeDataObject)

        let didPause = expectation(description: "did pause")
        let didContinue = expectation(description: "did continue")
        didContinue.isInverted = true
        Task {
            var paused = false
            var progressAfterPause = 0
            for await progress in await task.progress {
                Self.logger.debug("progress: \(progress)")
                if !paused {
                    paused = true
                    task.pause()
                    didPause.fulfill()
                } else {
                    progressAfterPause += 1
                    if progressAfterPause > 1 {
                        didContinue.fulfill()
                    }
                }
            }
        }
        await fulfillment(of: [didPause], timeout: TestCommonConstants.networkTimeout)
        await fulfillment(of: [didContinue], timeout: 5)

        let completeInvoked = expectation(description: "Upload is completed")
        completeInvoked.isInverted = true
        let uploadTask = Task {
            let result = try await task.value
            completeInvoked.fulfill()
            return result
        }

        Self.logger.debug("Cancelling upload task")
        task.cancel()
        await fulfillment(of: [completeInvoked], timeout: 1)

        let uploadKey = try? await uploadTask.value
        XCTAssertNil(uploadKey)

        // clean up
        Self.logger.debug("Cleaning up after upload task")
        try await Amplify.Storage.remove(key: key)
    }

    /// Given: A large data object to upload
    /// When: Call the put API, pause, and then resume the operation,
    /// Then: The operation should complete successfully
    func testUploadLargeDataAndPauseThenResume() async throws {
        let key = UUID().uuidString
        Self.logger.debug("Uploading data")
        let task = Amplify.Storage.uploadData(key: key, data: AWSS3StoragePluginTestBase.largeDataObject)

        let progressInvoked = expectation(description: "Progress invoked")
        Task {
            for await progress in await task.progress {
                if progress.fractionCompleted > 0.1 {
                    progressInvoked.fulfill()
                    break
                }
            }
        }
        await fulfillment(of: [progressInvoked], timeout: TestCommonConstants.networkTimeout)

        Self.logger.debug("Pausing upload task")
        task.pause()

        Self.logger.debug("Sleeping")
        try await Task.sleep(seconds: 0.25)

        let completeInvoked = expectation(description: "Upload is completed")
        let uploadTask = Task {
            let result = try await task.value
            completeInvoked.fulfill()
            return result
        }

        Self.logger.debug("Resuming upload task")
        task.resume()
        await fulfillment(of: [completeInvoked], timeout: TestCommonConstants.networkTimeout)

        Self.logger.debug("Waiting to finish upload task")
        let uploadKey = try await uploadTask.value
        XCTAssertEqual(uploadKey, key)

        // clean up
        Self.logger.debug("Cleaning up after upload task")
        try await Amplify.Storage.remove(key: key)
    }

    /// Given: A large data object to upload
    /// When: Call the put API, pause, and then resume tthe operation,
    /// Then: The operation should complete successfully
    func testUploadLargeDataAndCancel() async throws {
        let key = UUID().uuidString
        Self.logger.debug("Uploading data")
        let task = Amplify.Storage.uploadData(key: key, data: AWSS3StoragePluginTestBase.largeDataObject)

        let didCancel = expectation(description: "did cancel")
        let didContinue = expectation(description: "did continue")
        didContinue.isInverted = true
        Task {
            var cancelled = false
            var continued = false
            for await progress in await task.progress {
                if !cancelled, progress.fractionCompleted > 0.1 {
                    cancelled = true
                    task.cancel()
                    didCancel.fulfill()
                } else if cancelled, !continued, progress.fractionCompleted > 0.5 {
                    continued = true
                    didContinue.fulfill()
                }
            }
        }
        await fulfillment(of: [didCancel], timeout: TestCommonConstants.networkTimeout)
        await fulfillment(of: [didContinue], timeout: 5)

        let completeInvoked = expectation(description: "Upload is completed")
        completeInvoked.isInverted = true

        let uploadTask = Task {
            let result = try await task.value
            completeInvoked.fulfill()
            return result
        }

        await fulfillment(of: [completeInvoked], timeout: 1)

        let uploadKey = try? await uploadTask.value
        XCTAssertNil(uploadKey)

        // clean up
        Self.logger.debug("Cleaning up after upload task")
        try await Amplify.Storage.remove(key: key)
    }
}
