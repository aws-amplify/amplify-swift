//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
import AWSCognitoAuthPlugin

class AuthDeleteUserTests: AWSAuthBaseTest {

    override func setUp() {
        super.setUp()
        initializeAmplify()
        AuthSessionHelper.clearSession()
    }

    override func tearDown() async throws {
        try await super.tearDown()
        await Amplify.reset()
        sleep(2)
    }

    /// Test deleteUser in authenticated state
    ///
    /// - Given: An authenticated state
    /// - When:
    ///    - I invoke `deleteUser`
    /// - Then:
    ///    - I should get successful result, the user should no longer exist, and the auth session should be signedOut
    ///
    func testDeleteUserFromAuthState() {
        let username = "integTest\(UUID().uuidString)"
        let password = "P123@\(UUID().uuidString)"

        let registerAndSignInExpectation = expectation(description: "SignIn operation should complete")
        AuthSignInHelper.registerAndSignInUser(username: username,
                                               password: password,
                                               email: defaultTestEmail) { didSucceed, error in
            registerAndSignInExpectation.fulfill()
            XCTAssertTrue(didSucceed, "SignIn operation failed - \(String(describing: error))")
        }
        wait(for: [registerAndSignInExpectation], timeout: networkTimeout)

        // Check if the auth session is signed in
        let authSignedInSessionExpectation = expectation(description: "Operation should complete")
        _ = Amplify.Auth.fetchAuthSession { result in
            defer {
                authSignedInSessionExpectation.fulfill()
            }
            do {
                let session = try result.get()
                XCTAssertTrue(session.isSignedIn, "Auth session should be signedIn")
            } catch {
                XCTFail("Fetch auth session failed with error - \(error)")
            }
        }
        wait(for: [authSignedInSessionExpectation], timeout: networkTimeout)

        let operationExpectation = expectation(description: "Operation should complete")
        let operation = Amplify.Auth.deleteUser { result in
            defer {
                operationExpectation.fulfill()
            }
            switch result {
            case .success:
                print("Success deleteUser")
            case .failure(let error):
                XCTFail("deleteUser should not fail - \(error)")
            }
        }
        XCTAssertNotNil(operation, "deleteUser operation should not be nil")
        wait(for: [operationExpectation], timeout: networkTimeout)

        // Check if account was deleted
        let signInExpectation = expectation(description: "SignIn operation should complete")
        AuthSignInHelper.signInUser(username: username, password: password) { didSucceed, error in
            defer {
                signInExpectation.fulfill()
            }
            XCTAssertFalse(didSucceed, "signIn after account deletion should fail")
            guard case .service(_, _, let underlyingError) = error else {
                XCTFail("Should produce service error instead of \(String(describing: error))")
                return
            }
            guard case .userNotFound = (underlyingError as? AWSCognitoAuthError) else {
                XCTFail("Underlying error should be userNotFound instead of \(String(describing: error))")
                return
            }
        }
        wait(for: [signInExpectation], timeout: networkTimeout)

        // Check if the auth session is signed out
        let authSignedOutSessionExpectation = expectation(description: "Operation should complete")
        _ = Amplify.Auth.fetchAuthSession { result in
            defer {
                authSignedOutSessionExpectation.fulfill()
            }
            do {
                let session = try result.get()
                XCTAssertFalse(session.isSignedIn, "Auth session should NOT be signedIn")
            } catch {
                XCTFail("Fetch auth session failed with error - \(error)")
            }
        }
        wait(for: [authSignedOutSessionExpectation], timeout: networkTimeout)
    }

    /// Test if invoking deleteUser without unauthenticated state fails with expected error.
    ///
    /// - Given: An unauthenticated state
    /// - When:
    ///    - I invoke `deleteUser`
    /// - Then:
    ///    - I should get a `AuthError.signedOut` error.
    ///
    func testDeleteUserFromUnauthState() {
        let operationExpectation = expectation(description: "Operation should complete")
        let operation = Amplify.Auth.deleteUser { result in
            defer {
                operationExpectation.fulfill()
            }
            switch result {
            case .success:
                XCTFail("Should not get success")
            case .failure(let error):
                guard case .signedOut = error else {
                    XCTFail("Should produce signedOut error instead of \(error)")
                    return
                }
            }
        }
        XCTAssertNotNil(operation, "deleteUser operation should not be nil")
        wait(for: [operationExpectation], timeout: networkTimeout)
    }
}
