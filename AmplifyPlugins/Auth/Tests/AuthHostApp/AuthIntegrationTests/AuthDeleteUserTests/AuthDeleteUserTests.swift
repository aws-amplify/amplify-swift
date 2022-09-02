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
    func testDeleteUserFromAuthState() async throws {
        let username = "integTest\(UUID().uuidString)"
        let password = "P123@\(UUID().uuidString)"

        let didSucceed = try await AuthSignInHelper.registerAndSignInUser(username: username,
                                               password: password,
                                               email: defaultTestEmail)
        XCTAssertTrue(didSucceed, "SignIn operation failed")

        // Check if the auth session is signed in
        let session = try await Amplify.Auth.fetchAuthSession()
        XCTAssertTrue(session.isSignedIn, "Auth session should be signedIn")
        
        do {
            try await Amplify.Auth.deleteUser()
            print("Success deleteUser")
        } catch {
            XCTFail("deleteUser should not fail - \(error)")
        }

        // Check if account was deleted
        do {
            _ = try await AuthSignInHelper.signInUser(username: username, password: password)
            XCTFail("signIn after account deletion should fail")
        } catch {
            guard case AuthError.service(_, _, let underlyingError) = error else {
                XCTFail("Should produce service error instead of \(String(describing: error))")
                return
            }
            guard case .userNotFound = (underlyingError as? AWSCognitoAuthError) else {
                XCTFail("Underlying error should be userNotFound instead of \(String(describing: error))")
                return
            }
        }

        // Check if the auth session is signed out
        let anotherSession = try await Amplify.Auth.fetchAuthSession()
        XCTAssertFalse(anotherSession.isSignedIn, "Auth session should NOT be signedIn")
    }

    /// Test if invoking deleteUser without unauthenticated state fails with expected error.
    ///
    /// - Given: An unauthenticated state
    /// - When:
    ///    - I invoke `deleteUser`
    /// - Then:
    ///    - I should get a `AuthError.signedOut` error.
    ///
    func testDeleteUserFromUnauthState() async {
        do {
            try await Amplify.Auth.deleteUser()
            XCTFail("Should not get success")
            
        } catch {
            guard case AuthError.signedOut = error else {
                XCTFail("Should produce signedOut error instead of \(error)")
                return
            }
        }
    }
}
