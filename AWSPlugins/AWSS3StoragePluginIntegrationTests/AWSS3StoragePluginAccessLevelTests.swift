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
import AWSCognitoIdentityProvider

class AWSS3StoragePluginAccessLevelTests: AWSS3StoragePluginTestBase {
    let user1 = "storageUser1@testing.com"
    let user2  = "storageUser2@testing.com"
    let password = "Abc123@@!!"

    // This is a run once function to set up users then use console to verify and run rest of these tests.
    func testSetUpOnce() {
        signUpUser(username: user1)
        signUpUser(username: user2)
    }

    func testPutToProtectedAndListThenGetThenRemove() {
        let key = "testPutToProtectedAndListThenGetThenRemove"
        let accessLevel: StorageAccessLevel = .protected
        putThenListThenGetThenRemoveForSingleUser(username: user1, key: key, accessLevel: accessLevel)
    }

    func testPutToPrivateAndListThenGetThenRemove() {
        let key = #function
        let accessLevel: StorageAccessLevel = .private
        putThenListThenGetThenRemoveForSingleUser(username: user1, key: key, accessLevel: accessLevel)
    }

    func testPutToPublicAndListThenGetThenRemoveFromOtherUser() {
        let key = "testPutToPublicAndListThenGetThenRemoveFromOtherUser"
        let accessLevel: StorageAccessLevel = .public

        // Sign into user1
        signIn(username: user1)
        let user1IdentityId = getIdentityId()

        // Put data
        put(key: key, data: key, accessLevel: accessLevel)

        // Sign out of user1 and into user2
        AWSMobileClient.sharedInstance().signOut()
        signIn(username: user2)
        let user2IdentityId = getIdentityId()
        XCTAssertNotEqual(user1IdentityId, user2IdentityId)

        // list keys as user2
        let keys = list(path: key, accessLevel: accessLevel)
        XCTAssertNotNil(keys)
        XCTAssertEqual(keys!.count, 1)

        // get key as user2
        let data = get(key: key, accessLevel: accessLevel)
        XCTAssertNotNil(data)

        // remove key as user2
        remove(key: key, accessLevel: accessLevel)

        // get key after removal should return NotFound
        let getFailedExpectation = expectation(description: "Get Operation should fail")
        let getOptions = StorageGetOption(accessLevel: accessLevel,
                                          targetIdentityId: nil,
                                          storageGetDestination: .data,
                                          options: nil)
        _ = Amplify.Storage.get(key: key, options: getOptions) { (event) in
            switch event {
            case .completed(let results):
                XCTFail("Should not have completed with result \(results)")
            case .failed(let error):
                guard case .notFound = error else {
                    XCTFail("Expected notFound error")
                    return
                }
                getFailedExpectation.fulfill()
            default:
                break
            }
        }
        waitForExpectations(timeout: 30)
    }

    func testPutToProtectedAndListThenGetFromOtherUser() {
        let key = "testPutToProtectedAndListThenGetThenFailRemoveFromOtherUser"
        let accessLevel: StorageAccessLevel = .protected

        // Sign into user1
        signIn(username: user1)
        let user1IdentityId = getIdentityId()

        // Put
        put(key: key, data: key, accessLevel: accessLevel)

        // Sign out of user1 and into user2
        AWSMobileClient.sharedInstance().signOut()
        signIn(username: user2)
        let user2IdentityId = getIdentityId()
        XCTAssertNotEqual(user1IdentityId, user2IdentityId)

        // list keys for user1 as user2
        let keys = list(path: key, accessLevel: accessLevel, targetIdentityId: user1IdentityId)
        XCTAssertNotNil(keys)
        XCTAssertEqual(keys!.count, 1)

        // get key for user1 as user2
        let data = get(key: key, accessLevel: accessLevel, targetIdentityId: user1IdentityId)
        XCTAssertNotNil(data)
    }

    // Should this test really exist? or should we just test that a
    // remove request cannot be made with private and targetIdentityId?
    func testPutToPrivateAndFailListThenFailGetFromOtherUser() {
        let key = "testPutToPrivateAndFailListThenFailGetFromOtherUser"
        let accessLevel: StorageAccessLevel = .private

        // Sign into user1
        signIn(username: user1)
        let user1IdentityId = getIdentityId()

        // Put
        put(key: key, data: key, accessLevel: accessLevel)

        // Sign out of user1 and into user2
        AWSMobileClient.sharedInstance().signOut()
        signIn(username: user2)
        let user2IdentityId = getIdentityId()
        XCTAssertNotEqual(user1IdentityId, user2IdentityId)

        // list keys for user1 as user2 - should fail with validation error
        let listFailedExpectation = expectation(description: "List operation should fail")
        let listOptions = StorageListOption(accessLevel: accessLevel,
                                            targetIdentityId: user1IdentityId,
                                            path: key,
                                            limit: nil,
                                            options: nil)
        _ = Amplify.Storage.list(options: listOptions) { (event) in
            switch event {
            case .completed:
                XCTFail("Should not have completed")
            case .failed(let error):
                guard case .validation(let errorDescription, _) = error else {
                    XCTFail("Expected validation error")
                    return
                }
                listFailedExpectation.fulfill()
            default:
                break
            }
        }
        waitForExpectations(timeout: 5)

        // get key for user1 as user2 - should fail with validation error
        let getFailedExpectation = expectation(description: "Get Operation should fail")
        let getOptions = StorageGetOption(accessLevel: accessLevel,
                                          targetIdentityId: user1IdentityId,
                                          storageGetDestination: .data,
                                          options: nil)
        _ = Amplify.Storage.get(key: key, options: getOptions) { (event) in
            switch event {
            case .completed(let results):
                XCTFail("Should not have completed")
            case .failed(let error):
                guard case .validation(let errorDescription, _) = error else {
                    XCTFail("Expected validation error")
                    return
                }
                getFailedExpectation.fulfill()
            default:
                break
            }
        }
        waitForExpectations(timeout: 5)
    }

    // Mark: Commonn test functions

    func putThenListThenGetThenRemoveForSingleUser(username: String, key: String, accessLevel: StorageAccessLevel) {
        signIn(username: username)

        // Put
        put(key: key, data: key, accessLevel: accessLevel)

        // List
        let keys = list(path: key, accessLevel: accessLevel)
        XCTAssertNotNil(keys)
        XCTAssertEqual(keys!.count, 1)

        // Get
        let data = get(key: key, accessLevel: accessLevel)
        XCTAssertNotNil(data)

        // Remove
        remove(key: key, accessLevel: accessLevel)

        // Get key after removal should return NotFound
        let getFailedExpectation = expectation(description: "Get Operation should fail")
        let getOptions = StorageGetOption(accessLevel: accessLevel,
                                          targetIdentityId: nil,
                                          storageGetDestination: .data,
                                          options: nil)
        _ = Amplify.Storage.get(key: key, options: getOptions) { (event) in
            switch event {
            case .completed(let results):
                XCTFail("Should not have completed with result \(results)")
            case .failed(let error):
                guard case .notFound = error else {
                    XCTFail("Expected notFound error")
                    return
                }
                getFailedExpectation.fulfill()
            default:
                break
            }
        }
        waitForExpectations(timeout: 5)
    }

    // MARK: StoragePlugin Helper functions

    func list(path: String, accessLevel: StorageAccessLevel, targetIdentityId: String? = nil) -> [String]? {
        var keys: [String]?
        let listExpectation = expectation(description: "List operation should be successful")
        let listOptions = StorageListOption(accessLevel: accessLevel,
                                            targetIdentityId: targetIdentityId,
                                            path: path,
                                            limit: nil,
                                            options: nil)
        _ = Amplify.Storage.list(options: listOptions) { (event) in
            switch event {
            case .completed(let results):
                keys = results.keys
                listExpectation.fulfill()
            case .failed(let error):
                XCTFail("Failed to list with error \(error)")
            default:
                break
            }
        }
        waitForExpectations(timeout: 5)
        return keys
    }

    func get(key: String, accessLevel: StorageAccessLevel, targetIdentityId: String? = nil) -> Data? {
        var data: Data?
        let getExpectation = expectation(description: "Get Operation should be successful")
        let getOptions = StorageGetOption(accessLevel: accessLevel,
                                          targetIdentityId: targetIdentityId,
                                          storageGetDestination: .data,
                                          options: nil)
        _ = Amplify.Storage.get(key: key, options: getOptions) { (event) in
            switch event {
            case .completed(let results):
                data = results.data
                getExpectation.fulfill()
            case .failed(let error):
                XCTFail("Failed to get with error \(error)")
            default:
                break
            }
        }
        waitForExpectations(timeout: 5)
        return data
    }

    func put(key: String, data: String, accessLevel: StorageAccessLevel) {
        let putExpectation = expectation(description: "Put operation should be successful")
        let putOptions = StoragePutOption(accessLevel: accessLevel,
                                          contentType: nil,
                                          metadata: nil,
                                          options: nil)
        _ = Amplify.Storage.put(key: key, data: data.data(using: .utf8)!, options: putOptions) { (event) in
            switch event {
            case .completed:
                putExpectation.fulfill()
            case .failed(let error):
                XCTFail("Failed to put \(key) with error \(error)")
            default:
                break
            }
        }
        waitForExpectations(timeout: 5)
    }

    func remove(key: String, accessLevel: StorageAccessLevel) {
        let removeExpectation = expectation(description: "Remove Operation should be successful")
        let removeOptions = StorageRemoveOption(accessLevel: accessLevel, options: nil)
        _ = Amplify.Storage.remove(key: key, options: removeOptions) { (event) in
            switch event {
            case .completed(let results):
                print("results from remove: \(results.key)")
                removeExpectation.fulfill()
            case .failed(let error):
                XCTFail("Failed to remove with error \(error)")
            default:
                break
            }
        }
        waitForExpectations(timeout: 5)
    }

    // MARK: Auth Helper functions

    func signIn(username: String) {
        let signInWasSuccessful = expectation(description: "signIn was successful")
        AWSMobileClient.sharedInstance().signIn(username: username, password: password) { (result, error) in
            if let error = error {
                XCTFail("Sign in failed: \(error.localizedDescription)")
                return
            }

            guard let result = result else {
                XCTFail("No result from SignIn")
                return
            }
            XCTAssertEqual(result.signInState, .signedIn)
            signInWasSuccessful.fulfill()
        }
        waitForExpectations(timeout: 5)
    }

    func signUpUser(username: String) {
        let signUpExpectation = expectation(description: "successful sign up expectation.")
        AWSMobileClient.sharedInstance().signUp(username: username, password: password) { (result, error) in
            guard error == nil else {
                let error = error
                XCTFail("Failed to sign up user with error: \(error?.localizedDescription)")
                return
            }

            guard result != nil else {
                XCTFail("result from signUp should not be nil")
                return
            }

            signUpExpectation.fulfill()
        }

        waitForExpectations(timeout: 5)
    }

    func getIdentityId() -> String {
        let getIdentityIdForUser2Task = AWSMobileClient.sharedInstance().getIdentityId()
        getIdentityIdForUser2Task.waitUntilFinished()
        return getIdentityIdForUser2Task.result! as String
    }
}
