//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSS3
import AWSS3StoragePlugin
import Combine
import XCTest

// swiftlint:disable:next type_name
// `@unchecked Sendable`: `XCTestCase` is not `Sendable`, but the test body is captured by the
// `@Sendable` closures the API now takes. XCTest runs one test at a time.
class AWSS3StoragePluginUploadDataResumabilityTests: AWSS3StoragePluginTestBase, @unchecked Sendable {
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

    /// Given: A data object with more parts than the upload runs at once
    /// When:
    ///    - the upload is paused right after a part completes, while the session prepares the next part
    ///      (partial file and presign), and resumed two seconds later
    ///    - three times over
    /// Then:
    ///    - the upload completes (#4407 item G: a part still being prepared at pause was never restarted)
    ///
    func testUploadLargeDataAndPauseWhilePartIsPrepared_shouldComplete() async throws {
        let key = UUID().uuidString
        // More parts than the session runs at once (2 per core), so each completed part queues the next one.
        let partCount = ProcessInfo.processInfo.activeProcessorCount * 2 + 8
        let data = Data(repeating: 0xff, count: 5 * 1_024 * 1_024 * partCount)
        Self.logger.debug("Uploading \(partCount) parts")
        let task = Amplify.Storage.uploadData(key: key, data: data)

        var progress = await task.progress.makeAsyncIterator()
        for cycle in 1 ... 3 {
            guard await progress.next() != nil else {
                XCTFail("Upload ended before pause \(cycle)")
                break
            }
            Self.logger.debug("Pausing upload task (\(cycle))")
            task.pause()
            // Longer than a part upload, so a part request sent while paused also finishes while paused.
            try await Task.sleep(seconds: 2)
            Self.logger.debug("Resuming upload task (\(cycle))")
            task.resume()
        }

        let finished = expectation(description: "Upload finished")
        let outcome = Task { () -> Result<String, Error> in
            defer { finished.fulfill() }
            do {
                return try await .success(task.value)
            } catch {
                return .failure(error)
            }
        }
        // A part left `.queued` is never restarted, so the upload can hang rather than fail.
        guard await XCTWaiter().fulfillment(of: [finished], timeout: 120) == .completed else {
            XCTFail("Upload did not finish after pause and resume")
            task.cancel()
            return
        }
        let uploadedKey = try await outcome.value.get()
        XCTAssertEqual(uploadedKey, key)

        // clean up
        await remove(key: key)
    }
}
