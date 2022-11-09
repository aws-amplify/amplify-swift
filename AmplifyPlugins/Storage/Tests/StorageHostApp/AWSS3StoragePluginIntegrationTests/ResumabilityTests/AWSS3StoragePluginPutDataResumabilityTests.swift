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
        try await testTask(timeout: 600) {
            let key = UUID().uuidString
            Self.logger.debug("Uploading data")
            let task = Amplify.Storage.uploadData(key: key, data: AWSS3StoragePluginTestBase.largeDataObject)

            let didPause = asyncExpectation(description: "did pause")
            let didContinue = asyncExpectation(description: "did continue", isInverted: true)
            Task {
                var paused = false
                var progressAfterPause = 0
                for await progress in await task.progress {
                    Self.logger.debug("progress: \(progress)")
                    if !paused {
                        paused = true
                        task.pause()
                        await didPause.fulfill()
                    } else {
                        progressAfterPause += 1
                        if progressAfterPause > 1 {
                            await didContinue.fulfill()
                        }
                    }
                }
            }
            await waitForExpectations([didPause], timeout: TestCommonConstants.networkTimeout)
            await waitForExpectations([didContinue], timeout: 5)

            let completeInvoked = asyncExpectation(description: "Upload is completed", isInverted: true)
            let uploadTask = Task {
                let result = try await task.value
                await completeInvoked.fulfill()
                return result
            }

            Self.logger.debug("Cancelling upload task")
            task.cancel()
            await waitForExpectations([completeInvoked])

            let uploadKey = try? await uploadTask.value
            XCTAssertNil(uploadKey)

            // clean up
            Self.logger.debug("Cleaning up after upload task")
            try await Amplify.Storage.remove(key: key)
        }
    }

    /// Given: A large data object to upload
    /// When: Call the put API, pause, and then resume the operation,
    /// Then: The operation should complete successfully
    func testUploadLargeDataAndPauseThenResume() async throws {
        try await testTask(timeout: 600) {
            let key = UUID().uuidString
            Self.logger.debug("Uploading data")
            let task = Amplify.Storage.uploadData(key: key, data: AWSS3StoragePluginTestBase.largeDataObject)

            let progressInvoked = asyncExpectation(description: "Progress invoked")
            Task {
                for await progress in await task.progress {
                    if progress.fractionCompleted > 0.1 {
                        await progressInvoked.fulfill()
                        break
                    }
                }
            }
            await waitForExpectations([progressInvoked], timeout: TestCommonConstants.networkTimeout)

            Self.logger.debug("Pausing upload task")
            task.pause()

            Self.logger.debug("Sleeping")
            try await Task.sleep(seconds: 0.25)

            let completeInvoked = asyncExpectation(description: "Upload is completed")
            let uploadTask = Task {
                let result = try await task.value
                await completeInvoked.fulfill()
                return result
            }

            Self.logger.debug("Resuming upload task")
            task.resume()
            await waitForExpectations([completeInvoked], timeout: TestCommonConstants.networkTimeout)

            Self.logger.debug("Waiting to finish upload task")
            let uploadKey = try await uploadTask.value
            XCTAssertEqual(uploadKey, key)

            // clean up
            Self.logger.debug("Cleaning up after upload task")
            try await Amplify.Storage.remove(key: key)
        }
    }

    /// Given: A large data object to upload
    /// When: Call the put API, pause, and then resume tthe operation,
    /// Then: The operation should complete successfully
    func testUploadLargeDataAndCancel() async throws {
        try await testTask(timeout: 600) {
            let key = UUID().uuidString
            Self.logger.debug("Uploading data")
            let task = Amplify.Storage.uploadData(key: key, data: AWSS3StoragePluginTestBase.largeDataObject)

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

            let completeInvoked = asyncExpectation(description: "Upload is completed", isInverted: true)
            let uploadTask = Task {
                let result = try await task.value
                await completeInvoked.fulfill()
                return result
            }

            await waitForExpectations([completeInvoked])

            let uploadKey = try? await uploadTask.value
            XCTAssertNil(uploadKey)

            // clean up
            Self.logger.debug("Cleaning up after upload task")
            try await Amplify.Storage.remove(key: key)
        }
    }
}
