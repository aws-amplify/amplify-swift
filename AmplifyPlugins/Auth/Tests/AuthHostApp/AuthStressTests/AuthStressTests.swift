//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
import AWSCognitoAuthPlugin
import AWSPluginsCore

final class AuthStressTests: AWSAuthBaseTest {

    let concurrencyLimit = 50
    
    override func setUp() async throws {
        try await super.setUp()
        AuthSessionHelper.clearSession()
    }

    override func tearDown() async throws {
        try await super.tearDown()
        AuthSessionHelper.clearSession()
    }
    
    // MARK: - Stress tests
    
    /// Test concurrent fetching of the user's email attribute.
    ///
    /// - Given: A confirmed user
    /// - When:
    ///    - I invoke Amplify.Auth.fetchUserAttributes simultaneously from 50 tasks
    /// - Then:
    ///    - The request should be successful and the email attribute should have the correct value
    ///
    func testMultipleFetchUserAttributes() async throws {
        let username = "integTest\(UUID().uuidString)"
        let password = "P123@\(UUID().uuidString)"

        let didSucceed = try await AuthSignInHelper.registerAndSignInUser(username: username,
                                               password: password,
                                               email: defaultTestEmail)
        XCTAssertTrue(didSucceed, "SignIn operation failed")

        let fetchUserAttributesExpectation = asyncExpectation(description: "Fetch user attributes was successful",
                                                              expectedFulfillmentCount: concurrencyLimit)
        for _ in 1...concurrencyLimit {
            Task {
                let attributes = try await Amplify.Auth.fetchUserAttributes()
                if let emailAttribute = attributes.filter({ $0.key == .email }).first {
                    XCTAssertEqual(emailAttribute.value, self.defaultTestEmail)
                } else {
                    XCTFail("Email attribute not found")
                }
                await fetchUserAttributesExpectation.fulfill()
            }
        }
        
        await waitForExpectations([fetchUserAttributesExpectation], timeout: 30)
    }

    /// Test if successful session is retreived after a user signin and tried to fetch auth session multiple times
    /// simultaneously
    ///
    /// - Given: A signedout Amplify Auth Category
    /// - When:
    ///    - I sign in to the Auth Category, and try fetch Auth session from 50 tasks
    /// - Then:
    ///    - I should receive a valid session in signed in state
    ///
    func testMultipleFetchAuthSessionAfterSignIn() async throws {
        let username = "integTest\(UUID().uuidString)"
        let password = "P123@\(UUID().uuidString)"
        let didSucceed = try await AuthSignInHelper.registerAndSignInUser(username: username, password: password,
                                               email: defaultTestEmail)
        XCTAssertTrue(didSucceed, "SignIn operation failed")

        let fetchAuthSessionExpectation = asyncExpectation(description: "Fetch auth session was successful",
                                                           expectedFulfillmentCount: concurrencyLimit)
        for _ in 1...concurrencyLimit {
            Task {
                let session = try await Amplify.Auth.fetchAuthSession()
                XCTAssertTrue(session.isSignedIn, "Session state should be signed In")
                await fetchAuthSessionExpectation.fulfill()
            }
        }
        
        await waitForExpectations([fetchAuthSessionExpectation], timeout: networkTimeout)
    }
    
    /// Test if successful session is retrieved with random force refresh operation happening in between
    ///
    /// - Given: A signedIn auth plugin
    /// - When:
    ///    - I start a parallel fetchAuthSession from 50 tasks simultaneously
    ///    - I invoke a force refresh
    /// - Then:
    ///    - I should receive a valid sessions
    ///
    func testMultipleFetchAuthSessionWithRandomForceRefresh() async throws {
        let username = "integTest\(UUID().uuidString)"
        let password = "P123@\(UUID().uuidString)"
        let didSucceed = try await AuthSignInHelper.registerAndSignInUser(
            username: username,
            password: password,
            email: defaultTestEmail
        )
        XCTAssertTrue(didSucceed, "SignIn operation failed")

        let identityIDExpectation = asyncExpectation(description: "Identity id should be fetched",
                                                     expectedFulfillmentCount: concurrencyLimit)
        for index in 1...concurrencyLimit {
            Task {
                // Randomly yield the task so that below execution of force refresh happens
                let session : AuthSession
                if index == concurrencyLimit/2 {
                    session = try await Amplify.Auth.fetchAuthSession(options: .forceRefresh())
                } else {
                    session = try await Amplify.Auth.fetchAuthSession()
                }
                guard let cognitoSession = session as? AWSAuthCognitoSession,
                      let _ = try? cognitoSession.identityIdResult.get() else {
                    XCTFail("Could not fetch Identity ID")
                    return
                }
                await identityIDExpectation.fulfill()
            }
        }
        
        await waitForExpectations([identityIDExpectation], timeout: networkTimeout)
    }
    
    /// Test if we can fetch auth session in signedOut state
    ///
    /// - Given: Auth category with a signedOut state
    /// - When:
    ///    - I invoke fetchAuthSession from 50 tasks simulateneously
    /// - Then:
    ///    - Valid response with signedOut state = false
    ///
    func testMultipleFetchAuthSessionWhenSignedOut() async throws {
        let fetchAuthSessionExpectation = asyncExpectation(description: "Session state should not be signedIn",
                                           expectedFulfillmentCount: concurrencyLimit)
        for _ in 1...concurrencyLimit {
            Task {
                let result = try await Amplify.Auth.fetchAuthSession()
                XCTAssertFalse(result.isSignedIn, "Session state should be not signed In")
                let credentialsResult = (result as? AuthAWSCredentialsProvider)?.getAWSCredentials()
                guard let awsCredentails = try? credentialsResult?.get() else {
                    XCTFail("Could not fetch aws credentials")
                    return
                }
                XCTAssertNotNil(awsCredentails.accessKeyId, "Access key should not be nil")
                await fetchAuthSessionExpectation.fulfill()
            }
        }
        
        await waitForExpectations([fetchAuthSessionExpectation], timeout: networkTimeout)
    }
    
    /// Test concurrent invocations of get current user API
    ///
    /// - Given: A signedIn Amplify Auth Category
    /// - When:
    ///    - I call Amplify.Auth.getCurrentUser for 50 tasks simultaneously
    /// - Then:
    ///    - I should receive a valid user back
    ///
    func testMultipleGetCurrentUser() async throws {
        let username = "integtest\(UUID().uuidString)"
        let password = "P123@\(UUID().uuidString)"
        let didSucceed = try await AuthSignInHelper.registerAndSignInUser(
            username: username,
            password: password,
            email: defaultTestEmail)

        XCTAssertTrue(didSucceed, "SignIn operation failed")
        
        let getCurrentUserExpectation = asyncExpectation(description: "getCurrentUser() is successful",
                                                         expectedFulfillmentCount: concurrencyLimit)
        for _ in 1...concurrencyLimit {
            Task {
                let authUser = try await Amplify.Auth.getCurrentUser()
                XCTAssertEqual(authUser.username.lowercased(), username.lowercased())
                XCTAssertNotNil(authUser.userId)
                await getCurrentUserExpectation.fulfill()
            }
        }
        
        await waitForExpectations([getCurrentUserExpectation], timeout: networkTimeout)
    }
}
