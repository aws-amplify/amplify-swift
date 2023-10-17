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
class AWSS3StoragePluginDownloadDataResumabilityTests: AWSS3StoragePluginTestBase {

    /// Given: A data object in storage
    /// When: Call the get API then pause
    /// Then: The operation is stalled (no progress, completed, or failed event)
    func testDownloadDataAndPause() async throws {
        let key = UUID().uuidString
        let data = AWSS3StoragePluginTestBase.smallDataObject
        let uploadKey = try await Amplify.Storage.uploadData(key: key, data: data).value
        XCTAssertEqual(uploadKey, key)

        Self.logger.debug("Downloading data")
        let task = Amplify.Storage.downloadData(key: key)

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

        let completeInvoked = expectation(description: "Download is completed")
        completeInvoked.isInverted = true
        let downloadTask = Task {
            let result = try await task.value
            completeInvoked.fulfill()
            return result
        }

        Self.logger.debug("Cancelling download task")
        task.cancel()
        await fulfillment(of: [completeInvoked], timeout: 1)

        let downloadData = try? await downloadTask.value
        XCTAssertNil(downloadData)

        // clean up
        Self.logger.debug("Cleaning up after download task")
        try await Amplify.Storage.remove(key: key)
    }

    /// Given: A data object in storage
    /// When: Call the downloadData API, pause, and then resume the operation
    /// Then: The operation should complete successfully
    func testDownloadDataAndPauseThenResume() async throws {
        let key = UUID().uuidString
        let data = AWSS3StoragePluginTestBase.smallDataObject
        let uploadKey = try await Amplify.Storage.uploadData(key: key, data: data).value
        XCTAssertEqual(uploadKey, key)

        let task = Amplify.Storage.downloadData(key: key)

        let progressInvoked = expectation(description: "Progress invoked")
        Task {
            var progressInvokedCalled = false
            for await progress in await task.progress {
                Self.logger.debug("Download progress: \(progress.fractionCompleted)")
                if !progressInvokedCalled, progress.fractionCompleted > 0.1 {
                    progressInvokedCalled = true
                    progressInvoked.fulfill()
                }
            }
        }
        await fulfillment(of: [progressInvoked], timeout: TestCommonConstants.networkTimeout)

        Self.logger.debug("Pausing download task")
        task.pause()

        Self.logger.debug("Sleeping")
        try await Task.sleep(seconds: 0.25)

        let completeInvoked = expectation(description: "Download is completed")
        let downloadTask = Task {
            let result = try await task.value
            completeInvoked.fulfill()
            return result
        }

        Self.logger.debug("Resuming download task")
        task.resume()

        await fulfillment(of: [completeInvoked], timeout: TestCommonConstants.networkTimeout)

        Self.logger.debug("Waiting to finish download task")
        let downloadData = try await downloadTask.value
        XCTAssertEqual(downloadData, data)

        // clean up
        Self.logger.debug("Cleaning up after download task")
        try await Amplify.Storage.remove(key: key)
    }

    /// Given: A data object in storage
    /// When: Call the get API then cancel the operation,
    /// Then: The operation should not complete or fail.
    func testDownloadDataAndCancel() async throws {
        let key = UUID().uuidString
        let data = AWSS3StoragePluginTestBase.smallDataObject
        let uploadKey = try await Amplify.Storage.uploadData(key: key, data: data).value
        XCTAssertEqual(uploadKey, key)

        Self.logger.debug("Downloading data")
        let task = Amplify.Storage.downloadData(key: key)

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

        let completeInvoked = expectation(description: "Download is completed")
        completeInvoked.isInverted = true
        let downloadTask = Task {
            let result = try await task.value
            completeInvoked.fulfill()
            return result
        }

        await fulfillment(of: [completeInvoked], timeout: 1)

        Self.logger.debug("Waiting for download to complete")
        let downloadData = try? await downloadTask.value
        XCTAssertNil(downloadData)

        // clean up
        Self.logger.debug("Cleaning up after download task")
        try await Amplify.Storage.remove(key: key)

        Self.logger.debug("Done")
    }
}
