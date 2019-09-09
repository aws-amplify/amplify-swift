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
class AWSS3StoragePluginBasicIntegrationTests: AWSS3StoragePluginTestBase {
    // MARK: Basic tests

    func testPutData() {
        let key = "testPutData"
        let dataString = "testPutDataString"
        let data = dataString.data(using: .utf8)!
        let completeInvoked = expectation(description: "Completed is invoked")

        let operation = Amplify.Storage.put(key: key, data: data, options: nil) { (event) in
            switch event {
            case .unknown:
                break
            case .notInProcess:
                break
            case .inProcess:
                break
            case .completed:
                completeInvoked.fulfill()
            case .failed(let error):
                XCTFail("Failed with \(error)")
            }
        }

        waitForExpectations(timeout: 60)
    }

    func testPutDataFromFile() {
        let key = "testPutDataFromFile"
        let filePath = NSTemporaryDirectory() + "testPutDataFromFile.tmp"
        var testData = "testPutDataFromFile"
        for _ in 1...5 {
            testData += testData
        }
        let fileURL = URL(fileURLWithPath: filePath)
        FileManager.default.createFile(atPath: filePath, contents: testData.data(using: .utf8), attributes: nil)

        let completeInvoked = expectation(description: "Completed is invoked")
        let operation = Amplify.Storage.put(key: key, local: fileURL, options: nil) { (event) in
            switch event {
            case .completed:
                completeInvoked.fulfill()
            case .failed(let error):
                XCTFail("Failed with \(error)")
            default:
                break
            }
        }

        XCTAssertNotNil(operation)
        waitForExpectations(timeout: 100)
    }

    func testGetDataToMemory() {
        let key = "test-image.png"

        let completeInvoked = expectation(description: "Completed is invoked")
        let options = StorageGetOption(accessLevel: nil,
                                       targetIdentityId: nil,
                                       storageGetDestination: .data,
                                       options: nil)

        let operation = Amplify.Storage.get(key: key, options: options) { (event) in
            switch event {
            case .completed:
                completeInvoked.fulfill()
            case .failed(let error):
                XCTFail("Failed with \(error)")
            default:
                break
            }
        }
        XCTAssertNotNil(operation)
        waitForExpectations(timeout: 60)
    }

    func testGetDataToFile() {
        XCTFail("Not yet implemented")
    }

    func testGetRemoteURL() {
        let key = "test-image.png"
        let completeInvoked = expectation(description: "Completed is invoked")
        let operation = Amplify.Storage.get(key: key, options: nil) { (event) in
            switch event {
            case .unknown:
                break
            case .notInProcess:
                break
            case .inProcess:
                break
            case .completed(let result):
                if let remote = result.remote {
                    print("Got result: \(remote)")
                } else {
                    XCTFail("Missing remote url from result")
                }
                completeInvoked.fulfill()
            case .failed(let error):
                XCTFail("Failed with \(error)")
            }
        }
        XCTAssertNotNil(operation)
        waitForExpectations(timeout: 100)
    }

    func testListFromPublic() {
        let completeInvoked = expectation(description: "Completed is invoked")
        let operation = Amplify.Storage.list(options: nil) { (event) in
            switch event {
            case .unknown:
                break
            case .notInProcess:
                break
            case .inProcess:
                break
            case .completed(let result):
                print("Got result: \(result.keys)")
                completeInvoked.fulfill()
            case .failed(let error):
                XCTFail("Failed with \(error)")
            }
        }
        XCTAssertNotNil(operation)
        waitForExpectations(timeout: 100)
    }

    func testListFromProtected() {
        let completeInvoked = expectation(description: "Completed is invoked")
        let options = StorageListOption(accessLevel: .protected,
                                        targetIdentityId: nil,
                                        path: nil,
                                        limit: nil,
                                        options: nil)
        let operation = Amplify.Storage.list(options: options) { (event) in
            switch event {
            case .unknown:
                break
            case .notInProcess:
                break
            case .inProcess:
                break
            case .completed(let result):
                print("Got result: \(result.keys)")
                completeInvoked.fulfill()
            case .failed(let error):
                XCTFail("Failed with \(error)")
            }
        }
        XCTAssertNotNil(operation)
        waitForExpectations(timeout: 100)
    }

    func testRemoveKey() {
        let key = "testRemoveKey"
        let dataString = "testRemoveKey"
        let data = dataString.data(using: .utf8)!
        let completeInvoked = expectation(description: "Completed is invoked")

        _ = Amplify.Storage.put(key: key, data: data, options: nil) { (event) in
            switch event {
            case .unknown:
                break
            case .notInProcess:
                break
            case .inProcess:
                break
            case .completed:
                let removeOperation = Amplify.Storage.remove(key: key, options: nil) { (event) in
                    switch event {
                    case .unknown:
                        break
                    case .notInProcess:
                        break
                    case .inProcess:
                        break
                    case .completed(let result):
                        print("Got result: \(result.key)")
                        completeInvoked.fulfill()
                    case .failed(let error):
                        XCTFail("Failed with \(error)")
                    }
                }
                XCTAssertNotNil(removeOperation)
            case .failed(let error):
                XCTFail("Failed with \(error)")
            }
        }

        waitForExpectations(timeout: 100)
    }

    func testEscapeHatchForHeadObject() {
        // TODO: upload to public with metadata and then get
        do {
            let plugin = try Amplify.Storage.getPlugin(for: "AWSS3StoragePlugin")
            if let plugin = plugin as? AWSS3StoragePlugin {
                let awsS3 = plugin.getEscapeHatch()

                let request = AWSS3HeadObjectRequest()
                request?.bucket = "swift6a3ad8b2b9f4402187f051de89548cc0-devo" // TODO retrieve from above
                request?.key = "public/test-image.png"

                let task = awsS3.headObject(request!)
                task.waitUntilFinished()

                if let error = task.error {
                    XCTFail("Failed to get headObject \(error)")
                } else if let result = task.result {
                    print("headObject \(result)")
                }
            } else {
                XCTFail("Failed to get AWSS3StoragePlugin")
            }
        } catch {
            XCTFail("Failed to get AWSS3StoragePlugin")
        }
    }
}
