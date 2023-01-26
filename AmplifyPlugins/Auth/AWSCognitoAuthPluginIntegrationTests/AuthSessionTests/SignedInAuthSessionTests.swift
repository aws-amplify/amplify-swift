//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import AWSMobileClient
@testable import Amplify
import AWSCognitoAuthPlugin
import AWSPluginsCore
import AmplifyTestCommon

class SignedInAuthSessionTests: AWSAuthBaseTest {

    override func setUpWithError() throws {
        try initializeAmplify()
        AuthSessionHelper.clearKeychain()
    }

    override func tearDownWithError() throws {
        _ = Amplify.Auth.signOut()
        Amplify.reset()
        sleep(2)
        AuthSessionHelper.clearKeychain()
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
            if didSucceed {
                signInExpectation.fulfill()
            }
            XCTAssertTrue(didSucceed, "SignIn operation failed - \(String(describing: error))")
        }
        wait(for: [signInExpectation], timeout: networkTimeout)

        let authSessionExpectation = expectation(description: "Received event result from fetchAuth")
        _ = Amplify.Auth.fetchAuthSession { result in
            switch result {
            case .failure(let error):
                XCTFail("Unable to fetch session: \(error)")
            case .success(let session):
                XCTAssertTrue(session.isSignedIn, "Session state should be signed In")
                authSessionExpectation.fulfill()
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
    func testSessionExpired() throws {
        let username = "integTest\(UUID().uuidString)"
        let password = "P123@\(UUID().uuidString)"
        let signInExpectation = expectation(description: "SignIn operation should complete")
        AuthSignInHelper.registerAndSignInUser(username: username, password: password,
                                               email: email) { didSucceed, error in
            if didSucceed {
                signInExpectation.fulfill()
            }
            XCTAssertTrue(didSucceed, "SignIn operation failed - \(String(describing: error))")
        }
        wait(for: [signInExpectation], timeout: networkTimeout)

        let originalSessionExpectation = expectation(description: "Received event result from fetchAuth")
        var originalSession: AuthSession?
        _ = Amplify.Auth.fetchAuthSession { result in
            switch result {
            case .failure(let error):
                XCTFail("Unable to retreive session \(error)")
            case .success(let session):
                XCTAssertTrue(session.isSignedIn)
                originalSession = session
                originalSessionExpectation.fulfill()
            }
        }
        wait(for: [originalSessionExpectation], timeout: networkTimeout)

        let originalTokenProvider = try XCTUnwrap(originalSession as? AuthCognitoTokensProvider)
        _ = try originalTokenProvider.getCognitoTokens().get()

        // Manually invalidate the tokens and then try to fetch the session.
        AuthSessionHelper.invalidateSession(username: username)
        let postExpirationExpectation = expectation(description: "Received event result from fetchAuth")
        var postExpirationSession: AuthSession?
        _ = Amplify.Auth.fetchAuthSession { result in
            switch result {
            case .failure(let error):
                XCTFail("Unable to retreive session \(error)")
            case .success(let session):
                XCTAssertTrue(session.isSignedIn)
                postExpirationSession = session
                postExpirationExpectation.fulfill()
            }
        }
        wait(for: [postExpirationExpectation], timeout: networkTimeout)

        let postExpirationTokenProvider = try XCTUnwrap(postExpirationSession as? AuthCognitoTokensProvider)
        let tokenResult = postExpirationTokenProvider.getCognitoTokens()
        switch tokenResult {
        case .failure(let error):
            switch error {
            case .sessionExpired:
                break
            default:
                XCTFail("Unexpected error case: \(error)")
            }
        case .success(let tokens):
            XCTFail("Unexpected tokens: \(String(describing: tokens).prefix(64))")
        }
    }
}
