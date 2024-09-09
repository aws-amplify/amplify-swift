//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPluginsCore
import XCTest
@testable import AWSS3StoragePlugin

class AWSS3StoragePluginAccessLevelTests: AWSS3StoragePluginTestBase {

    struct StorageAccessLevelsTestRun {
        let label: String
        let key: String
        let accessLevel: StorageAccessLevel
    }

    /// Given: An unauthenticated user
    /// When: List API with protected access level
    /// Then: Operation completes successfully with no items since there are no keys at that location.
    func testListFromProtectedForUnauthenticatedUser() async throws {
        let key = UUID().uuidString
        let options = StorageListRequest.Options(
            accessLevel: .protected,
            path: key
        )
        let items = try await Amplify.Storage.list(options: options).items
        XCTAssertEqual(items.count, 0)
    }

    /// Given: An unauthenticated user
    /// When: List API with private access level
    /// Then: Operation fails with access denied service error
    func testListFromPrivateForUnauthenticatedUserForReturnAccessDenied() async throws {
        do {
            let key = UUID().uuidString
            let options = StorageListRequest.Options(
                accessLevel: .private,
                path: key
            )
            _ = try await Amplify.Storage.list(options: options).items
            XCTFail("Expecting failure")
        } catch StorageError.accessDenied(let description, _, _) {
            XCTAssertEqual(description, StorageErrorConstants.accessDenied.errorDescription)
        } catch {
            XCTFail(String(describing: error))
        }
    }

    func testUploadAndRemoveForGuestOnly() async throws {
        let logger = Amplify.Logging.logger(forCategory: "Storage", logLevel: .verbose)

        let username = AWSS3StoragePluginTestBase.user1.lowercased()
        let password = AWSS3StoragePluginTestBase.password
        let accessLevel: StorageAccessLevel = .guest

        do {
            logger.debug("Sign In")
            let result = try await Amplify.Auth.signIn(username: username, password: password)
            XCTAssertTrue(result.isSignedIn)
            let currentUser = try await Amplify.Auth.getCurrentUser()
            XCTAssertEqual(username, currentUser.username)
        } catch {
            logger.error(error: error)
            XCTFail("Error: \(error)")
            return
        }

        let key = UUID().uuidString
        let dataInput = Data(UUID().uuidString.utf8)
        do {
            logger.debug("Upload [\(accessLevel)]")
            let uploadDataOptions = StorageUploadDataRequest.Options(accessLevel: accessLevel)
            let uploadKey = try await Amplify.Storage.uploadData(key: key, data: dataInput, options: uploadDataOptions).value
            XCTAssertEqual(key, uploadKey)

            logger.debug("Remove [\(accessLevel)]")
            let removeOptions = StorageRemoveRequest.Options(accessLevel: accessLevel)
            let removeKey = try await Amplify.Storage.remove(key: key, options: removeOptions)
            XCTAssertEqual(key, removeKey)
        } catch {
            logger.error(error: error)
            XCTFail("Error: \(error) [\(accessLevel)]")
        }
    }

    func testUploadAndListThenGetThenRemove() async throws {
        /*
         1. sign in
         2. upload (create data to upload)
         3. get list (confirm key is in list)
         4. download (using original key)
         5. remove (using key)
         6. download and confirm not found error
         */

        let logger = Amplify.Logging.logger(forCategory: "Storage", logLevel: .verbose)

        let levels: [StorageAccessLevel] = [
            .private,
            .protected,
            .guest
        ]

        let username = AWSS3StoragePluginTestBase.user1.lowercased()
        let password = AWSS3StoragePluginTestBase.password
        logger.debug("Signing in as user1")
        let result = try await Amplify.Auth.signIn(username: username, password: password)
        XCTAssertTrue(result.isSignedIn)
        let currentUser = try await Amplify.Auth.getCurrentUser()
        XCTAssertEqual(username, currentUser.username)
        let isSignedIn = result.isSignedIn

        // must be signed in to continue
        guard isSignedIn else { return }

        for accessLevel in levels {
            logger.debug("Testing storage access level: \(accessLevel)")

            let key = UUID().uuidString
            let dataInput = Data(UUID().uuidString.utf8)
            logger.debug("Upload [\(accessLevel)]")
            let uploadDataOptions = StorageUploadDataRequest.Options(accessLevel: accessLevel)
            let uploadKey = try await Amplify.Storage.uploadData(key: key, data: dataInput, options: uploadDataOptions).value
            XCTAssertEqual(key, uploadKey)

            logger.debug("List [\(accessLevel)]")
            let listOptions = StorageListRequest.Options(
                accessLevel: accessLevel,
                path: key
            )
            let keys = try await Amplify.Storage.list(options: listOptions).items
            XCTAssertEqual(keys.count, 1)

            logger.debug("Download [\(accessLevel)]")
            let downloadDataOptions = StorageDownloadDataRequest.Options(accessLevel: accessLevel)
            let dataOutput = try await Amplify.Storage.downloadData(key: key, options: downloadDataOptions).value
            XCTAssertNotNil(dataOutput, "Data undefined")
            XCTAssertEqual(dataInput.count, dataOutput.count)
            XCTAssertEqual(dataInput, dataOutput)

            logger.debug("Remove [\(accessLevel)]")
            let removeOptions = StorageRemoveRequest.Options(accessLevel: accessLevel)
            let removeKey = try await Amplify.Storage.remove(key: key, options: removeOptions)
            XCTAssertEqual(key, removeKey)

            do {
                logger.debug("Download after remove [\(accessLevel)]")
                _ = try await Amplify.Storage.downloadData(key: key, options: downloadDataOptions).value
                XCTFail("Expecting a StorageError.keyNotFound error")
            } catch StorageError.keyNotFound(_, _, _, let error) {
                XCTAssertNil(error)
            } catch {
                XCTFail("Expected Not Found error: \(error) [\(accessLevel)]")
            }
        }
    }

    /// Validate access levels between 2 users for each access level.
    func testAccessLevelsBetweenTwoUsers() async throws {
        let logger = Amplify.Logging.logger(forCategory: "Storage", logLevel: .verbose)

        let testRuns: [StorageAccessLevelsTestRun] = [
            // user 2 can read upload by user 1 with guest access
            .init(label: "Guest", key: UUID().uuidString, accessLevel: .guest),
            // user 2 can read upload by user 1 with protected access
            .init(label: "Protected", key: UUID().uuidString, accessLevel: .protected),
            // user 2 can get access denied error from upload by user 1 with private access
            .init(label: "Private", key: UUID().uuidString, accessLevel: .private),
        ]

        for testRun in testRuns {
                do {
                    logger.debug("Starting loop for \(testRun.label)")
                    logger.debug("Signing out at start of loop")
                    await signOut()

                    logger.debug("Signing in user1")
                    let user1SignedIn = try await Amplify.Auth.signIn(username: AWSS3StoragePluginTestBase.user1, password: AWSS3StoragePluginTestBase.password).isSignedIn
                    XCTAssertTrue(user1SignedIn)

                    logger.debug("Getting identity for user1")
                    let user1IdentityId = try await getIdentityId()
                    XCTAssertNotNil(user1IdentityId)

                    logger.debug("Uploading as user1 with \(testRun.accessLevel) access level")
                    let options = StorageUploadDataRequest.Options(accessLevel: testRun.accessLevel)
                    _ = try await Amplify.Storage.uploadData(key: testRun.key, data: Data(testRun.key.utf8), options: options).value

                    logger.debug("Getting list as user1")
                    let listOptions1 = StorageListRequest.Options(
                        accessLevel: testRun.accessLevel,
                        path: testRun.key
                    )
                    let keys1 = try await Amplify.Storage.list(options: listOptions1).items.filter {
                        $0.key == testRun.key
                    }
                    XCTAssertEqual(keys1.count, 1)

                    logger.debug("Signing out as user1")
                    await signOut()

                    logger.debug("Signing in as user2")
                    let user2SignedIn = try await Amplify.Auth.signIn(username: AWSS3StoragePluginTestBase.user2, password: AWSS3StoragePluginTestBase.password).isSignedIn
                    XCTAssertTrue(user2SignedIn)

                    logger.debug("Getting identity for user2")
                    let user2IdentityId = try await getIdentityId()
                    XCTAssertNotNil(user2IdentityId)
                    XCTAssertNotEqual(user1IdentityId, user2IdentityId)

                    let targetIdentityId = testRun.accessLevel == .guest ? nil : user1IdentityId

                    if testRun.accessLevel == .private {
                        logger.debug("Testing private access as user2")
                        // check for Access Denied error
                        do {
                            logger.debug("Getting list as user2")
                            let listOptions2 = StorageListRequest.Options(
                                accessLevel: testRun.accessLevel,
                                targetIdentityId: user1IdentityId,
                                path: testRun.key
                            )
                            try await Amplify.Storage.list(options: listOptions2)
                            XCTFail("Expecting validation error")
                        } catch StorageError.validation(_, let errorDescription, _, _) {
                            XCTAssertEqual(errorDescription, StorageErrorConstants.invalidAccessLevelWithTarget.errorDescription)
                        } catch {
                            XCTFail(String(describing: error))
                        }

                        logger.debug("Signing out as user2")
                        await signOut()

                        logger.debug("Signing in user1")
                        let user1SignedIn = try await Amplify.Auth.signIn(username: AWSS3StoragePluginTestBase.user1, password: AWSS3StoragePluginTestBase.password).isSignedIn
                        XCTAssertTrue(user1SignedIn)

                        logger.debug("Removing key as user1")
                        await remove(key: testRun.key, accessLevel: testRun.accessLevel)
                    } else {
                        logger.debug("Getting list as user2: \(testRun.accessLevel)")
                        let listOptions2 = StorageListRequest.Options(
                            accessLevel: testRun.accessLevel,
                            targetIdentityId: targetIdentityId,
                            path: testRun.key
                        )
                        let keys2 = try await Amplify.Storage.list(options: listOptions2).items.filter {
                            $0.key == testRun.key
                        }
                        XCTAssertEqual(keys2.count, 1)

                        logger.debug("Downloading as user2")
                        let downloadDataOptions = StorageDownloadDataRequest.Options(
                            accessLevel: testRun.accessLevel,
                            targetIdentityId: targetIdentityId
                        )
                        let data = try await Amplify.Storage.downloadData(key: testRun.key, options: downloadDataOptions).value
                        XCTAssertNotNil(data)

                        logger.debug("Removing key as user2")
                        await remove(key: testRun.key, accessLevel: testRun.accessLevel)
                    }
                } catch {
                    logger.debug("Error: \(error)")
                    XCTFail("Error: \(error)")
                }
        }

    }

    // MARK: - Auth Helpers -

    func getIdentityId() async throws -> String? {
        guard let session = try await Amplify.Auth.fetchAuthSession() as? AuthCognitoIdentityProvider else {
            throw AuthError.unknown("Could not get session", nil)
        }
        return try session.getIdentityId().get()
    }
}
