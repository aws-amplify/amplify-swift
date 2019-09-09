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

    let user1 = "testUser111@amazon.com"
    let user2 = "testUser122@amazon.com"
    let password = "testPassword123!"

    override func setUp() {
        // Set up AWSMobileClient
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
        wait(for: [mobileClientIsInitialized], timeout: 100)
        print("AWSMobileClient Initialized")

        // Set up Amplify
        let awss3StoragePluginConfig: [String: Any] = [
            "Bucket": "swift6a3ad8b2b9f4402187f051de89548cc0-devo",
            "Region": "us-east-1"
        ]
        let storageConfig = StorageCategoryConfiguration(
            plugins: ["AWSS3StoragePlugin": true]
        )
        let amplifyConfig = AmplifyConfiguration(storage: storageConfig)
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
        sleep(5)
    }

    // MARK: Integration test one-time setup
    func testSetUpIntegrationTestData() {
        // Sign up and confirm User1
        // perhaps we cache it and then check if user1 has been successfully signed up.
        AWSMobileClient.sharedInstance().signUp(username: user1, password: password) { (result, error) in
            guard error == nil else {
                // if already signed up, then we are done.

                XCTFail("Failed to sign up user1 with error \(error)")
                return
            }

            if let result = result {
                // Confirm user1 with admin
            }
        }

        // TODO: Sign up and confirm User2
    }

    // MARK: Configuration Tests

//    func testSetAccessLevelThenPutWithNewDefault() {
//        XCTFail("Not yet implemented")
//    }
//
//    func testFailConfiguration() {
//        XCTFail("Not yet implemented")
//    }

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

        let operation = Amplify.Storage.get(key: key, options: options) { (event) in
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
    // MARK: AccessLevel Tests
//
//    func testPutToPublicAndListThenGetThenRemoveFromOtherUser() {
//        XCTFail("Not yet implemented")
//    }
//
    func testPutToProtectedAndListThenGetThenRemove() {

        // TODO Sign in. here instead of in set up.
        AWSMobileClient.sharedInstance().signIn(username: user1, password: password) { (result, error) in
            // TODO
        }

        let key = "testPutToProtectedAndListThenGetThenRemove"
        let dataString = "testPutToProtectedAndListThenGetThenRemove"
        let data = dataString.data(using: .utf8)!
        let options = StoragePutOption(accessLevel: .protected,
                                       contentType: nil,
                                       metadata: nil,
                                       options: nil)

        let putExpectation = expectation(description: "Put operation should be successful")
        let operation = Amplify.Storage.put(key: key, data: data, options: options) { (event) in
            switch event {
            case .unknown:
                break
            case .notInProcess:
                break
            case .inProcess:
                break
            case .completed:
                putExpectation.fulfill()
            case .failed(let error):
                print("failed \(error)")
                break
            }
        }

        waitForExpectations(timeout: 100) { (error) in
            if let error = error {
                XCTFail("timeout errored: \(error)")
            }
        }

        // TODO List and then Remove
    }
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
            case .completed:
                XCTFail("Should not have completed successfully")
            case .failed(let error):
                failInvoked.fulfill()
            default:
                break
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
