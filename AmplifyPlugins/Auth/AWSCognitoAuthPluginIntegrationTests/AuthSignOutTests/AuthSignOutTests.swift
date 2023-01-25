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

class AuthSignedOutTests: AWSAuthBaseTest {

    override func setUpWithError() throws {
        continueAfterFailure = false
        try initializeAmplify()
    }

    override func tearDownWithError() throws {
        Amplify.reset()
        sleep(2)
    }

    /// Test if invoking signOut without unauthenticate state does not fail
    ///
    /// - Given: An unauthenticated state
    /// - When:
    ///    - I invoke signOut
    /// - Then:
    ///    - I should get a successul result
    ///
    func testSignedOutWithUnAuthState() {
        let operationExpectation = expectation(description: "Operation should complete")
        let operation = Amplify.Auth.signOut { result in
            defer {
                operationExpectation.fulfill()
            }
            switch result {
            case .success:
                break
            case .failure(let error):
                XCTFail("SignOut should not fail - \(error)")
            }
        }
        XCTAssertNotNil(operation, "SignOut operation should not be nil")
        wait(for: [operationExpectation], timeout: networkTimeout)
    }

    /// Test signOut in authenticated state
    ///
    /// - Given: An authenticated state
    /// - When:
    ///    - I invoke signout
    /// - Then:
    ///    - I should get successul result and the auth session should be signedout
    ///
    func testSignedOutFromAuthState() {

        let username = "integTest\(UUID().uuidString)"
        let password = "P123@\(UUID().uuidString)"

        let signInExpectation = expectation(description: "SignIn operation should complete")
        AuthSignInHelper.registerAndSignInUser(username: username,
                                               password: password,
                                               email: email) { didSucceed, error in
            defer {
                signInExpectation.fulfill()
            }
            XCTAssertTrue(didSucceed, "SignIn operation failed - \(String(describing: error))")
        }
        wait(for: [signInExpectation], timeout: networkTimeout)

        // Check if the auth session is signed in
        let authSignedInSessionExpectation = expectation(description: "Operation should complete")
        _ = Amplify.Auth.fetchAuthSession { result in
            defer {
                authSignedInSessionExpectation.fulfill()
            }
            switch result {
            case .success(let session):
                XCTAssertTrue(session.isSignedIn, "Auth session should be signedin")
            case .failure(let error):
                XCTFail("Fetch auth session failed with error - \(error)")
            }
        }
        wait(for: [authSignedInSessionExpectation], timeout: networkTimeout)

        let operationExpectation = expectation(description: "Operation should complete")
        let operation = Amplify.Auth.signOut { result in
            defer {
                operationExpectation.fulfill()
            }
            switch result {
            case .success:
                break
            case .failure(let error):
                XCTFail("SignOut should not fail - \(error)")
            }
        }
        XCTAssertNotNil(operation, "SignOut operation should not be nil")
        wait(for: [operationExpectation], timeout: networkTimeout)

        // Check if the auth session is signed out
        let authSignedOutSessionExpectation = expectation(description: "Operation should complete")
        _ = Amplify.Auth.fetchAuthSession { result in
            defer {
                authSignedOutSessionExpectation.fulfill()
            }
            do {
                let session = try result.get()
                XCTAssertFalse(session.isSignedIn, "Auth session should be signedin")
            } catch {
                XCTFail("Fetch auth session failed with error - \(error)")
            }
        }
        wait(for: [authSignedOutSessionExpectation], timeout: networkTimeout)
    }

    /// Test signOut in authenticated session expired state
    ///
    /// - Given: An authenticated state with expired session
    /// - When:
    ///    - I invoke signout
    /// - Then:
    ///    - I should get successul result and the auth session should be signedout
    ///
    func testSignedOutFromSessionExpiredState() {

        let username = "integTest\(UUID().uuidString)"
        let password = "P123@\(UUID().uuidString)"

        let signInExpectation = expectation(description: "SignIn operation should complete")
        AuthSignInHelper.registerAndSignInUser(username: username,
                                               password: password,
                                               email: email) { didSucceed, error in
            defer {
                signInExpectation.fulfill()
            }
            XCTAssertTrue(didSucceed, "SignIn operation failed - \(String(describing: error))")
        }
        wait(for: [signInExpectation], timeout: networkTimeout)
        AuthSessionHelper.invalidateSession(username: username)

        // Check if the auth session is signed in
        let authSignedInSessionExpectation = expectation(description: "Operation should complete")
        _ = Amplify.Auth.fetchAuthSession { result in
            defer {
                authSignedInSessionExpectation.fulfill()
            }
            switch result {
            case .success(let session):
                XCTAssertTrue(session.isSignedIn, "Auth session should be signedin")
            case .failure(let error):
                XCTFail("Fetch auth session failed with error - \(error)")
            }
        }
        wait(for: [authSignedInSessionExpectation], timeout: networkTimeout)

        let operationExpectation = expectation(description: "Operation should complete")
        let operation = Amplify.Auth.signOut { result in
            defer {
                operationExpectation.fulfill()
            }
            switch result {
            case .success:
                break
            case .failure(let error):
                XCTFail("SignOut should not fail - \(error)")
            }
        }
        XCTAssertNotNil(operation, "SignOut operation should not be nil")
        wait(for: [operationExpectation], timeout: networkTimeout)

        // Check if the auth session is signed out
        let authSignedOutSessionExpectation = expectation(description: "Operation should complete")
        _ = Amplify.Auth.fetchAuthSession { result in
            defer {
                authSignedOutSessionExpectation.fulfill()
            }
            do {
                let session = try result.get()
                XCTAssertFalse(session.isSignedIn, "Auth session should be signedin")
            } catch {
                XCTFail("Fetch auth session failed with error - \(error)")
            }
        }
        wait(for: [authSignedOutSessionExpectation], timeout: networkTimeout)
    }
}
