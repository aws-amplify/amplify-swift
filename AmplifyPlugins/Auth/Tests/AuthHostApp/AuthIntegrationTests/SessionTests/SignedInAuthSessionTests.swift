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

class SignedInAuthSessionTests: AWSAuthBaseTest {

    override func setUp() async throws {
        try await super.setUp()
        AuthSessionHelper.clearSession()
    }

    override func tearDown() async throws {
        try await super.tearDown()
        AuthSessionHelper.clearSession()
    }

    /// Test if force refresh session ignores the cached
    ///
    /// - Given: A signedout Amplify Auth Category
    /// - When:
    ///    - I sign in to the Auth Category and do a force refresh
    /// - Then:
    ///    - I should receive a valid session in signed in state, which is not the same as before
    ///
    func testSuccessfulForceSessionFetch() async throws {
        let username = "integTest\(UUID().uuidString)"
        let password = "P123@\(UUID().uuidString)"
        let didSucceed = try await AuthSignInHelper.registerAndSignInUser(username: username, password: password,
                                               email: defaultTestEmail)
        XCTAssertTrue(didSucceed, "SignIn operation failed")

        let firstCognitoSession = try await AuthSessionHelper.getCurrentAmplifySession(
            for: self,
            with: networkTimeout)

        let secondCognitoSession = try await AuthSessionHelper.getCurrentAmplifySession(
            for: self,
            with: networkTimeout)

        let thirdCognitoSession = try await AuthSessionHelper.getCurrentAmplifySession(
            shouldForceRefresh: true,
            for: self,
            with: networkTimeout)

        let fourthCognitoSession = try await AuthSessionHelper.getCurrentAmplifySession(
            for: self,
            with: networkTimeout)

        // First 2 sessions should match
        XCTAssertEqual(firstCognitoSession, secondCognitoSession)

        // Sessions after force refresh should not match
        XCTAssertNotEqual(secondCognitoSession, thirdCognitoSession)

        // Third and fourth session should match as it is retrieved from cache
        XCTAssertEqual(thirdCognitoSession, fourthCognitoSession)
    }

    /// Test if successful session is retreived after a user signin
    ///
    /// - Given: A signedout Amplify Auth Category
    /// - When:
    ///    - I sign in to the Auth Category
    /// - Then:
    ///    - I should receive a valid session in signed in state
    ///
    func testSuccessfulSessionFetch() async throws {
        let username = "integTest\(UUID().uuidString)"
        let password = "P123@\(UUID().uuidString)"
        let didSucceed = try await AuthSignInHelper.registerAndSignInUser(username: username, password: password,
                                               email: defaultTestEmail)
        XCTAssertTrue(didSucceed, "SignIn operation failed")

        let session = try await Amplify.Auth.fetchAuthSession()
        XCTAssertTrue(session.isSignedIn, "Session state should be signed In")
    }

    /// Test if I get sessionExpired error on session expiry
    ///
    /// - Given: Valid signedIn session
    /// - When:
    ///    - The session expired and I try to fetch the auth session
    /// - Then:
    ///    - I should get the signedin state as true but with token result as sessionExpired
    ///
    func testSessionExpired() async throws {
        throw XCTSkip("TODO: fix this test. We need to find a way to mock credential store")
        let username = "integTest\(UUID().uuidString)"
        let password = "P123@\(UUID().uuidString)"
        let didSucceed = try await AuthSignInHelper.registerAndSignInUser(username: username, password: password,
                                               email: defaultTestEmail)
        XCTAssertTrue(didSucceed, "SignIn operation failed")

        let session = try await Amplify.Auth.fetchAuthSession()
        do {
            let authSession = session as? AuthCognitoTokensProvider
            _ = try authSession?.getCognitoTokens().get()
        } catch {
            XCTFail("Should not receive error \(error)")
        }

        // Manually invalidate the tokens and then try to fetch the session.
        AuthSessionHelper.invalidateSession(with: self.amplifyConfiguration)
        let anotherSession = try await Amplify.Auth.fetchAuthSession()
        do {
            let authSession = anotherSession as? AuthCognitoTokensProvider
            _ = try authSession?.getCognitoTokens().get()
            XCTFail("Should not receive a valid token")
        } catch {
            guard let authError = error as? AuthError,
                  case .sessionExpired = authError else {
                XCTFail("Should receive a session expired error but received \(error)")
                return
            }
        }
    }

    /// Test if signedOut error is returned when session is cleared
    ///
    /// - Given: Valid signedIn session
    /// - When:
    ///    - The session is cleared and I try to fetch the auth session
    /// - Then:
    ///    - I should get the signedin state as false but with token result as seignedOut
    ///
    func testSessionCleared() async throws {
        throw XCTSkip("TODO: fix this test. We need to find a way to mock credential store")
        let username = "integTest\(UUID().uuidString)"
        let password = "P123@\(UUID().uuidString)"
        let didSucceed = try await AuthSignInHelper.registerAndSignInUser(username: username, password: password,
                                               email: defaultTestEmail)
        XCTAssertTrue(didSucceed, "SignIn operation failed")

        let session = try await Amplify.Auth.fetchAuthSession()
        do {
            let authSession = session as? AuthCognitoTokensProvider
            _ = try authSession?.getCognitoTokens().get()
        } catch {
            XCTFail("Should not receive error \(error)")
        }

        AuthSessionHelper.clearSession()
        let anotherSession = try await Amplify.Auth.fetchAuthSession()
        do {
            let authSession = anotherSession as? AuthCognitoTokensProvider
            _ = try authSession?.getCognitoTokens().get()
            XCTFail("Should not receive a valid token")
        } catch {
            guard let authError = error as? AuthError,
                  case .signedOut = authError else {
                XCTFail("Should receive a session expired error but received \(error)")
                return
            }
        }
    }

    /// Test if successful session is retreived after a user signin and tried to fetch auth session multiple times
    ///
    /// - Given: A signedout Amplify Auth Category
    /// - When:
    ///    - I sign in to the Auth Category, and try fetch Auth session multiple times.
    /// - Then:
    ///    - I should receive a valid session in signed in state
    ///
    func testMultipleSuccessfulSessionFetch() async throws {
        let username = "integTest\(UUID().uuidString)"
        let password = "P123@\(UUID().uuidString)"
        let didSucceed = try await AuthSignInHelper.registerAndSignInUser(username: username, password: password,
                                               email: defaultTestEmail)
        XCTAssertTrue(didSucceed, "SignIn operation failed")

        let firstSession = try await Amplify.Auth.fetchAuthSession()
        XCTAssertTrue(firstSession.isSignedIn, "Session state should be signed In")

        let secondSession = try await Amplify.Auth.fetchAuthSession()
        XCTAssertTrue(secondSession.isSignedIn, "Session state should be signed In")
    }

    /// Test if successful session is retreived with signOut operation happening in between
    ///
    /// - Given: A signedIn auth plugin
    /// - When:
    ///    - I start a parallel fetchAuthSession
    ///    - I invoke a signOut
    /// - Then:
    ///    - I should receive a valid sessions
    ///
    func testMultipleParallelSuccessfulSessionFetch() async throws {
        let username = "integTest\(UUID().uuidString)"
        let password = "P123@\(UUID().uuidString)"
        let didSucceed = try await AuthSignInHelper.registerAndSignInUser(
            username: username,
            password: password,
            email: defaultTestEmail
        )
        XCTAssertTrue(didSucceed, "SignIn operation failed")

        let identityIDExpectation = expectation(description: "Identity id should be fetched")
        identityIDExpectation.expectedFulfillmentCount = 100
        for index in 1...100 {
            Task {

                // Randomly yield the task so that below execution of signOut happen
                if index%6 == 0 {
                    await Task.yield()
                }
                let firstSession = try await Amplify.Auth.fetchAuthSession()
                guard let cognitoSession = firstSession as? AWSAuthCognitoSession,
                     let _ = try? cognitoSession.identityIdResult.get() else {
                    XCTFail("Could not fetch Identity ID")
                    return
                }
                identityIDExpectation.fulfill()
            }
        }

        await Task.yield()
        _ = await Amplify.Auth.signOut()
        let fetchSessionExptectation = expectation(description: "Session should be fetched")
        fetchSessionExptectation.expectedFulfillmentCount = 50
        for _ in 1...50 {
            Task {
                let firstSession = try await Amplify.Auth.fetchAuthSession()
                XCTAssertFalse(firstSession.isSignedIn, "Session state should be signed out")
                fetchSessionExptectation.fulfill()
            }
        }
        await waitForExpectations(timeout: networkTimeout)
    }

    /// Test if successful session is retrieved before and after a user sign in
    ///
    /// - Given: A signed out Amplify Auth Category
    /// - When:
    ///    - I call fetchAuthSession
    /// - Then:
    ///    - I get a signed out session
    /// - After that When:
    ///    - I sign in to the Auth Category
    /// - Then:
    ///    - I should receive a valid session in signed in state
    /// - After that When:
    ///    - I call fetchAuthSession
    /// - Then:
    ///    - I should receive a valid session in signed in state
    func testSuccessfulSessionFetchAndSignIn() async throws {
        let username = "integTest\(UUID().uuidString)"
        let password = "P123@\(UUID().uuidString)"

        var session = try await Amplify.Auth.fetchAuthSession()
        XCTAssertFalse(session.isSignedIn, "Session state should be signed out")

        let didSucceed = try await AuthSignInHelper.registerAndSignInUser(
            username: username,
            password: password,
            email: defaultTestEmail)
        XCTAssertTrue(didSucceed, "SignIn operation failed")

        session = try await Amplify.Auth.fetchAuthSession()
        XCTAssertTrue(session.isSignedIn, "Session state should be signed In")
    }
}
