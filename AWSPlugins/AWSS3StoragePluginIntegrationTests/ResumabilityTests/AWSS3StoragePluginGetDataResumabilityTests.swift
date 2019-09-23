//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import AWSMobileClient
import Amplify
import AWSS3StoragePlugin
import AWSS3

class AWSS3StoragePluginGetDataResumabilityTests: AWSS3StoragePluginTestBase {

    /// Given: A large data object in storage
    /// When: Call the get API then pause
    /// Then: The operation is stalled (no progress, completed, or failed event)
    func testGetLargeDataAndPause() {
        let key = "testGetLargeDataAndPause"
        var testData = key
        for _ in 1...15 {
            testData += testData
        }
        let data = testData.data(using: .utf8)!
        putData(key: key, data: data)

        let progressInvoked = expectation(description: "Progress invoked")
        progressInvoked.assertForOverFulfill = false
        let completeInvoked = expectation(description: "Completion invoked")
        completeInvoked.isInverted = true
        let failedInvoked = expectation(description: "Failed invoked")
        failedInvoked.isInverted = true
        let operation = Amplify.Storage.getData(key: key, options: nil) { (event) in
            switch event {
            case .inProcess(let progress):
                // To simulate a normal scenario, fulfill the progressInvoked expectation after some progress (30%)
                if progress.fractionCompleted > 0.3 {
                    progressInvoked.fulfill()
                }
            case .completed:
                completeInvoked.fulfill()
            case .failed:
                failedInvoked.fulfill()
            default:
                break
            }
        }

        XCTAssertNotNil(operation)
        wait(for: [progressInvoked], timeout: 15)
        operation.pause()
        wait(for: [completeInvoked, failedInvoked], timeout: 30)
    }

    /// Given: A large data object in storage
    /// When: Call the getData API, pause, and then resume the operation
    /// Then: The operation should complete successfully
    func testGetLargeDataAndPauseThenResume() {
        let key = "testGetLargeDataAndPauseThenResume"
        var testData = key
        for _ in 1...15 {
            testData += testData
        }
        let data = testData.data(using: .utf8)!
        putData(key: key, data: data)

        let progressInvoked = expectation(description: "Progress invoked")
        progressInvoked.assertForOverFulfill = false
        let completeInvoked = expectation(description: "Complete invoked")
        let operation = Amplify.Storage.getData(key: key, options: nil) { (event) in
            switch event {
            case .inProcess(let progress):
                // To simulate a normal scenario, fulfill the progressInvoked expectation after some progress (30%)
                if progress.fractionCompleted > 0.3 {
                    progressInvoked.fulfill()
                }
            case .completed:
                completeInvoked.fulfill()
            case .failed(let error):
                XCTFail("Failed with \(error)")
            default:
                break
            }
        }

        XCTAssertNotNil(operation)
        wait(for: [progressInvoked], timeout: 15)
        operation.pause()
        operation.resume()
        wait(for: [completeInvoked], timeout: 60)
    }

    /// Given: A large data object in storage
    /// When: Call the get API then cancel the operation,
    /// Then: The operation should not complete or fail.
    func testGetLargeDataAndCancel() {
        let key = "testGetLargeDataAndCancel"
        var testData = key
        for _ in 1...15 {
            testData += testData
        }
        let data = testData.data(using: .utf8)!
        putData(key: key, data: data)

        let progressInvoked = expectation(description: "Progress invoked")
        progressInvoked.assertForOverFulfill = false
        let completedInvoked = expectation(description: "Completion invoked")
        completedInvoked.isInverted = true
        let failedInvoked = expectation(description: "Failed invoked")
        failedInvoked.isInverted = true
        let operation = Amplify.Storage.getData(key: key, options: nil) { (event) in
            switch event {
            case .inProcess(let progress):
                // To simulate a normal scenario, fulfill the progressInvoked expectation after some progress (30%)
                if progress.fractionCompleted > 0.3 {
                    progressInvoked.fulfill()
                }
            case .completed:
                completedInvoked.fulfill()
            case .failed(let error):
                failedInvoked.fulfill()
            default:
                break
            }
        }

        XCTAssertNotNil(operation)
        wait(for: [progressInvoked], timeout: 15)
        operation.cancel()
        XCTAssertTrue(operation.isCancelled)
        wait(for: [completedInvoked, failedInvoked], timeout: 15)
    }

}
