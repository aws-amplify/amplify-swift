//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import Amplify
import AWSPluginsCore
@testable import AWSS3StoragePlugin
import AmplifyAsyncTesting

class AWSS3StoragePluginAccessLevelTests: AWSS3StoragePluginTestBase {

    /// Given: An unauthenticated user
    /// When: List API with protected access level
    /// Then: Operation completes successfully with no items since there are no keys at that location.
    func testListFromProtectedForUnauthenticatedUser() async {
        let key = UUID().uuidString
        let completeInvoked = asyncExpectation(description: "Completed is invoked")
        let options = StorageListRequest.Options(accessLevel: .protected,
                                                 targetIdentityId: nil,
                                                 path: key)
        Task {
            do {
                let result = try await Amplify.Storage.list(options: options)
                XCTAssertEqual(result.items.count, 0)
                await completeInvoked.fulfill()
            } catch {
                XCTFail("Failed with \(error)")
                await completeInvoked.fulfill()
            }
        }

        await waitForExpectations([completeInvoked], timeout: TestCommonConstants.networkTimeout)
    }

    /// Given: An unauthenticated user
    /// When: List API with private access level
    /// Then: Operation fails with access denied service error
    func testListFromPrivateForUnauthenticatedUserForReturnAccessDenied() async {
        let key = UUID().uuidString
        let listFailedExpectation = asyncExpectation(description: "List Operation should fail")
        let options = StorageListRequest.Options(accessLevel: .private,
                                                 targetIdentityId: nil,
                                                 path: key)
        Task {
            do {
                _ = try await Amplify.Storage.list(options: options)
                XCTFail("Should not have completed")
                await listFailedExpectation.fulfill()
            } catch {
                await listFailedExpectation.fulfill()
                guard let storageError = error as? StorageError,
                      case let .accessDenied(description, _, _) = storageError else {
                    XCTFail("Expected accessDenied error, got \(error)")
                    return
                }
                XCTAssertEqual(description, StorageErrorConstants.accessDenied.errorDescription)
            }
        }
        await waitForExpectations([listFailedExpectation], timeout: TestCommonConstants.networkTimeout)
    }

    /// Given: `user1` user uploads some data with protected access level
    /// When: The user retrieves and removes the data
    /// Then: The operations complete successful
    func testUploadToProtectedAndListThenGetThenRemove() async {
        let key = UUID().uuidString
        let accessLevel: StorageAccessLevel = .protected
        await putThenListThenGetThenRemoveForSingleUser(username: AWSS3StoragePluginTestBase.user1,
                                                        key: key,
                                                        accessLevel: accessLevel)
    }

    /// Given: `user1` user uploads some data with private access level
    /// When: The user retrieves and removes the data
    /// Then: The operations complete successful
    func testUploadToPrivateAndListThenGetThenRemove() async {
        let key = UUID().uuidString
        let accessLevel: StorageAccessLevel = .private
        await putThenListThenGetThenRemoveForSingleUser(username: AWSS3StoragePluginTestBase.user1,
                                                        key: key,
                                                        accessLevel: accessLevel)
    }

    /// Given: `user1` user uploads some data with public access level
    /// When: `user2` lists, gets, and removes the data for `user1`
    /// Then: The list, get, and remove operations complete successful and data is retrieved then removed.
    func testUploadToPublicAndListThenGetThenRemoveFromOtherUser() async {
        let key = UUID().uuidString
        let accessLevel: StorageAccessLevel = .guest

        // Sign into user1
        await signIn(username: AWSS3StoragePluginTestBase.user1, password: AWSS3StoragePluginTestBase.password)

        let user1IdentityId = await getIdentityId()
        XCTAssertNotNil(user1IdentityId)

        // Upload data
        await upload(key: key, data: key, accessLevel: accessLevel)

        // Sign out of user1 and into user2
        await signOut()
        await signIn(username: AWSS3StoragePluginTestBase.user2, password: AWSS3StoragePluginTestBase.password)
        let user2IdentityId = await getIdentityId()
        XCTAssertNotNil(user2IdentityId)
        XCTAssertNotEqual(user1IdentityId, user2IdentityId)

        // list keys as user2
        let listExpectation = asyncExpectation(description: "List operation should be successful")
        Task {
            let keys = await list(path: key, accessLevel: accessLevel)
            await listExpectation.fulfill()
            XCTAssertNotNil(keys)
            XCTAssertEqual(keys!.count, 1)
        }
        await waitForExpectations([listExpectation], timeout: TestCommonConstants.networkTimeout)

        // get key as user2
        let getExpectation = asyncExpectation(description: "Get Operation should be successful")
        Task {
            let data = await get(key: key, accessLevel: accessLevel)
            await getExpectation.fulfill()
            XCTAssertNotNil(data)
        }
        await waitForExpectations([getExpectation], timeout: TestCommonConstants.networkTimeout)

        // remove key as user2
        await remove(key: key, accessLevel: accessLevel)

        // get key after removal should return NotFound
        let getFailedExpectation = asyncExpectation(description: "Get Operation should fail")
        Task {
            do {
                let getOptions = StorageDownloadDataRequest.Options(accessLevel: accessLevel,
                                                                    targetIdentityId: nil)
                let result = try await Amplify.Storage.downloadData(key: key, options: getOptions).value
                XCTFail("Should not have completed with result \(result)")
                await getFailedExpectation.fulfill()
            } catch {
                await getFailedExpectation.fulfill()
                guard let storageError = error as? StorageError,
                      case let .keyNotFound(_, description, _, _) = storageError else {
                    XCTFail("Expected notFound error, got \(error)")
                    return
                }
                XCTAssertEqual(description, StorageErrorConstants.localFileNotFound.errorDescription)
            }
        }
        await waitForExpectations([getFailedExpectation], timeout: TestCommonConstants.networkTimeout)
    }

    /// GivenK: `user1` user uploads some data with protected access level
    /// When: `user2` lists, gets, and removes the data for `user1`
    /// Then: The list and get operations complete successful and data is retrieved.
    func testUploadToProtectedAndListThenGetFromOtherUser() async {
        let key = UUID().uuidString
        let accessLevel: StorageAccessLevel = .protected

        // Sign into user1
        await signIn(username: AWSS3StoragePluginTestBase.user1, password: AWSS3StoragePluginTestBase.password)
        let user1IdentityId = await getIdentityId()
        XCTAssertNotNil(user1IdentityId)
        // Upload
        await upload(key: key, data: key, accessLevel: accessLevel)

        // Sign out of user1 and into user2
        await signOut()
        await signIn(username: AWSS3StoragePluginTestBase.user2, password: AWSS3StoragePluginTestBase.password)
        let user2IdentityId = await getIdentityId()
        XCTAssertNotNil(user2IdentityId)
        XCTAssertNotEqual(user1IdentityId, user2IdentityId)

        // list keys for user1 as user2
        let listExpectation = asyncExpectation(description: "List operation should be successful")
        Task {
            let keys = await list(path: key, accessLevel: accessLevel, targetIdentityId: user1IdentityId)
            await listExpectation.fulfill()
            XCTAssertNotNil(keys)
            XCTAssertEqual(keys!.count, 1)
        }
        await waitForExpectations([listExpectation], timeout: TestCommonConstants.networkTimeout)

        // get key for user1 as user2
        let getExpectation = asyncExpectation(description: "Get Operation should be successful")
        Task {
            let data = await get(key: key, accessLevel: accessLevel, targetIdentityId: user1IdentityId)
            await getExpectation.fulfill()
            XCTAssertNotNil(data)
        }
        await waitForExpectations([getExpectation], timeout: TestCommonConstants.networkTimeout)
    }

    /// Given: `user1` user uploads some data with private access level
    /// When: `user2` lists and gets the data for `user1`
    /// Then: The list and get operations fail with validation errors
    func testUploadToPrivateAndFailListThenFailGetFromOtherUser() async {
        let key = UUID().uuidString
        let accessLevel: StorageAccessLevel = .private

        // Sign into user1
        await signIn(username: AWSS3StoragePluginTestBase.user1, password: AWSS3StoragePluginTestBase.password)
        let user1IdentityId = await getIdentityId()
        XCTAssertNotNil(user1IdentityId)

        // Upload
        await upload(key: key, data: key, accessLevel: accessLevel)

        // Sign out of user1 and into user2
        await signOut()
        await signIn(username: AWSS3StoragePluginTestBase.user2, password: AWSS3StoragePluginTestBase.password)
        let user2IdentityId = await getIdentityId()
        XCTAssertNotNil(user2IdentityId)
        XCTAssertNotEqual(user1IdentityId, user2IdentityId)

        // list keys for user1 as user2 - should fail with validation error
        let listFailedExpectation = asyncExpectation(description: "List operation should fail")
        Task {
            do {
                let listOptions = StorageListRequest.Options(accessLevel: accessLevel,
                                                             targetIdentityId: user1IdentityId,
                                                             path: key)
                _ = try await Amplify.Storage.list(options: listOptions)
                XCTFail("Should not have completed")
                await listFailedExpectation.fulfill()
            } catch {
                await listFailedExpectation.fulfill()
                guard let storageError = error as? StorageError,
                      case .validation = storageError else {
                    XCTFail("Expected validation error, got \(error)")
                    return
                }
            }
        }

        await waitForExpectations([listFailedExpectation], timeout: TestCommonConstants.networkTimeout)

        // get key for user1 as user2 - should fail with validation error
        let getFailedExpectation = asyncExpectation(description: "Get Operation should fail")
        Task {
            do {
                let getOptions = StorageDownloadDataRequest.Options(accessLevel: accessLevel,
                                                                    targetIdentityId: user1IdentityId)
                let result = try await Amplify.Storage.downloadData(key: key, options: getOptions).value
                XCTFail("Should not have completed, got \(result)")
                await getFailedExpectation.fulfill()
            } catch {
                await getFailedExpectation.fulfill()
                guard let storageError = error as? StorageError,
                      case .validation = storageError else {
                    XCTFail("Expected validation error, got \(error)")
                    return
                }
            }
        }

        await waitForExpectations([getFailedExpectation], timeout: TestCommonConstants.networkTimeout)
    }

    // MARK: - Common test functions

    func putThenListThenGetThenRemoveForSingleUser(username: String, key: String, accessLevel: StorageAccessLevel) async {
        await signIn(username: username, password: AWSS3StoragePluginTestBase.password)

        // Upload
        await upload(key: key, data: key, accessLevel: accessLevel)

        // List
        let listExpectation = asyncExpectation(description: "List operation should be successful")
        Task {
            let keys = await list(path: key, accessLevel: accessLevel)
            await listExpectation.fulfill()
            XCTAssertNotNil(keys)
            XCTAssertEqual(keys!.count, 1)
        }
        await waitForExpectations([listExpectation], timeout: TestCommonConstants.networkTimeout)

        // Get
        let getExpectation = asyncExpectation(description: "Get Operation should be successful")
        Task {
            let data = await get(key: key, accessLevel: accessLevel)
            await getExpectation.fulfill()
            XCTAssertNotNil(data)
        }
        await waitForExpectations([getExpectation], timeout: TestCommonConstants.networkTimeout)

        // Remove
        await remove(key: key, accessLevel: accessLevel)

        // Get key after removal should return NotFound
        let getFailedExpectation = asyncExpectation(description: "Get Operation should fail")
        Task {
            do {
                let getOptions = StorageDownloadDataRequest.Options(accessLevel: accessLevel,
                                                                    targetIdentityId: nil)
                let result = try await Amplify.Storage.downloadData(key: key, options: getOptions).value
                XCTFail("Should not have completed with result \(result)")
                await getFailedExpectation.fulfill()
            } catch {
                await getFailedExpectation.fulfill()
                guard let storageError = error as? StorageError,
                      case let .keyNotFound(_, description, _, _) = storageError else {
                    XCTFail("Expected notFound error, got \(error)")
                    return
                }
                XCTAssertEqual(description, StorageErrorConstants.localFileNotFound.errorDescription)
            }
        }
        await waitForExpectations([getFailedExpectation], timeout: TestCommonConstants.networkTimeout)
    }

    // MARK: StoragePlugin Helper functions

    private func list(path: String, accessLevel: StorageAccessLevel, targetIdentityId: String? = nil) async -> [StorageListResult.Item]? {
        let listOptions = StorageListRequest.Options(accessLevel: accessLevel,
                                                     targetIdentityId: targetIdentityId,
                                                     path: path)
        do {
            return try await Amplify.Storage.list(options: listOptions).items
        } catch {
            XCTFail("Failed to list with error \(error)")
            return nil
        }
    }

    private func get(key: String, accessLevel: StorageAccessLevel, targetIdentityId: String? = nil) async -> Data? {
        let getOptions = StorageDownloadDataRequest.Options(accessLevel: accessLevel,
                                               targetIdentityId: targetIdentityId)
        do {
            return try await Amplify.Storage.downloadData(key: key, options: getOptions).value
        } catch {
            XCTFail("Failed to get with error \(error)")
            return nil
        }
    }

    private func upload(key: String, data: String, accessLevel: StorageAccessLevel) async {
        let uploadExpectation = asyncExpectation(description: "Upload operation should be successful")
        Task {
            do {
                let options = StorageUploadDataRequest.Options(accessLevel: accessLevel)
                _ = try await Amplify.Storage.uploadData(key: key, data: data.data(using: .utf8)!, options: options)
                await uploadExpectation.fulfill()
            } catch {
                await uploadExpectation.fulfill()
                XCTFail("Failed to put \(key) with error \(error)")
            }
        }

        await waitForExpectations([uploadExpectation], timeout: TestCommonConstants.networkTimeout)
    }

    private func remove(key: String, accessLevel: StorageAccessLevel) async {
        let removeExpectation = asyncExpectation(description: "Remove Operation should be successful")
        Task {
            do {
                let removeOptions = StorageRemoveRequest.Options(accessLevel: accessLevel)
                _ = try await Amplify.Storage.remove(key: key, options: removeOptions)
                await removeExpectation.fulfill()
            } catch {
                XCTFail("Failed to remove with error \(error)")
                await removeExpectation.fulfill()
            }

        }
        await waitForExpectations([removeExpectation], timeout: TestCommonConstants.networkTimeout)
    }

    // Auth Helpers

    private func signIn(username: String, password: String) async {
        let signInInvoked = asyncExpectation(description: "sign in completed")
        Task {
            do {
                _ = try await Amplify.Auth.signIn(username: username, password: password)
                await signInInvoked.fulfill()
            } catch {
                await signInInvoked.fulfill()
                XCTFail("Failed to Sign in user \(error)")
            }
        }
        await waitForExpectations([signInInvoked], timeout: TestCommonConstants.networkTimeout)
    }

    func getIdentityId() async -> String? {
        do {
            guard let session = try await Amplify.Auth.fetchAuthSession() as? AuthCognitoIdentityProvider else {
                XCTFail("Could not get auth session as AuthCognitoIdentityProvider")
                return nil
            }
            return try session.getIdentityId().get()

        } catch {
            XCTFail("Failed to get auth session \(error)")
            return nil
        }
    }

    func signOut() async {
        let signOutCompleted = asyncExpectation(description: "sign out completed")
        Task {
            do {
                _ = try await Amplify.Auth.signOut()
                await signOutCompleted.fulfill()
            } catch {
                await signOutCompleted.fulfill()
                XCTFail("Could not sign out user \(error)")
            }
        }

        await waitForExpectations([signOutCompleted], timeout: TestCommonConstants.networkTimeout)
    }
}
