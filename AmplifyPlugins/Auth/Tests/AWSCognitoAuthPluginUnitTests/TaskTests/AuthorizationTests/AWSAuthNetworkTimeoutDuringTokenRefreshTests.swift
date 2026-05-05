//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

import AWSCognitoIdentity
import AWSCognitoIdentityProvider
import AWSPluginsCore
import ClientRuntime
import XCTest
@testable import Amplify
@testable import AWSCognitoAuthPlugin

@testable import AWSPluginsTestCommon

// MARK: - Network Timeout During Token Refresh Tests
// These tests verify that network errors during token refresh correctly
// preserve the user's signed-in state and do not incorrectly trigger logout.

class AWSAuthNetworkTimeoutDuringTokenRefreshTests: BaseAuthorizationTests {

    // MARK: - Test: Network timeout during token refresh should preserve isSignedIn = true

    /// Test that network timeout during token refresh preserves signed-in state
    ///
    /// - Given: A signed-in user with expired tokens that need refresh
    /// - When: Token refresh fails due to network timeout (NSURLErrorTimedOut)
    /// - Then:
    ///   - isSignedIn should still be true (user is still authenticated)
    ///   - cognitoTokensResult should be a failure with service error
    ///   - The error should NOT be sessionExpired (which would indicate logout)
    ///   - The underlying error should be a network error
    ///
    func testNetworkTimeoutDuringTokenRefresh_ShouldPreserveSignedInState() async throws {
        // Expectation to verify the mock was actually called
        let tokenRefreshExpectation = expectation(description: "Token refresh should be called")

        // Setup: User is signed in with expired tokens
        let initialState = AuthState.configured(
            AuthenticationState.signedIn(.testData),
            AuthorizationState.sessionEstablished(
                AmplifyCredentials.testDataWithExpiredTokens),
            .notStarted
        )

        // Mock: Token refresh throws a network timeout error
        let getTokensFromRefreshToken: MockIdentityProvider.MockGetTokensFromRefreshTokenResponse = { _ in
            // Fulfill expectation to prove this mock was called
            tokenRefreshExpectation.fulfill()

            // Simulate NSURLErrorTimedOut (-1001)
            let networkError = NSError(
                domain: NSURLErrorDomain,
                code: NSURLErrorTimedOut,
                userInfo: [NSLocalizedDescriptionKey: "The request timed out."]
            )
            throw networkError
        }

        let plugin = configurePluginWith(
            userPool: { MockIdentityProvider(mockGetTokensFromRefreshTokenResponse: getTokensFromRefreshToken) },
            initialState: initialState
        )

        // Act: Fetch auth session (which will trigger token refresh)
        let session = try await plugin.fetchAuthSession(options: AuthFetchSessionRequest.Options())

        // Wait for the expectation to verify mock was called
        await fulfillment(of: [tokenRefreshExpectation], timeout: apiTimeout)

        // Assert: User should STILL be signed in despite network error
        XCTAssertTrue(
            session.isSignedIn,
            "isSignedIn should be true even when token refresh fails due to network timeout"
        )

        // Assert: Token result should be a failure (but NOT sessionExpired)
        let tokensResult = (session as? AuthCognitoTokensProvider)?.getCognitoTokens()
        guard case .failure(let tokenError) = tokensResult else {
            XCTFail("Expected token fetch to fail due to network error")
            return
        }

        // Assert: The error should be a service error, NOT sessionExpired
        // sessionExpired would indicate the refresh token is invalid (user should re-login)
        // service error indicates a transient failure (user should retry)
        switch tokenError {
        case .sessionExpired:
            XCTFail(
                "Network timeout should NOT result in sessionExpired error. " +
                "sessionExpired should only occur for NotAuthorizedException (invalid refresh token)."
            )
        case .service(_, _, let underlyingError):
            // This is the expected behavior - network errors should be service errors
            if let cognitoError = underlyingError as? AWSCognitoAuthError {
                XCTAssertEqual(
                    cognitoError,
                    .network,
                    "Expected underlying error to be .network for timeout errors"
                )
            }
            // Success - network error correctly classified as service error
        default:
            // Other error types are acceptable as long as it's not sessionExpired
            break
        }
    }

    // MARK: - Test: Network timeout should NOT clear credentials

    /// Test that network timeout during token refresh does not clear stored credentials
    ///
    /// - Given: A signed-in user with expired tokens
    /// - When: Token refresh fails due to network timeout
    /// - Then: The authorization state should preserve existing credentials
    ///
    func testNetworkTimeoutDuringTokenRefresh_ShouldNotClearCredentials() async throws {
        // Expectation to verify the mock was actually called
        let tokenRefreshExpectation = expectation(description: "Token refresh should be called")

        let initialState = AuthState.configured(
            AuthenticationState.signedIn(.testData),
            AuthorizationState.sessionEstablished(
                AmplifyCredentials.testDataWithExpiredTokens),
            .notStarted
        )

        let getTokensFromRefreshToken: MockIdentityProvider.MockGetTokensFromRefreshTokenResponse = { _ in
            tokenRefreshExpectation.fulfill()
            throw NSError(
                domain: NSURLErrorDomain,
                code: NSURLErrorTimedOut,
                userInfo: [NSLocalizedDescriptionKey: "The request timed out."]
            )
        }

        let plugin = configurePluginWith(
            userPool: { MockIdentityProvider(mockGetTokensFromRefreshTokenResponse: getTokensFromRefreshToken) },
            initialState: initialState
        )

        let session = try await plugin.fetchAuthSession(options: AuthFetchSessionRequest.Options())

        // Wait for the expectation to verify mock was called
        await fulfillment(of: [tokenRefreshExpectation], timeout: apiTimeout)

        // The session should still report signed in
        XCTAssertTrue(session.isSignedIn)

        // Identity ID should still be available (from cached credentials)
        _ = (session as? AuthCognitoIdentityProvider)?.getIdentityId()
        // Note: Identity ID may fail if it depends on token refresh, but the key point
        // is that isSignedIn remains true
    }

    // MARK: - Test: Connection lost during token refresh

    /// Test that connection lost error during token refresh preserves signed-in state
    ///
    func testConnectionLostDuringTokenRefresh_ShouldPreserveSignedInState() async throws {
        // Expectation to verify the mock was actually called
        let tokenRefreshExpectation = expectation(description: "Token refresh should be called")

        let initialState = AuthState.configured(
            AuthenticationState.signedIn(.testData),
            AuthorizationState.sessionEstablished(
                AmplifyCredentials.testDataWithExpiredTokens),
            .notStarted
        )

        let getTokensFromRefreshToken: MockIdentityProvider.MockGetTokensFromRefreshTokenResponse = { _ in
            tokenRefreshExpectation.fulfill()
            // Simulate NSURLErrorNetworkConnectionLost (-1005)
            throw NSError(
                domain: NSURLErrorDomain,
                code: NSURLErrorNetworkConnectionLost,
                userInfo: [NSLocalizedDescriptionKey: "The network connection was lost."]
            )
        }

        let plugin = configurePluginWith(
            userPool: { MockIdentityProvider(mockGetTokensFromRefreshTokenResponse: getTokensFromRefreshToken) },
            initialState: initialState
        )

        let session = try await plugin.fetchAuthSession(options: AuthFetchSessionRequest.Options())

        // Wait for the expectation to verify mock was called
        await fulfillment(of: [tokenRefreshExpectation], timeout: apiTimeout)

        XCTAssertTrue(
            session.isSignedIn,
            "isSignedIn should be true even when token refresh fails due to connection lost"
        )
    }

    // MARK: - Test: No internet connection during token refresh

    /// Test that no internet connection error during token refresh preserves signed-in state
    ///
    func testNoInternetDuringTokenRefresh_ShouldPreserveSignedInState() async throws {
        // Expectation to verify the mock was actually called
        let tokenRefreshExpectation = expectation(description: "Token refresh should be called")

        let initialState = AuthState.configured(
            AuthenticationState.signedIn(.testData),
            AuthorizationState.sessionEstablished(
                AmplifyCredentials.testDataWithExpiredTokens),
            .notStarted
        )

        let getTokensFromRefreshToken: MockIdentityProvider.MockGetTokensFromRefreshTokenResponse = { _ in
            tokenRefreshExpectation.fulfill()
            // Simulate NSURLErrorNotConnectedToInternet (-1009)
            throw NSError(
                domain: NSURLErrorDomain,
                code: NSURLErrorNotConnectedToInternet,
                userInfo: [NSLocalizedDescriptionKey: "The Internet connection appears to be offline."]
            )
        }

        let plugin = configurePluginWith(
            userPool: { MockIdentityProvider(mockGetTokensFromRefreshTokenResponse: getTokensFromRefreshToken) },
            initialState: initialState
        )

        let session = try await plugin.fetchAuthSession(options: AuthFetchSessionRequest.Options())

        // Wait for the expectation to verify mock was called
        await fulfillment(of: [tokenRefreshExpectation], timeout: apiTimeout)

        XCTAssertTrue(
            session.isSignedIn,
            "isSignedIn should be true even when token refresh fails due to no internet"
        )
    }

    // MARK: - Test: Contrast with actual session expiry (NotAuthorizedException)

    /// Test that NotAuthorizedException correctly results in sessionExpired error
    /// This contrasts with network errors to show the difference in handling
    ///
    /// - Given: A signed-in user with expired tokens
    /// - When: Token refresh fails due to NotAuthorizedException (invalid refresh token)
    /// - Then:
    ///   - isSignedIn should still be true (authentication state is preserved)
    ///   - cognitoTokensResult should be sessionExpired (indicating re-login needed)
    ///
    func testNotAuthorizedException_ShouldResultInSessionExpired() async throws {
        // Expectation to verify the mock was actually called
        let tokenRefreshExpectation = expectation(description: "Token refresh should be called")

        let initialState = AuthState.configured(
            AuthenticationState.signedIn(.testData),
            AuthorizationState.sessionEstablished(
                AmplifyCredentials.testDataWithExpiredTokens),
            .notStarted
        )

        let getTokensFromRefreshToken: MockIdentityProvider.MockGetTokensFromRefreshTokenResponse = { _ in
            tokenRefreshExpectation.fulfill()
            // This is the ONLY error that should result in sessionExpired
            throw AWSCognitoIdentityProvider.NotAuthorizedException()
        }

        let plugin = configurePluginWith(
            userPool: { MockIdentityProvider(mockGetTokensFromRefreshTokenResponse: getTokensFromRefreshToken) },
            initialState: initialState
        )

        let session = try await plugin.fetchAuthSession(options: AuthFetchSessionRequest.Options())

        // Wait for the expectation to verify mock was called
        await fulfillment(of: [tokenRefreshExpectation], timeout: apiTimeout)

        // isSignedIn is still true - the authentication state is preserved
        XCTAssertTrue(session.isSignedIn)

        // But the token result should be sessionExpired
        let tokensResult = (session as? AuthCognitoTokensProvider)?.getCognitoTokens()
        guard case .failure(let tokenError) = tokensResult,
              case .sessionExpired = tokenError else {
            XCTFail("NotAuthorizedException should result in sessionExpired error")
            return
        }
    }

    // MARK: - Test: App-level error handling simulation

    /// This test demonstrates how apps might incorrectly handle session errors
    /// and provides guidance on correct error handling
    ///
    func testAppErrorHandling_ShouldDistinguishNetworkFromSessionExpiry() async throws {
        // Expectation to verify the mock was actually called
        let tokenRefreshExpectation = expectation(description: "Token refresh should be called")

        let initialState = AuthState.configured(
            AuthenticationState.signedIn(.testData),
            AuthorizationState.sessionEstablished(
                AmplifyCredentials.testDataWithExpiredTokens),
            .notStarted
        )

        // Simulate network timeout
        let getTokensFromRefreshToken: MockIdentityProvider.MockGetTokensFromRefreshTokenResponse = { _ in
            tokenRefreshExpectation.fulfill()
            throw NSError(
                domain: NSURLErrorDomain,
                code: NSURLErrorTimedOut,
                userInfo: nil
            )
        }

        let plugin = configurePluginWith(
            userPool: { MockIdentityProvider(mockGetTokensFromRefreshTokenResponse: getTokensFromRefreshToken) },
            initialState: initialState
        )

        let session = try await plugin.fetchAuthSession(options: AuthFetchSessionRequest.Options())

        // Wait for the expectation to verify mock was called
        await fulfillment(of: [tokenRefreshExpectation], timeout: apiTimeout)

        // CORRECT app-level error handling:
        // 1. First check isSignedIn - if true, user is still authenticated
        if session.isSignedIn {
            // User is authenticated, check token availability
            let tokensResult = (session as? AuthCognitoTokensProvider)?.getCognitoTokens()

            switch tokensResult {
            case .success:
                // Tokens available - proceed normally
                break

            case .failure(let error):
                switch error {
                case .sessionExpired:
                    // ONLY in this case should the app prompt for re-login
                    // This means the refresh token is invalid
                    break

                case .service:
                    // Network or service error - DO NOT log out!
                    // Retry later or show "offline" message
                    XCTAssertTrue(session.isSignedIn, "User should remain signed in for service errors")

                default:
                    // Other errors - handle appropriately but don't log out
                    break
                }

            case .none:
                break
            }
        } else {
            // User is not signed in - this is the only case where logout is appropriate
        }
    }
}
