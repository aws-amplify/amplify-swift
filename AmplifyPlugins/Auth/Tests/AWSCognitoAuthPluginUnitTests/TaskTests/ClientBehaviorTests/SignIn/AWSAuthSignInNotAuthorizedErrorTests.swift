//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSCognitoIdentityProvider
import XCTest
@testable import Amplify
@testable import AWSCognitoAuthPlugin

/// Tests for GitHub issue #4089: [Auth] Underlying Error is always nil
/// https://github.com/aws-amplify/amplify-swift/issues/4089
///
/// When a NotAuthorizedException occurs during sign-in, the underlying error
/// should be preserved so developers can distinguish between different failure
/// reasons (e.g., "Incorrect username or password" vs "Password attempts exceeded").
class AWSAuthSignInNotAuthorizedErrorTests: BasePluginTest {

    override var initialState: AuthState {
        AuthState.configured(.signedOut(.init(lastKnownUserName: nil)), .configured, .notStarted)
    }

    /// Test that NotAuthorizedException preserves the underlying error
    ///
    /// - Given: An auth plugin with mocked service that throws NotAuthorizedException
    ///
    /// - When:
    ///    - I invoke signIn with incorrect credentials
    /// - Then:
    ///    - I should get a .notAuthorized error with the underlying NotAuthorizedException preserved
    ///
    func testSignInNotAuthorizedErrorPreservesUnderlyingError() async {
        let expectedErrorMessage = "Incorrect username or password."

        mockIdentityProvider = MockIdentityProvider(mockInitiateAuthResponse: { _ in
            throw AWSCognitoIdentityProvider.NotAuthorizedException(
                message: expectedErrorMessage
            )
        })

        let options = AuthSignInRequest.Options()

        do {
            let result = try await plugin.signIn(username: "username", password: "wrongpassword", options: options)
            XCTFail("Should not receive a success response \(result)")
        } catch let error as AuthError {
            guard case .notAuthorized(let errorDescription, _, let underlyingError) = error else {
                XCTFail("Should receive notAuthorized error instead got \(error)")
                return
            }

            // Verify the error description contains the expected message
            XCTAssertEqual(errorDescription, expectedErrorMessage)

            // Verify the underlying error is NOT nil (this is the fix for issue #4089)
            XCTAssertNotNil(underlyingError, "Underlying error should not be nil - this is the fix for issue #4089")

            // Verify the underlying error is the original NotAuthorizedException
            XCTAssertTrue(
                underlyingError is AWSCognitoIdentityProvider.NotAuthorizedException,
                "Underlying error should be NotAuthorizedException"
            )
        } catch {
            XCTFail("Received unexpected error type: \(error)")
        }
    }

    /// Test that different NotAuthorizedException messages are preserved
    ///
    /// - Given: An auth plugin with mocked service that throws NotAuthorizedException
    ///          with "Password attempts exceeded" message
    ///
    /// - When:
    ///    - I invoke signIn
    /// - Then:
    ///    - I should get a .notAuthorized error with the specific message preserved
    ///
    func testSignInPasswordAttemptsExceededPreservesUnderlyingError() async {
        let expectedErrorMessage = "Password attempts exceeded"

        mockIdentityProvider = MockIdentityProvider(mockInitiateAuthResponse: { _ in
            throw AWSCognitoIdentityProvider.NotAuthorizedException(
                message: expectedErrorMessage
            )
        })

        let options = AuthSignInRequest.Options()

        do {
            let result = try await plugin.signIn(username: "username", password: "password", options: options)
            XCTFail("Should not receive a success response \(result)")
        } catch let error as AuthError {
            guard case .notAuthorized(let errorDescription, _, let underlyingError) = error else {
                XCTFail("Should receive notAuthorized error instead got \(error)")
                return
            }

            // Verify the error description contains the expected message
            XCTAssertEqual(errorDescription, expectedErrorMessage)

            // Verify the underlying error is preserved
            XCTAssertNotNil(underlyingError, "Underlying error should not be nil")

            // Verify we can cast and inspect the underlying error
            if let notAuthorizedException = underlyingError as? AWSCognitoIdentityProvider.NotAuthorizedException {
                // The message is stored in properties.message
                XCTAssertEqual(notAuthorizedException.properties.message, expectedErrorMessage)
            } else {
                XCTFail("Should be able to cast underlying error to NotAuthorizedException")
            }
        } catch {
            XCTFail("Received unexpected error type: \(error)")
        }
    }
}
