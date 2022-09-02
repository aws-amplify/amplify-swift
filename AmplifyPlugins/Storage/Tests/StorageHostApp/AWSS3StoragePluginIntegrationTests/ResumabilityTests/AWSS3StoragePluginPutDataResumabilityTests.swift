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
        var cancellables = Set<AnyCancellable>()
        let key = UUID().uuidString
        let progressInvoked = expectation(description: "Progress invoked")
        progressInvoked.assertForOverFulfill = false
        let task = try await Amplify.Storage.uploadData(
            key: key,
            data: AWSS3StoragePluginTestBase.largeDataObject,
            options: nil
        )

        task.inProcessPublisher.sink { progress in
            // To simulate a normal scenario, fulfill the progressInvoked expectation after some progress (30%)
            if progress.fractionCompleted > 0.3 {
                progressInvoked.fulfill()
            }
        }.store(in: &cancellables)

        await waitForExpectations(timeout: TestCommonConstants.networkTimeout)
        task.pause()
        cancellables.removeAll()

        let noProgressAfterPause = expectation(description: "Progress after pause is invoked")
        noProgressAfterPause.isInverted = true
        noProgressAfterPause.assertForOverFulfill = false
        task.inProcessPublisher.sink { progress in
            // After pausing, progress events still trickle in, but should not exceed
            if progress.fractionCompleted > 0.7 {
                XCTFail("Task should have been paused")
                noProgressAfterPause.fulfill()
            }
        }.store(in: &cancellables)

        let completeInvoked = expectation(description: "Upload is completed")
        completeInvoked.isInverted = true
        task.resultPublisher.sink(receiveCompletion: { _ in }, receiveValue: { value in
            XCTFail("Task should have been paused")
            completeInvoked.fulfill()
        })
        .store(in: &cancellables)

        await waitForExpectations(timeout: 30)
        task.cancel()
        // A 5 second sleep has been added because, the cancelling runs async task to cancel anything existing that is still running, 
        // This gives ample time for operation to cancel, and then await Amplify.reset(), Amplify.configure works as expected.
        // If the sleep is not added, await Amplify.reset() will be trigerred in the tear down method which will remove all the plugins, 
        // Removing all the plugins when operation is still cancelling, results in undesired behavior from the storage/auth plugin 
        sleep(5)
    }

    /// Given: A large data object to upload
    /// When: Call the put API, pause, and then resume the operation,
    /// Then: The operation should complete successfully
    func testUploadLargeDataAndPauseThenResume() async throws {
        var cancellables = Set<AnyCancellable>()
        let key = UUID().uuidString
        let progressInvoked = expectation(description: "Progress invoked")
        progressInvoked.assertForOverFulfill = false

        let task = try await Amplify.Storage.uploadData(
            key: key,
            data: AWSS3StoragePluginTestBase.largeDataObject,
            options: nil
        )

        task.inProcessPublisher.sink { progress in
            // To simulate a normal scenario, fulfill the progressInvoked expectation after some progress (30%)
            if progress.fractionCompleted > 0.3 {
                progressInvoked.fulfill()
            }
        }.store(in: &cancellables)

        XCTAssertNotNil(task)
        await waitForExpectations(timeout: TestCommonConstants.networkTimeout)
        task.pause()

        let completeInvoked = expectation(description: "Upload is completed")
        task.resultPublisher.sink(receiveCompletion: { result in
            switch result {
            case .finished:
                completeInvoked.fulfill()
            case .failure(let error):
                XCTFail("Failed with \(error)")
                completeInvoked.fulfill()
            }
        }, receiveValue: { _ in })
        .store(in: &cancellables)

        task.resume()
        await waitForExpectations(timeout: TestCommonConstants.networkTimeout)
    }

    /// Given: A large data object to upload
    /// When: Call the put API, pause, and then resume tthe operation,
    /// Then: The operation should complete successfully
    func testUploadLargeDataAndCancel() async throws {
        var cancellables = Set<AnyCancellable>()
        let key = UUID().uuidString
        let progressInvoked = expectation(description: "Progress invoked")
        progressInvoked.assertForOverFulfill = false

        let task = try await Amplify.Storage.uploadData(
            key: key,
            data: AWSS3StoragePluginTestBase.largeDataObject,
            options: nil
        )

        task.inProcessPublisher.sink { progress in
            // To simulate a normal scenario, fulfill the progressInvoked expectation after some progress (30%)
            if progress.fractionCompleted > 0.3 {
                progressInvoked.fulfill()
            }
        }.store(in: &cancellables)

        await waitForExpectations(timeout: TestCommonConstants.networkTimeout)

        let completeInvoked = expectation(description: "Upload is completed")
        completeInvoked.isInverted = true
        task.resultPublisher.sink(receiveCompletion: { _ in }, receiveValue: { value in
            XCTFail("Task should have been cancelled")
            completeInvoked.fulfill()
        })
        .store(in: &cancellables)

        task.cancel()
        await waitForExpectations(timeout: 30)
    }
}
