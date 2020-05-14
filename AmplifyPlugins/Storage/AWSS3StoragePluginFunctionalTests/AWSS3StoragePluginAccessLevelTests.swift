//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import Amplify
@testable import AWSS3StoragePlugin
import AWSS3
import AWSCognitoIdentityProvider
@testable import AmplifyTestCommon

class AWSS3StoragePluginAccessLevelTests: AWSS3StoragePluginTestBase {

    /// Given: An unauthenticated user
    /// When: List API with protected access level
    /// Then: Operation completes successfully with no items since there are no keys at that location.
    func testListFromProtectedForUnauthenticatedUser() {
        let key = UUID().uuidString
        let completeInvoked = expectation(description: "Completed is invoked")
        let options = StorageListRequest.Options(accessLevel: .protected,
                                                 targetIdentityId: nil,
                                                 path: key)
        let operation = Amplify.Storage.list(options: options) { event in
            switch event {
            case .completed(let result):
                XCTAssertNotNil(result)
                XCTAssertNotNil(result.items)
                XCTAssertEqual(result.items.count, 0)
                completeInvoked.fulfill()
            case .failed(let error):
                XCTFail("Failed with \(error)")
            default:
                break
            }
        }
        XCTAssertNotNil(operation)
        waitForExpectations(timeout: TestCommonConstants.networkTimeout)
    }

    /// Given: An unauthenticated user
    /// When: List API with private access level
    /// Then: Operation fails with access denied service error
    func testListFromPrivateForUnauthenticatedUserForReturnAccessDenied() {
        let key = UUID().uuidString
        let listFailedExpectation = expectation(description: "List Operation should fail")
        let options = StorageListRequest.Options(accessLevel: .private,
                                                 targetIdentityId: nil,
                                                 path: key)
        let operation = Amplify.Storage.list(options: options) { event in
            switch event {
            case .completed:
                XCTFail("Should not have completed")
            case .failed(let error):
                // TODO: service error, check string?
                guard case let .accessDenied(description, suggestion, _) = error else {
                    XCTFail("Expected accessDenied error")
                    return
                }
                XCTAssertEqual(description, StorageErrorConstants.accessDenied.errorDescription)
                listFailedExpectation.fulfill()
            default:
                break
            }
        }
        XCTAssertNotNil(operation)
        waitForExpectations(timeout: TestCommonConstants.networkTimeout)
    }

    /// Given: `user1` user uploads some data with protected access level
    /// When: The user retrieves and removes the data
    /// Then: The operations complete successful
    func testUploadToProtectedAndListThenGetThenRemove() {
        let key = UUID().uuidString
        let accessLevel: StorageAccessLevel = .protected
        putThenListThenGetThenRemoveForSingleUser(username: AWSS3StoragePluginTestBase.user1,
                                                  key: key,
                                                  accessLevel: accessLevel)
    }

    /// Given: `user1` user uploads some data with private access level
    /// When: The user retrieves and removes the data
    /// Then: The operations complete successful
    func testUploadToPrivateAndListThenGetThenRemove() {
        let key = UUID().uuidString
        let accessLevel: StorageAccessLevel = .private
        putThenListThenGetThenRemoveForSingleUser(username: AWSS3StoragePluginTestBase.user1,
                                                  key: key,
                                                  accessLevel: accessLevel)
    }

    /// Given: `user1` user uploads some data with public access level
    /// When: `user2` lists, gets, and removes the data for `user1`
    /// Then: The list, get, and remove operations complete successful and data is retrieved then removed.
    func testUploadToPublicAndListThenGetThenRemoveFromOtherUser() {
        let key = UUID().uuidString
        let accessLevel: StorageAccessLevel = .guest

        // Sign into user1
        AuthHelper.signIn(username: AWSS3StoragePluginTestBase.user1, password: AWSS3StoragePluginTestBase.password)
        let user1IdentityId = AuthHelper.getIdentityId()

        // Upload data
        upload(key: key, data: key, accessLevel: accessLevel)

        // Sign out of user1 and into user2
        AuthHelper.signOut()
        AuthHelper.signIn(username: AWSS3StoragePluginTestBase.user2, password: AWSS3StoragePluginTestBase.password)
        let user2IdentityId = AuthHelper.getIdentityId()
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
        let getOptions = StorageDownloadDataRequest.Options(accessLevel: accessLevel,
                                               targetIdentityId: nil)
        _ = Amplify.Storage.downloadData(key: key, options: getOptions) { event in
            switch event {
            case .completed(let results):
                XCTFail("Should not have completed with result \(results)")
            case .failed(let error):
                guard case .keyNotFound = error else {
                    XCTFail("Expected notFound error")
                    return
                }
                getFailedExpectation.fulfill()
            default:
                break
            }
        }
        waitForExpectations(timeout: TestCommonConstants.networkTimeout)
    }

    /// GivenK: `user1` user uploads some data with protected access level
    /// When: `user2` lists, gets, and removes the data for `user1`
    /// Then: The list and get operations complete successful and data is retrieved.
    func testUploadToProtectedAndListThenGetFromOtherUser() {
        let key = UUID().uuidString
        let accessLevel: StorageAccessLevel = .protected

        // Sign into user1
        AuthHelper.signIn(username: AWSS3StoragePluginTestBase.user1, password: AWSS3StoragePluginTestBase.password)
        let user1IdentityId = AuthHelper.getIdentityId()

        // Upload
        upload(key: key, data: key, accessLevel: accessLevel)

        // Sign out of user1 and into user2
        AuthHelper.signOut()
        AuthHelper.signIn(username: AWSS3StoragePluginTestBase.user2, password: AWSS3StoragePluginTestBase.password)
        let user2IdentityId = AuthHelper.getIdentityId()
        XCTAssertNotEqual(user1IdentityId, user2IdentityId)

        // list keys for user1 as user2
        let keys = list(path: key, accessLevel: accessLevel, targetIdentityId: user1IdentityId)
        XCTAssertNotNil(keys)
        XCTAssertEqual(keys!.count, 1)

        // get key for user1 as user2
        let data = get(key: key, accessLevel: accessLevel, targetIdentityId: user1IdentityId)
        XCTAssertNotNil(data)
    }

    /// Given: `user1` user uploads some data with private access level
    /// When: `user2` lists and gets the data for `user1`
    /// Then: The list and get operations fail with validation errors
    func testUploadToPrivateAndFailListThenFailGetFromOtherUser() {
        let key = UUID().uuidString
        let accessLevel: StorageAccessLevel = .private

        // Sign into user1
        AuthHelper.signIn(username: AWSS3StoragePluginTestBase.user1, password: AWSS3StoragePluginTestBase.password)
        let user1IdentityId = AuthHelper.getIdentityId()

        // Upload
        upload(key: key, data: key, accessLevel: accessLevel)

        // Sign out of user1 and into user2
        AuthHelper.signOut()
        AuthHelper.signIn(username: AWSS3StoragePluginTestBase.user2, password: AWSS3StoragePluginTestBase.password)
        let user2IdentityId = AuthHelper.getIdentityId()
        XCTAssertNotEqual(user1IdentityId, user2IdentityId)

        // list keys for user1 as user2 - should fail with validation error
        let listFailedExpectation = expectation(description: "List operation should fail")
        let listOptions = StorageListRequest.Options(accessLevel: accessLevel,
                                            targetIdentityId: user1IdentityId,
                                            path: key)
        _ = Amplify.Storage.list(options: listOptions) { event in
            switch event {
            case .completed:
                XCTFail("Should not have completed")
            case .failed(let error):
                guard case .validation(let field, let errorDescription, _, _) = error else {
                    XCTFail("Expected validation error")
                    return
                }
                listFailedExpectation.fulfill()
            default:
                break
            }
        }
        waitForExpectations(timeout: TestCommonConstants.networkTimeout)

        // get key for user1 as user2 - should fail with validation error
        let getFailedExpectation = expectation(description: "Get Operation should fail")
        let getOptions = StorageDownloadDataRequest.Options(accessLevel: accessLevel,
                                               targetIdentityId: user1IdentityId)
        _ = Amplify.Storage.downloadData(key: key, options: getOptions) { event in
            switch event {
            case .completed(let results):
                XCTFail("Should not have completed")
            case .failed(let error):
                guard case .validation(let field, let errorDescription, _, _) = error else {
                    XCTFail("Expected validation error")
                    return
                }
                getFailedExpectation.fulfill()
            default:
                break
            }
        }
        waitForExpectations(timeout: TestCommonConstants.networkTimeout)
    }

    // MARK: - Common test functions

    func putThenListThenGetThenRemoveForSingleUser(username: String, key: String, accessLevel: StorageAccessLevel) {
        AuthHelper.signIn(username: username, password: AWSS3StoragePluginTestBase.password)

        // Upload
        upload(key: key, data: key, accessLevel: accessLevel)

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
        let getOptions = StorageDownloadDataRequest.Options(accessLevel: accessLevel,
                                               targetIdentityId: nil)
        _ = Amplify.Storage.downloadData(key: key, options: getOptions) { event in
            switch event {
            case .completed(let results):
                XCTFail("Should not have completed with result \(results)")
            case .failed(let error):
                guard case .keyNotFound = error else {
                    XCTFail("Expected notFound error")
                    return
                }
                getFailedExpectation.fulfill()
            default:
                break
            }
        }
        waitForExpectations(timeout: TestCommonConstants.networkTimeout)
    }

    // MARK: StoragePlugin Helper functions

    func list(path: String, accessLevel: StorageAccessLevel, targetIdentityId: String? = nil) ->
        [StorageListResult.Item]? {
        var items: [StorageListResult.Item]?
        let listExpectation = expectation(description: "List operation should be successful")
        let listOptions = StorageListRequest.Options(accessLevel: accessLevel,
                                            targetIdentityId: targetIdentityId,
                                            path: path)
        _ = Amplify.Storage.list(options: listOptions) { event in
            switch event {
            case .completed(let results):
                items = results.items
                listExpectation.fulfill()
            case .failed(let error):
                XCTFail("Failed to list with error \(error)")
            default:
                break
            }
        }
        waitForExpectations(timeout: TestCommonConstants.networkTimeout)
        return items
    }

    func get(key: String, accessLevel: StorageAccessLevel, targetIdentityId: String? = nil) -> Data? {
        var data: Data?
        let getExpectation = expectation(description: "Get Operation should be successful")
        let getOptions = StorageDownloadDataRequest.Options(accessLevel: accessLevel,
                                               targetIdentityId: targetIdentityId)
        _ = Amplify.Storage.downloadData(key: key, options: getOptions) { event in
            switch event {
            case .completed(let result):
                data = result
                getExpectation.fulfill()
            case .failed(let error):
                XCTFail("Failed to get with error \(error)")
            default:
                break
            }
        }
        waitForExpectations(timeout: TestCommonConstants.networkTimeout)
        return data
    }

    func upload(key: String, data: String, accessLevel: StorageAccessLevel) {
        let uploadExpectation = expectation(description: "Upload operation should be successful")
        let options = StorageUploadDataRequest.Options(accessLevel: accessLevel)
        _ = Amplify.Storage.uploadData(key: key, data: data.data(using: .utf8)!, options: options) { event in
            switch event {
            case .completed:
                uploadExpectation.fulfill()
            case .failed(let error):
                XCTFail("Failed to put \(key) with error \(error)")
            default:
                break
            }
        }
        waitForExpectations(timeout: TestCommonConstants.networkTimeout)
    }

    func remove(key: String, accessLevel: StorageAccessLevel) {
        let removeExpectation = expectation(description: "Remove Operation should be successful")
        let removeOptions = StorageRemoveRequest.Options(accessLevel: accessLevel)
        _ = Amplify.Storage.remove(key: key, options: removeOptions) { event in
            switch event {
            case .completed(let key):
                removeExpectation.fulfill()
            case .failed(let error):
                XCTFail("Failed to remove with error \(error)")
            default:
                break
            }
        }
        waitForExpectations(timeout: TestCommonConstants.networkTimeout)
    }
}
