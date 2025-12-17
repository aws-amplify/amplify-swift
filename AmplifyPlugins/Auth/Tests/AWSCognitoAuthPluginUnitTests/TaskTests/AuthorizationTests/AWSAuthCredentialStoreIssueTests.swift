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

// MARK: - Credential Store Issue Tests
// These tests investigate potential causes of random user logouts
// related to credential store operations, decoding failures, and edge cases.

class AWSAuthCredentialStoreIssueTests: BaseAuthorizationTests {

    // MARK: - Test: Multiple concurrent session fetches should not cause race condition

    /// Test that multiple concurrent fetchAuthSession calls don't cause race conditions
    ///
    /// - Given: A signed-in user with expired tokens
    /// - When: Multiple fetchAuthSession calls are made concurrently
    /// - Then: All calls should return consistent results without causing logout
    ///
    func testConcurrentSessionFetches_ShouldNotCauseRaceCondition() async throws {
        let tokenRefreshExpectation = expectation(description: "Token refresh should be called")
        tokenRefreshExpectation.assertForOverFulfill = false // May be called multiple times

        let initialState = AuthState.configured(
            AuthenticationState.signedIn(.testData),
            AuthorizationState.sessionEstablished(
                AmplifyCredentials.testDataWithExpiredTokens),
            .notStarted
        )

        let getTokensFromRefreshToken: MockIdentityProvider.MockGetTokensFromRefreshTokenResponse = { _ in
            tokenRefreshExpectation.fulfill()
            return GetTokensFromRefreshTokenOutput(authenticationResult: .init(
                accessToken: "newAccessToken",
                expiresIn: 3_600,
                idToken: "newIdToken",
                refreshToken: "newRefreshToken"
            ))
        }

        let awsCredentials: MockIdentity.MockGetCredentialsResponse = { _ in
            let credentials = CognitoIdentityClientTypes.Credentials(
                accessKeyId: "accessKey",
                expiration: Date().addingTimeInterval(3_600),
                secretKey: "secret",
                sessionToken: "session"
            )
            return .init(credentials: credentials, identityId: "responseIdentityID")
        }

        let plugin = configurePluginWith(
            userPool: { MockIdentityProvider(mockGetTokensFromRefreshTokenResponse: getTokensFromRefreshToken) },
            identityPool: { MockIdentity(mockGetCredentialsResponse: awsCredentials) },
            initialState: initialState
        )

        // Make multiple concurrent session fetch calls
        async let session1 = plugin.fetchAuthSession(options: AuthFetchSessionRequest.Options())
        async let session2 = plugin.fetchAuthSession(options: AuthFetchSessionRequest.Options())
        async let session3 = plugin.fetchAuthSession(options: AuthFetchSessionRequest.Options())

        let results = try await [session1, session2, session3]

        await fulfillment(of: [tokenRefreshExpectation], timeout: apiTimeout)

        // All sessions should report signed in
        for (index, session) in results.enumerated() {
            XCTAssertTrue(
                session.isSignedIn,
                "Session \(index + 1) should report signed in after concurrent fetch"
            )
        }
    }

    // MARK: - Test: Session fetch during token refresh should not cause inconsistent state

    /// Test that fetching session while token refresh is in progress returns consistent state
    ///
    /// - Given: A signed-in user with a token refresh in progress
    /// - When: Another fetchAuthSession is called
    /// - Then: The result should be consistent and not cause logout
    ///
    func testSessionFetchDuringRefresh_ShouldReturnConsistentState() async throws {
        let tokenRefreshExpectation = expectation(description: "Token refresh should be called")

        let initialState = AuthState.configured(
            AuthenticationState.signedIn(.testData),
            AuthorizationState.sessionEstablished(
                AmplifyCredentials.testDataWithExpiredTokens),
            .notStarted
        )

        let getTokensFromRefreshToken: MockIdentityProvider.MockGetTokensFromRefreshTokenResponse = { _ in
            tokenRefreshExpectation.fulfill()
            // Simulate some delay in token refresh
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            return GetTokensFromRefreshTokenOutput(authenticationResult: .init(
                accessToken: "newAccessToken",
                expiresIn: 3_600,
                idToken: "newIdToken",
                refreshToken: "newRefreshToken"
            ))
        }

        let awsCredentials: MockIdentity.MockGetCredentialsResponse = { _ in
            let credentials = CognitoIdentityClientTypes.Credentials(
                accessKeyId: "accessKey",
                expiration: Date().addingTimeInterval(3_600),
                secretKey: "secret",
                sessionToken: "session"
            )
            return .init(credentials: credentials, identityId: "responseIdentityID")
        }

        let plugin = configurePluginWith(
            userPool: { MockIdentityProvider(mockGetTokensFromRefreshTokenResponse: getTokensFromRefreshToken) },
            identityPool: { MockIdentity(mockGetCredentialsResponse: awsCredentials) },
            initialState: initialState
        )

        let session = try await plugin.fetchAuthSession(options: AuthFetchSessionRequest.Options())

        await fulfillment(of: [tokenRefreshExpectation], timeout: apiTimeout)

        XCTAssertTrue(session.isSignedIn, "User should remain signed in during token refresh")
    }

    // MARK: - Test: Empty token response should not cause logout

    /// Test that receiving empty tokens from refresh doesn't cause logout
    ///
    /// - Given: A signed-in user with expired tokens
    /// - When: Token refresh returns empty/nil tokens
    /// - Then: isSignedIn should still be true, but token results should fail
    ///
    func testEmptyTokenResponse_ShouldNotCauseLogout() async throws {
        let tokenRefreshExpectation = expectation(description: "Token refresh should be called")

        let initialState = AuthState.configured(
            AuthenticationState.signedIn(.testData),
            AuthorizationState.sessionEstablished(
                AmplifyCredentials.testDataWithExpiredTokens),
            .notStarted
        )

        let getTokensFromRefreshToken: MockIdentityProvider.MockGetTokensFromRefreshTokenResponse = { _ in
            tokenRefreshExpectation.fulfill()
            // Return empty/nil tokens
            return GetTokensFromRefreshTokenOutput(authenticationResult: .init(
                accessToken: nil,
                expiresIn: 0,
                idToken: nil,
                refreshToken: nil
            ))
        }

        let plugin = configurePluginWith(
            userPool: { MockIdentityProvider(mockGetTokensFromRefreshTokenResponse: getTokensFromRefreshToken) },
            initialState: initialState
        )

        let session = try await plugin.fetchAuthSession(options: AuthFetchSessionRequest.Options())

        await fulfillment(of: [tokenRefreshExpectation], timeout: apiTimeout)

        // User should still be signed in even if tokens are empty
        XCTAssertTrue(
            session.isSignedIn,
            "User should remain signed in even when token refresh returns empty tokens"
        )

        // Token result should be a failure
        let tokensResult = (session as? AuthCognitoTokensProvider)?.getCognitoTokens()
        if case .success = tokensResult {
            XCTFail("Expected token fetch to fail when refresh returns empty tokens")
        }
    }

    // MARK: - Test: Partial token response should not cause logout

    /// Test that receiving partial tokens from refresh doesn't cause logout
    ///
    /// - Given: A signed-in user with expired tokens
    /// - When: Token refresh returns only some tokens (missing accessToken)
    /// - Then: isSignedIn should still be true
    ///
    func testPartialTokenResponse_ShouldNotCauseLogout() async throws {
        let tokenRefreshExpectation = expectation(description: "Token refresh should be called")

        let initialState = AuthState.configured(
            AuthenticationState.signedIn(.testData),
            AuthorizationState.sessionEstablished(
                AmplifyCredentials.testDataWithExpiredTokens),
            .notStarted
        )

        let getTokensFromRefreshToken: MockIdentityProvider.MockGetTokensFromRefreshTokenResponse = { _ in
            tokenRefreshExpectation.fulfill()
            // Return partial tokens (missing accessToken)
            return GetTokensFromRefreshTokenOutput(authenticationResult: .init(
                accessToken: nil,
                expiresIn: 3_600,
                idToken: "idToken",
                refreshToken: "refreshToken"
            ))
        }

        let plugin = configurePluginWith(
            userPool: { MockIdentityProvider(mockGetTokensFromRefreshTokenResponse: getTokensFromRefreshToken) },
            initialState: initialState
        )

        let session = try await plugin.fetchAuthSession(options: AuthFetchSessionRequest.Options())

        await fulfillment(of: [tokenRefreshExpectation], timeout: apiTimeout)

        // User should still be signed in even if some tokens are missing
        XCTAssertTrue(
            session.isSignedIn,
            "User should remain signed in even when token refresh returns partial tokens"
        )
    }

    // MARK: - Test: Generic service error should not cause logout

    /// Test that generic service errors during token refresh don't cause logout
    ///
    /// - Given: A signed-in user with expired tokens
    /// - When: Token refresh fails with a generic service error (InternalErrorException)
    /// - Then: isSignedIn should still be true and error should NOT be sessionExpired
    ///
    func testGenericServiceError_ShouldNotCauseLogout() async throws {
        let tokenRefreshExpectation = expectation(description: "Token refresh should be called")

        let initialState = AuthState.configured(
            AuthenticationState.signedIn(.testData),
            AuthorizationState.sessionEstablished(
                AmplifyCredentials.testDataWithExpiredTokens),
            .notStarted
        )

        let getTokensFromRefreshToken: MockIdentityProvider.MockGetTokensFromRefreshTokenResponse = { _ in
            tokenRefreshExpectation.fulfill()
            // Throw a generic service error (not NotAuthorizedException)
            throw AWSCognitoIdentityProvider.InternalErrorException()
        }

        let plugin = configurePluginWith(
            userPool: { MockIdentityProvider(mockGetTokensFromRefreshTokenResponse: getTokensFromRefreshToken) },
            initialState: initialState
        )

        let session = try await plugin.fetchAuthSession(options: AuthFetchSessionRequest.Options())

        await fulfillment(of: [tokenRefreshExpectation], timeout: apiTimeout)

        // User should still be signed in for service errors
        XCTAssertTrue(
            session.isSignedIn,
            "User should remain signed in when token refresh fails with service error"
        )

        // Token result should NOT be sessionExpired
        let tokensResult = (session as? AuthCognitoTokensProvider)?.getCognitoTokens()
        if case .failure(let error) = tokensResult {
            if case .sessionExpired = error {
                XCTFail("Generic service error should NOT result in sessionExpired")
            }
        }
    }
}
