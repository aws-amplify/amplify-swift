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
        try await testTask(timeout: 300) {
            let key = UUID().uuidString
            let data = AWSS3StoragePluginTestBase.smallDataObject
            let uploadKey = try await Amplify.Storage.uploadData(key: key, data: data).value
            XCTAssertEqual(uploadKey, key)

            Self.logger.debug("Downloading data")
            let task = try await Amplify.Storage.downloadData(key: key)

            let didPause = asyncExpectation(description: "did pause")
            let didContinue = asyncExpectation(description: "did continue", isInverted: true)
            Task {
                var paused = false
                var continued = false
                for await progress in await task.progress {
                    if !paused, progress.fractionCompleted > 0.1 {
                        paused = true
                        task.pause()
                        await didPause.fulfill()
                    } else if paused, !continued, progress.fractionCompleted > 0.5 {
                        continued = true
                        await didContinue.fulfill()
                    }
                }
            }
            await waitForExpectations([didPause], timeout: TestCommonConstants.networkTimeout)
            await waitForExpectations([didContinue], timeout: 5)

            let completeInvoked = asyncExpectation(description: "Download is completed", isInverted: true)
            let downloadTask = Task {
                let result = try await task.value
                await completeInvoked.fulfill()
                return result
            }

            Self.logger.debug("Cancelling download task")
            task.cancel()
            await waitForExpectations([completeInvoked])

            let downloadData = try? await downloadTask.value
            XCTAssertNil(downloadData)

            // clean up
            Self.logger.debug("Cleaning up after download task")
            try await Amplify.Storage.remove(key: key)
        }
    }

    /// Given: A data object in storage
    /// When: Call the downloadData API, pause, and then resume the operation
    /// Then: The operation should complete successfully
    func testDownloadDataAndPauseThenResume() async throws {
        try await testTask(timeout: 300) {
            let key = UUID().uuidString
            let data = AWSS3StoragePluginTestBase.smallDataObject
            let uploadKey = try await Amplify.Storage.uploadData(key: key, data: data).value
            XCTAssertEqual(uploadKey, key)

            let task = try await Amplify.Storage.downloadData(key: key)

            let progressInvoked = asyncExpectation(description: "Progress invoked")
            Task {
                var progressInvokedCalled = false
                for await progress in await task.progress {
                    Self.logger.debug("Download progress: \(progress.fractionCompleted)")
                    if !progressInvokedCalled, progress.fractionCompleted > 0.1 {
                        progressInvokedCalled = true
                        await progressInvoked.fulfill()
                    }
                }
            }
            await waitForExpectations([progressInvoked], timeout: TestCommonConstants.networkTimeout)

            Self.logger.debug("Pausing download task")
            task.pause()

            Self.logger.debug("Sleeping")
            try await Task.sleep(seconds: 0.25)

            let completeInvoked = asyncExpectation(description: "Download is completed")
            let downloadTask = Task {
                let result = try await task.value
                await completeInvoked.fulfill()
                return result
            }

            Self.logger.debug("Resuming download task")
            task.resume()

            await waitForExpectations([completeInvoked], timeout: TestCommonConstants.networkTimeout)

            Self.logger.debug("Waiting to finish download task")
            let downloadData = try await downloadTask.value
            XCTAssertEqual(downloadData, data)

            // clean up
            Self.logger.debug("Cleaning up after download task")
            try await Amplify.Storage.remove(key: key)
        }
    }

    /// Given: A data object in storage
    /// When: Call the get API then cancel the operation,
    /// Then: The operation should not complete or fail.
    func testDownloadDataAndCancel() async throws {
        try await testTask(timeout: 300) {
            let key = UUID().uuidString
            let data = AWSS3StoragePluginTestBase.smallDataObject
            let uploadKey = try await Amplify.Storage.uploadData(key: key, data: data).value
            XCTAssertEqual(uploadKey, key)

            Self.logger.debug("Downloading data")
            let task = try await Amplify.Storage.downloadData(key: key)

            let didCancel = asyncExpectation(description: "did cancel")
            let didContinue = asyncExpectation(description: "did continue", isInverted: true)
            Task {
                var cancelled = false
                var continued = false
                for await progress in await task.progress {
                    if !cancelled, progress.fractionCompleted > 0.1 {
                        cancelled = true
                        task.cancel()
                        await didCancel.fulfill()
                    } else if cancelled, !continued, progress.fractionCompleted > 0.5 {
                        continued = true
                        await didContinue.fulfill()
                    }
                }
            }
            await waitForExpectations([didCancel], timeout: TestCommonConstants.networkTimeout)
            await waitForExpectations([didContinue], timeout: 5)

            let completeInvoked = asyncExpectation(description: "Download is completed", isInverted: true)
            let downloadTask = Task {
                let result = try await task.value
                await completeInvoked.fulfill()
                return result
            }

            await waitForExpectations([completeInvoked])

            Self.logger.debug("Waiting for download to complete")
            let downloadData = try? await downloadTask.value
            XCTAssertNil(downloadData)

            // clean up
            Self.logger.debug("Cleaning up after download task")
            try await Amplify.Storage.remove(key: key)

            Self.logger.debug("Done")
        }
    }
}
