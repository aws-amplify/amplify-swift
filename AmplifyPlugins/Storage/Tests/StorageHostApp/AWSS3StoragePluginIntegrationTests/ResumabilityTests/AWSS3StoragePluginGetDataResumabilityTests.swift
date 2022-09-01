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

// swiftlint:disable:next type_name
class AWSS3StoragePluginDownloadDataResumabilityTests: AWSS3StoragePluginTestBase {

    /// Given: A large data object in storage
    /// When: Call the get API then pause
    /// Then: The operation is stalled (no progress, completed, or failed event)
    func testDownloadLargeDataAndPause() {
        let key = UUID().uuidString
        uploadData(key: key, data: AWSS3StoragePluginTestBase.largeDataObject)

        let progressInvoked = expectation(description: "Progress invoked")
        progressInvoked.assertForOverFulfill = false
        let completeInvoked = expectation(description: "Completion invoked")
        completeInvoked.isInverted = true
        let failedInvoked = expectation(description: "Failed invoked")
        failedInvoked.isInverted = true
        let noProgressAfterPause = expectation(description: "Progress after pause is invoked")
        noProgressAfterPause.isInverted = true
        let operation = Amplify.Storage.downloadData(
            key: key,
            options: nil,
            progressListener: { progress in
            // To simulate a normal scenario, fulfill the progressInvoked expectation after some progress (30%)
            if progress.fractionCompleted > 0.3 {
                progressInvoked.fulfill()
            }

            // After pausing, progress events still trickle in, but should not exceed
            if progress.fractionCompleted > 0.7 {
                noProgressAfterPause.fulfill()
            }
        }, resultListener: { result in
            switch result {
            case .success:
                completeInvoked.fulfill()
            case .failure:
                failedInvoked.fulfill()
            }
        })

        XCTAssertNotNil(operation)
        wait(for: [progressInvoked], timeout: TestCommonConstants.networkTimeout)
        operation.pause()
        wait(for: [completeInvoked, failedInvoked, noProgressAfterPause], timeout: 30)
    }

    /// Given: A large data object in storage
    /// When: Call the downloadData API, pause, and then resume the operation
    /// Then: The operation should complete successfully
    func testDownloadLargeDataAndPauseThenResume() {
        let key = UUID().uuidString
        uploadData(key: key, data: AWSS3StoragePluginTestBase.largeDataObject)

        let progressInvoked = expectation(description: "Progress invoked")
        progressInvoked.assertForOverFulfill = false
        let completeInvoked = expectation(description: "Complete invoked")
        let operation = Amplify.Storage.downloadData(
            key: key,
            options: nil,
            progressListener: { progress in
            // To simulate a normal scenario, fulfill the progressInvoked expectation after some progress (30%)
            if progress.fractionCompleted > 0.3 {
                progressInvoked.fulfill()
            }
        }, resultListener: { result in
            switch result {
            case .success:
                completeInvoked.fulfill()
            case .failure(let error):
                XCTFail("Failed with \(error)")
            }
        })

        XCTAssertNotNil(operation)
        wait(for: [progressInvoked], timeout: TestCommonConstants.networkTimeout)
        operation.pause()
        operation.resume()
        wait(for: [completeInvoked], timeout: TestCommonConstants.networkTimeout)
    }

    /// Given: A large data object in storage
    /// When: Call the get API then cancel the operation,
    /// Then: The operation should not complete or fail.
    func testDownloadLargeDataAndCancel() {
        let key = UUID().uuidString
        uploadData(key: key, data: AWSS3StoragePluginTestBase.largeDataObject)

        let progressInvoked = expectation(description: "Progress invoked")
        progressInvoked.assertForOverFulfill = false
        let completedInvoked = expectation(description: "Completion invoked")
        completedInvoked.isInverted = true
        let failedInvoked = expectation(description: "Failed invoked")
        failedInvoked.isInverted = true
        let operation = Amplify.Storage.downloadData(
            key: key,
            options: nil,
            progressListener: { progress in
            // To simulate a normal scenario, fulfill the progressInvoked expectation after some progress (30%)
            if progress.fractionCompleted > 0.3 {
                progressInvoked.fulfill()
            }
        }, resultListener: { result in
            switch result {
            case .success:
                completedInvoked.fulfill()
            case .failure:
                failedInvoked.fulfill()
            }
        })

        XCTAssertNotNil(operation)
        wait(for: [progressInvoked], timeout: TestCommonConstants.networkTimeout)
        operation.cancel()
        wait(for: [completedInvoked, failedInvoked], timeout: 30)
    }
}
