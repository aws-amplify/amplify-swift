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
        let result = await wait(with: completeInvoked) {
            return try await Amplify.Storage.list(options: options)
        }
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.items.count, 0)
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
        let listError = await waitError(with: listFailedExpectation) {
            return try await Amplify.Storage.list(options: options)
        }

        guard let listError = listError else {
            XCTFail("Expected error from List operation")
            return
        }

        guard case let .accessDenied(description, _, _) = (listError as? StorageError) else {
            XCTFail("Expected accessDenied error, got \(listError)")
            return
        }
        XCTAssertEqual(description, StorageErrorConstants.accessDenied.errorDescription)
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
        let keys = await list(path: key, accessLevel: accessLevel)
        XCTAssertNotNil(keys)
        XCTAssertEqual(keys?.count, 1)

        // get key as user2
        let data =  await get(key: key, accessLevel: accessLevel)
        XCTAssertNotNil(data)

        // remove key as user2
        await remove(key: key, accessLevel: accessLevel)

        // get key after removal should return NotFound
        let getFailedExpectation = asyncExpectation(description: "Download operation should fail")
        let getOptions = StorageDownloadDataRequest.Options(accessLevel: accessLevel,
                                                            targetIdentityId: nil)
        let getError = await waitError(with: getFailedExpectation) {
            return try await Amplify.Storage.downloadData(key: key, options: getOptions).value
        }

        guard let getError = getError else {
            XCTFail("Expected error from Download operation")
            return
        }

        guard case .keyNotFound(_, _, _, _) = (getError as? StorageError) else {
            XCTFail("Expected notFound error, got \(getError)")
            return
        }
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
        let keys = await list(path: key, accessLevel: accessLevel, targetIdentityId: user1IdentityId)
        XCTAssertNotNil(keys)
        XCTAssertEqual(keys?.count, 1)

        // get key for user1 as user2
        let data =  await get(key: key, accessLevel: accessLevel, targetIdentityId: user1IdentityId)
        XCTAssertNotNil(data)
        
        // Remove the key as user1
        await signOut()
        await signIn(username: AWSS3StoragePluginTestBase.user1, password: AWSS3StoragePluginTestBase.password)
        await remove(key: key, accessLevel: accessLevel)
    }

    // TODO: review this failing test

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
        let listOptions = StorageListRequest.Options(accessLevel: accessLevel,
                                                     targetIdentityId: user1IdentityId,
                                                     path: key)
        let listError = await waitError(with: listFailedExpectation) {
            return try await Amplify.Storage.list(options: listOptions)
        }

        guard case .validation  = (listError as? StorageError) else {
            XCTFail("Expected validation error, got \(listError ?? "nil")")
            return
        }

        // get key for user1 as user2 - should fail with validation error
        let getFailedExpectation = asyncExpectation(description: "Download operation should fail")
        let getOptions = StorageDownloadDataRequest.Options(accessLevel: accessLevel,
                                                            targetIdentityId: user1IdentityId)
        let getError = await waitError(with: getFailedExpectation) {
            return try await Amplify.Storage.downloadData(key: key, options: getOptions).value
        }

        guard let getError = getError else {
            XCTFail("Expected error from download operation")
            return
        }

        guard case .validation = (getError as? StorageError) else {
            XCTFail("Expected validation error, got \(getError)")
            return
        }
        
        // Remove the key as user1
        await signOut()
        await signIn(username: AWSS3StoragePluginTestBase.user1, password: AWSS3StoragePluginTestBase.password)
        await remove(key: key, accessLevel: accessLevel)
    }

    // MARK: - Common test functions

    func putThenListThenGetThenRemoveForSingleUser(username: String, key: String,
                                                   accessLevel: StorageAccessLevel,
                                                   file: StaticString = #file,
                                                   line: UInt = #line) async {
        await signIn(username: username, password: AWSS3StoragePluginTestBase.password)

        // Upload
        await upload(key: key, data: key, accessLevel: accessLevel, file: file, line: line)

        // List
        let keys = await list(path: key, accessLevel: accessLevel)
        XCTAssertNotNil(keys, "Key undefined", file: file, line: line)
        XCTAssertEqual(keys?.count, 1, "Keys count", file: file, line: line)

        // Get
        let data = await get(key: key, accessLevel: accessLevel, file: file, line: line)
        XCTAssertNotNil(data, "Data undefined", file: file, line: line)

        // Remove
        await remove(key: key, accessLevel: accessLevel)

        // Get key after removal should return NotFound
        let getFailedExpectation = asyncExpectation(description: "Get Operation should fail")
        let getOptions = StorageDownloadDataRequest.Options(accessLevel: accessLevel,
                                                            targetIdentityId: nil)
        let getError = await waitError(with: getFailedExpectation, file: file, line: line) {
            try await Amplify.Storage.downloadData(key: key, options: getOptions).value
        }

        guard let getError = getError else {
            XCTFail("Expected error from download operation", file: file, line: line)
            return
        }

        guard case .keyNotFound(_, _, _, _) = (getError as? StorageError) else {
            XCTFail("Expected notFound error, got \(getError)", file: file, line: line)
            return
        }
    }

    // MARK: StoragePlugin Helper functions

    private func list(path: String, accessLevel: StorageAccessLevel, targetIdentityId: String? = nil,
                      file: StaticString = #file,
                      line: UInt = #line) async -> [StorageListResult.Item]? {
        return await wait(name: "List operation should be successful") {
            let listOptions = StorageListRequest.Options(accessLevel: accessLevel,
                                                         targetIdentityId: targetIdentityId,
                                                         path: path)
            return try await Amplify.Storage.list(options: listOptions).items
        }
    }

    private func get(key: String, accessLevel: StorageAccessLevel, targetIdentityId: String? = nil,
                     file: StaticString = #file,
                     line: UInt = #line) async -> Data? {
        return await wait(name: "Download operation should be successful", file: file, line: line) {
            let getOptions = StorageDownloadDataRequest.Options(accessLevel: accessLevel,
                                                                targetIdentityId: targetIdentityId)
            return try await Amplify.Storage.downloadData(key: key, options: getOptions).value
        }
    }

    private func upload(key: String, data: String,
                        accessLevel: StorageAccessLevel,
                        file: StaticString = #file,
                        line: UInt = #line) async {
        let options = StorageUploadDataRequest.Options(accessLevel: accessLevel)
        let result = await wait(name: "Upload operation should be successful", file: file, line: line) {
            return try await Amplify.Storage.uploadData(key: key, data: data.data(using: .utf8)!, options: options).value
        }
        XCTAssertNotNil(result, "Result undefined", file: file, line: line)
    }

    // Auth Helpers

    private func signIn(username: String, password: String,
                        file: StaticString = #file,
                        line: UInt = #line) async {
        let result = await wait(name: "Sign in completed") {
            return try await Amplify.Auth.signIn(username: username, password: password)
        }
        XCTAssertNotNil(result, "Result undefined", file: file, line: line)
    }

    func getIdentityId(file: StaticString = #file, line: UInt = #line) async -> String? {
        return await wait(name: "Fetch Auth Session completed") {
            guard let session = try await Amplify.Auth.fetchAuthSession() as? AuthCognitoIdentityProvider else {
                XCTFail("Could not get auth session as AuthCognitoIdentityProvider", file: file, line: line)
                throw AuthError.unknown("Could not get session", nil)
            }
            return try session.getIdentityId().get()
        }
    }
}
