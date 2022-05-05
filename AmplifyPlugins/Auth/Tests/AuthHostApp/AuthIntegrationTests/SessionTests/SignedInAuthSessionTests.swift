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

    override func setUp() {
        super.setUp()
        initializeAmplify()
        AuthSessionHelper.clearSession()
    }

    override func tearDown() {
        super.tearDown()
        AuthSessionHelper.clearSession()
        Amplify.reset()
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
                                               email: defaultTestEmail) { didSucceed, error in
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
                                               email: defaultTestEmail) { didSucceed, error in
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
        AuthSessionHelper.invalidateSession(with: self.amplifyConfiguration)
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
                    XCTFail("Should receive a session expired error but received \(error)")
                    return
                }
            }
        }
        wait(for: [authSessionExpiredExpectation], timeout: networkTimeout)
    }


    /// Test if signedOut error is returned when session is cleared
    ///
    /// - Given: Valid signedIn session
    /// - When:
    ///    - The session is cleared and I try to fetch the auth session
    /// - Then:
    ///    - I should get the signedin state as false but with token result as seignedOut
    ///
    func testSessionCleared() {
        let username = "integTest\(UUID().uuidString)"
        let password = "P123@\(UUID().uuidString)"
        let signInExpectation = expectation(description: "SignIn operation should complete")
        AuthSignInHelper.registerAndSignInUser(username: username, password: password,
                                               email: defaultTestEmail) { didSucceed, error in
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

        AuthSessionHelper.clearSession()
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
                      case .signedOut = authError else {
                    XCTFail("Should receive a session expired error but received \(error)")
                    return
                }
            }
        }
        wait(for: [authSessionExpiredExpectation], timeout: networkTimeout)
    }
    
    /// Test if successful session is retreived after a user signin and tried to fetch auth session multiple times
    ///
    /// - Given: A signedout Amplify Auth Category
    /// - When:
    ///    - I sign in to the Auth Category, and try fetch Auth session multiple times.
    /// - Then:
    ///    - I should receive a valid session in signed in state
    ///
    func testMultipleSuccessfulSessionFetch() {
        let username = "integTest\(UUID().uuidString)"
        let password = "P123@\(UUID().uuidString)"
        let signInExpectation = expectation(description: "SignIn operation should complete")
        AuthSignInHelper.registerAndSignInUser(username: username, password: password,
                                               email: defaultTestEmail) { didSucceed, error in
            signInExpectation.fulfill()
            XCTAssertTrue(didSucceed, "SignIn operation failed - \(String(describing: error))")
        }
        wait(for: [signInExpectation], timeout: networkTimeout)

        let firstAuthSessionExpectation = expectation(description: "Received event result from fetchAuth")
        _ = Amplify.Auth.fetchAuthSession { result in
            defer {
                firstAuthSessionExpectation.fulfill()
            }
            switch result {
            case .success(let session):
                XCTAssertTrue(session.isSignedIn, "Session state should be signed In")
            case .failure(let error):
                XCTFail("Should not receive error \(error)")
            }
        }
        
        let secondAuthSessionExpectation = expectation(description: "Received event result from fetchAuth")
        _ = Amplify.Auth.fetchAuthSession { result in
            defer {
                secondAuthSessionExpectation.fulfill()
            }
            switch result {
            case .success(let session):
                XCTAssertTrue(session.isSignedIn, "Session state should be signed In")
            case .failure(let error):
                XCTFail("Should not receive error \(error)")
            }
        }
        wait(for: [firstAuthSessionExpectation, secondAuthSessionExpectation], timeout: networkTimeout)
    }
}
