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

//TODO: ENABLE TESTS when SIGN UP helper is available
/*
class SignedInAuthSessionTests: AWSAuthBaseTest {

    override func setUp() {
        super.setUp()
        initializeAmplify()
    }

    override func tearDown() {
        super.tearDown()
        Amplify.reset()
        sleep(2)
    }

    /// Test if successful session is retreived after a user signin
    ///
    /// - Given: A signedout Amplify Auth Category
    /// - When:
    ///    - I sign in to the Auth Category
    /// - Then:
    ///    - I should receive a valid session in signed in state
    ///
    func testSuccessfulSessionFetch() {
        let username = "integTest\(UUID().uuidString)"
        let password = "P123@\(UUID().uuidString)"
        let signInExpectation = expectation(description: "SignIn operation should complete")
        AuthSignInHelper.registerAndSignInUser(username: username, password: password,
                                               email: email) { didSucceed, error in
            signInExpectation.fulfill()
            XCTAssertTrue(didSucceed, "SignIn operation failed - \(String(describing: error))")
        }
        wait(for: [signInExpectation], timeout: networkTimeout)

        let authSessionExpectation = expectation(description: "Received event result from fetchAuth")
        _ = Amplify.Auth.fetchAuthSession { result in
            defer {
                authSessionExpectation.fulfill()
            }
            switch result {
            case .success(let session):
                XCTAssertTrue(session.isSignedIn, "Session state should be signed In")
            case .failure(let error):
                XCTFail("Should not receive error \(error)")
            }
        }
        wait(for: [authSessionExpectation], timeout: networkTimeout)
    }

    /// Test if I get sessionExpired error on session expiry
    ///
    /// - Given: Valid signedIn session
    /// - When:
    ///    - The session expired and I try to fetch the auth session
    /// - Then:
    ///    - I should get the signedin state as true but with token result as sessionExpired
    ///
    func testSessionExpired() {
        let username = "integTest\(UUID().uuidString)"
        let password = "P123@\(UUID().uuidString)"
        let signInExpectation = expectation(description: "SignIn operation should complete")
        AuthSignInHelper.registerAndSignInUser(username: username, password: password,
                                               email: email) { didSucceed, error in
            signInExpectation.fulfill()
            XCTAssertTrue(didSucceed, "SignIn operation failed - \(String(describing: error))")
        }
        wait(for: [signInExpectation], timeout: networkTimeout)

        let authSessionExpectation = expectation(description: "Received event result from fetchAuth")
        _ = Amplify.Auth.fetchAuthSession { result in
            defer {
                authSessionExpectation.fulfill()
            }

            do {
                let authSession = try result.get() as? AuthCognitoTokensProvider
                _ = try authSession?.getCognitoTokens().get()
            } catch {
                XCTFail("Should not receive error \(error)")
            }
        }
        wait(for: [authSessionExpectation], timeout: networkTimeout)

        // Manually invalidate the tokens and then try to fetch the session.
        AuthSessionHelper.invalidateSession(username: username)
        let authSessionExpiredExpectation = expectation(description: "Received event result from fetchAuth")
        _ = Amplify.Auth.fetchAuthSession { result in
            defer {
                authSessionExpiredExpectation.fulfill()
            }

            do {
                let authSession = try result.get() as? AuthCognitoTokensProvider
                _ = try authSession?.getCognitoTokens().get()
                XCTFail("Should not receive a valid token")
            } catch {
                guard let authError = error as? AuthError,
                      case .sessionExpired = authError else {
                    XCTFail("Should receive a session expired error")
                    return
                }
            }
        }
        wait(for: [authSessionExpiredExpectation], timeout: networkTimeout)
    }
}
 */
