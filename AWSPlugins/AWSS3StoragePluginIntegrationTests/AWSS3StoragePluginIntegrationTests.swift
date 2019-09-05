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

class AWSS3StoragePluginIntegrationTests: XCTestCase {

    override func setUp() {
        // Set up AWSMobileClient
        // AWSInfo will read from the awsconfiguration.json file only from the main bundle, so we can't even just have
        // the awsconfiguration.json file in the test target.
        // https://stackoverflow.com/questions/1879247/why-cant-code-inside-unit-tests-find-bundle-resources

        // Once https://github.com/aws-amplify/aws-sdk-ios/pull/1812 is done, we can add code like/
        // AWSInfo.configure(values we pass in), can even read from awsconfiguration.json or amplifyconfiguration.json.
        let mobileClientIsInitialized = expectation(description: "AWSMobileClient is initialized")

        AWSMobileClient.sharedInstance().initialize { (userState, error) in
            guard error == nil else {
                XCTFail("Error initializing AWSMobileClient. Error: \(error!.localizedDescription)")
                return
            }

            guard let userState = userState else {
                XCTFail("userState is unexpectedly empty initializing AWSMobileClient")
                return
            }

            if userState != UserState.signedOut {
                AWSMobileClient.sharedInstance().signOut()
            }
            
            mobileClientIsInitialized.fulfill()
        }

        wait(for: [mobileClientIsInitialized], timeout: 5)
        print("AWSMobileClient Initialized")

        // Set up Amplify
        let awss3StoragePluginConfig: [String: Any] = [
            "Bucket": "swift6a3ad8b2b9f4402187f051de89548cc0-devo",
            "Region": "us-east-1"
        ]
        let storageConfig = BasicCategoryConfiguration(
            plugins: ["AWSS3StoragePlugin": awss3StoragePluginConfig]
        )
        let amplifyConfig = BasicAmplifyConfiguration(storage: storageConfig)

        let plugin = AWSS3StoragePlugin()
        do {
            try Amplify.add(plugin: plugin)
            try Amplify.configure(amplifyConfig)
        } catch {
            XCTFail("Failed to initialize and configure Amplify")
        }
        print("Amplify initialized")
    }

    override func tearDown() {
        print("Amplify reset")
        Amplify.reset()
    }

    // MARK: Configuration Tests

    func testSetAccessLevelThenPutWithNewDefault() {
        XCTFail("Not yet implemented")
    }

    func testFailConfiguration() {
        XCTFail("Not yet implemented")
    }

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

        waitForExpectations(timeout: 100)
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

        let operation = Amplify.Storage.get(key: "test-image.png", options: options) { (event) in
            switch event {
            case .unknown:
                break
            case .notInProcess:
                break
            case .inProcess:
                print("[testGet] progress")
                //progressInvoked.fulfill()
            case .completed:
                print("[testGet] completed")
                completeInvoked.fulfill()
            case .failed(let error):
                XCTFail("[testGet] Failed with \(error)")
            }
        }
        XCTAssertNotNil(operation)

        waitForExpectations(timeout: 100)
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
//
//    func testEscapeHatch() {
//        XCTFail("Not yet implemented")
//    }
//
//    // MARK: Resumability Tests
//
//    func testPutLargeDataAndPauseThenResume() {
//        XCTFail("Not yet implemented")
//    }
//
//    func testPutLargeDataAndCancel() {
//        XCTFail("Not yet implemented")
//    }
//
//    func testGetLargeDataAndPauseThenResume() {
//        XCTFail("Not yet implemented")
//    }
//
//    func testGetLargeDataAndCancel() {
//        XCTFail("Not yet implemented")
//    }
//
//    // MARK: AccessLevel Tests
//
//    func testPutToPublicAndListThenGetThenRemoveFromOtherUser() {
//        XCTFail("Not yet implemented")
//    }
//
//    func testPutToProtectedAndListThenGetThenRemove() {
//        XCTFail("Not yet implemented")
//    }
//
//    func testPutToProtectedAndListThenGetThenFailRemoveFromOtherUser() {
//        XCTFail("Not yet implemented")
//    }
//
//    func testPutToPrivateAndListThenGetThenRemove() {
//        XCTFail("Not yet implemented")
//    }
//
//    func testPutToPrivateAndFailListThenFailGetThenFailRemoveFromOtherUser() {
//        XCTFail("Not yet implemented")
//    }
//
//    // MARK: Usability with Options Tests
//
//    func testPutLargeDataWithMultiPart() {
//        XCTFail("Not yet implemented")
//    }
//
//    func testGetRemoteURLWithExpires() {
//        XCTFail("Not yet implemented")
//    }
//
//    func testPutWithMetadata() {
//        XCTFail("Not yet implemented")
//    }
//
//    func testPutWithTags() {
//        XCTFail("Not yet implemented")
//    }
//
//    func testListWithLimit() {
//        XCTFail("Not yet implemented")
//    }
//
//    // MARK: Negative Tests
//
    func testGetNonexistentKey() {
        let key = "testGetNonexistentKey"
        let failInvoked = expectation(description: "Failed is invoked")
        let operation = Amplify.Storage.get(key: key, options: nil) { (event) in
            switch event {
            case .unknown:
                break
            case .notInProcess:
                break
            case .inProcess:
                break
            case .completed:
                XCTFail("Negative test completed successfully")
            case .failed(let error):
                failInvoked.fulfill()
            }
        }

        XCTAssertNotNil(operation)
        waitForExpectations(timeout: 100)
    }
//
//    func testPutDataFromMissingFile() {
//        XCTFail("Not yet implemented")
//    }
//
//    func testPutDataForEmptyObject() {
//        XCTFail("Not yet implemented")
//    }
//
//    func testListNonExistentKey() {
//        XCTFail("Not yet implemented")
//        // So we should set a custom Prefix since by default it will list from the "public/" folder. we need to..
//        // change this and test that accessDenied is returned ..
//    }
//
//    func testRemoveNonExistentKey() {
//        XCTFail("Not yet implemented")
//    }
}
