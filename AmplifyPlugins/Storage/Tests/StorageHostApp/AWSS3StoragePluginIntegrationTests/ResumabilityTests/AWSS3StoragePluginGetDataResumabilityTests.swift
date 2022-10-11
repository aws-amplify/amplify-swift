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

    /// Given: A large data object in storage
    /// When: Call the get API then pause
    /// Then: The operation is stalled (no progress, completed, or failed event)
    func testDownloadLargeDataAndPause() async {
        let key = UUID().uuidString
        await uploadData(key: key, data: AWSS3StoragePluginTestBase.largeDataObject)

        guard let task = await downloadTask(key: key) else {
            XCTFail("Unable to create download task")
            return
        }

        var cancellables = Set<AnyCancellable>()
        let progressInvoked = expectation(description: "Progress invoked")
        progressInvoked.assertForOverFulfill = false
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
        var progressCount = 0
        task.inProcessPublisher.sink { progress in
            progressCount += 1
            XCTAssertLessThanOrEqual(progressCount, 1)
            if progressCount > 1 {
                XCTFail("Task should have been paused")
                noProgressAfterPause.fulfill()
            }
        }.store(in: &cancellables)

        let completeInvoked = expectation(description: "Download is completed")
        completeInvoked.isInverted = true
        task.resultPublisher.sink(receiveCompletion: { _ in }, receiveValue: { value in
            XCTFail("Task should have been paused")
            completeInvoked.fulfill()
        })
        .store(in: &cancellables)

        await waitForExpectations(timeout: 30)
        // Remove the key
        await remove(key: key)
    }

    /// Given: A large data object in storage
    /// When: Call the downloadData API, pause, and then resume the operation
    /// Then: The operation should complete successfully
    func testDownloadLargeDataAndPauseThenResume() async {
        let key = UUID().uuidString
        await uploadData(key: key, data: AWSS3StoragePluginTestBase.largeDataObject)

        guard let task = await downloadTask(key: key) else {
            XCTFail("Unable to create download task")
            return
        }

        var cancellables = Set<AnyCancellable>()
        let progressInvoked = expectation(description: "Progress invoked")
        progressInvoked.assertForOverFulfill = false
        task.inProcessPublisher.sink { progress in
            // To simulate a normal scenario, fulfill the progressInvoked expectation after some progress (30%)
            if progress.fractionCompleted > 0.3 {
                progressInvoked.fulfill()
            }
        }.store(in: &cancellables)

        XCTAssertNotNil(task)
        await waitForExpectations(timeout: TestCommonConstants.networkTimeout)
        task.pause()

        let completeInvoked = expectation(description: "Download is completed")
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
        // Remove the key
        await remove(key: key)
    }

    /// Given: A large data object in storage
    /// When: Call the get API then cancel the operation,
    /// Then: The operation should not complete or fail.
    func testDownloadLargeDataAndCancel() async {
        let key = UUID().uuidString
        await uploadData(key: key, data: AWSS3StoragePluginTestBase.largeDataObject)

        guard let task = await downloadTask(key: key) else {
            XCTFail("Unable to create download task")
            return
        }

        var cancellables = Set<AnyCancellable>()
        let progressInvoked = expectation(description: "Progress invoked")
        progressInvoked.assertForOverFulfill = false
        task.inProcessPublisher.sink { progress in
            // To simulate a normal scenario, fulfill the progressInvoked expectation after some progress (30%)
            if progress.fractionCompleted > 0.3 {
                progressInvoked.fulfill()
            }
        }.store(in: &cancellables)

        await waitForExpectations(timeout: TestCommonConstants.networkTimeout)

        let completeInvoked = expectation(description: "Download is completed")
        completeInvoked.isInverted = true
        task.resultPublisher.sink(receiveCompletion: { _ in }, receiveValue: { value in
            XCTFail("Task should have been cancelled")
            completeInvoked.fulfill()
        })
        .store(in: &cancellables)

        task.cancel()
        await waitForExpectations(timeout: 30)
        // Remove the key
        await remove(key: key)
    }
}
