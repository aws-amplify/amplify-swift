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
class AWSS3StoragePluginResumabilityTests: AWSS3StoragePluginTestBase {

    // MARK: Resumability Tests

    func testPutLargeDataAndPauseThenResume() {
        let key = "testPutLargeDataAndPauseThenResume"
        var testData = key
        for _ in 1...15 {
            testData += testData
        }
        let data = testData.data(using: .utf8)!
        let completeInvoked = expectation(description: "Completed is invoked")
        let progressInvoked = expectation(description: "Progress invoked")
        var progressFulfilled = false
        let operation = Amplify.Storage.put(key: key, data: data, options: nil) { (event) in
            switch event {
            case .inProcess(let progress):
                if progress.fractionCompleted > 0.3 && !progressFulfilled {
                    progressFulfilled = true
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
        sleep(5)
        operation.resume()
        wait(for: [completeInvoked], timeout: 60)
    }

    func testPutLargeDataAndCancel() {
        let key = "testPutLargeDataAndCancel"
        var testData = key
        for _ in 1...15 {
            testData += testData
        }
        let data = testData.data(using: .utf8)!
        let progressInvoked = expectation(description: "Progress invoked")
        var progressFulfilled = false
        let completedInvoked = expectation(description: "Completion invoked")
        completedInvoked.isInverted = true
        let operation = Amplify.Storage.put(key: key, data: data, options: nil) { (event) in
            switch event {
            case .inProcess(let progress):
                if progress.fractionCompleted > 0.3 && !progressFulfilled {
                    progressFulfilled = true
                    progressInvoked.fulfill()
                }
            case .completed:
                XCTFail("Should not have completed after cancel")
                completedInvoked.fulfill()
            case .failed(let error):
                XCTFail("Failed with \(error)")
            default:
                break
            }
        }

        XCTAssertNotNil(operation)
        wait(for: [progressInvoked], timeout: 15)
        operation.cancel()
        XCTAssertTrue(operation.isCancelled)
        wait(for: [completedInvoked], timeout: 15)
    }

    func testGetLargeDataAndPauseThenResume() {
        let key = "testGetLargeDataAndPauseThenResume"
        var testData = key
        for _ in 1...15 {
            testData += testData
        }
        let data = testData.data(using: .utf8)!
        putData(key: key, data: data)

        let progressInvoked = expectation(description: "Progress invoked")
        var progressFulfilled = false
        let completeInvoked = expectation(description: "Complete invoked")
        let operation = Amplify.Storage.getData(key: key, options: nil) { (event) in
            switch event {
            case .inProcess(let progress):
                if progress.fractionCompleted > 0.3 && !progressFulfilled {
                    progressFulfilled = true
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
        sleep(5)
        operation.resume()
        wait(for: [completeInvoked], timeout: 60)
    }

    func testGetLargeDataAndCancel() {
        let key = "testGetLargeDataAndCancel"
        var testData = key
        for _ in 1...15 {
            testData += testData
        }
        let data = testData.data(using: .utf8)!
        putData(key: key, data: data)

        let progressInvoked = expectation(description: "Progress invoked")
        var progressFulfilled = false
        let operation = Amplify.Storage.getData(key: key, options: nil) { (event) in
            switch event {
            case .inProcess(let progress):
                print(progress)
                if progress.fractionCompleted > 0.3 && !progressFulfilled {
                    progressFulfilled = true
                    progressInvoked.fulfill()
                }
            case .completed:
                XCTFail("Should not have completed after cancel")
            case .failed(let error):
                XCTFail("Failed with \(error)")
            default:
                break
            }
        }

        XCTAssertNotNil(operation)
        wait(for: [progressInvoked], timeout: 15)
        operation.cancel()
        XCTAssertTrue(operation.isCancelled)
    }
}
