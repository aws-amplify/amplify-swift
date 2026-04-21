//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

import XCTest
@testable import Amplify
@testable import AWSCognitoAuthPlugin
import AWSCognitoIdentity
import AWSPluginsCore

class AWSAuthFetchSessionCacheTests: BaseAuthorizationTests {

    /// Given: A signed-in auth plugin with valid tokens
    /// When: fetchAuthSession is called twice without forceRefresh
    /// Then: The second call should return a cached session
    func testFetchAuthSession_validCachedTokens_returnsCachedSession() async throws {
        let initialState = AuthState.configured(
            AuthenticationState.signedIn(.testData),
            AuthorizationState.sessionEstablished(
                AmplifyCredentials.testData),
            .notStarted)

        let plugin = configurePluginWith(initialState: initialState)

        // First call populates the cache
        let session1 = try await plugin.fetchAuthSession(options: AuthFetchSessionRequest.Options())
        XCTAssertTrue(session1.isSignedIn)
        XCTAssertNotNil(plugin.cachedSession)

        // Second call should use the cache
        let session2 = try await plugin.fetchAuthSession(options: AuthFetchSessionRequest.Options())
        XCTAssertTrue(session2.isSignedIn)

        // Both sessions should be equivalent
        let tokens1 = try? (session1 as? AuthCognitoTokensProvider)?.getCognitoTokens().get()
        let tokens2 = try? (session2 as? AuthCognitoTokensProvider)?.getCognitoTokens().get()
        XCTAssertNotNil(tokens1)
        XCTAssertNotNil(tokens2)
        XCTAssertEqual(tokens1?.accessToken, tokens2?.accessToken)
    }

    /// Given: A signed-in auth plugin with a cached session
    /// When: fetchAuthSession is called with forceRefresh = true
    /// Then: The cache should be bypassed and a new session fetched
    func testFetchAuthSession_forceRefresh_bypassesCache() async throws {
        let initialState = AuthState.configured(
            AuthenticationState.signedIn(.testData),
            AuthorizationState.sessionEstablished(
                AmplifyCredentials.testData),
            .notStarted)

        let plugin = configurePluginWith(initialState: initialState)

        // Populate cache
        _ = try await plugin.fetchAuthSession(options: AuthFetchSessionRequest.Options())
        XCTAssertNotNil(plugin.cachedSession)

        // Force refresh should bypass cache
        let options = AuthFetchSessionRequest.Options(forceRefresh: true)
        let session = try await plugin.fetchAuthSession(options: options)
        XCTAssertTrue(session.isSignedIn)
    }

    /// Given: A signed-in auth plugin with a cached session
    /// When: signOut is called
    /// Then: The cached session should be cleared
    func testSignOut_clearsCachedSession() async throws {
        let initialState = AuthState.configured(
            AuthenticationState.signedIn(.testData),
            AuthorizationState.sessionEstablished(
                AmplifyCredentials.testData),
            .notStarted)

        let plugin = configurePluginWith(initialState: initialState)

        // Populate cache
        _ = try await plugin.fetchAuthSession(options: AuthFetchSessionRequest.Options())
        XCTAssertNotNil(plugin.cachedSession)

        // Sign out should clear cache
        _ = await plugin.signOut()
        XCTAssertNil(plugin.cachedSession)
    }

    /// Given: A newly configured auth plugin with no cached session
    /// When: cachedSession is accessed
    /// Then: It should be nil
    func testCachedSession_initialState_isNil() {
        let initialState = AuthState.configured(
            AuthenticationState.signedIn(.testData),
            AuthorizationState.sessionEstablished(
                AmplifyCredentials.testData),
            .notStarted)

        let plugin = configurePluginWith(initialState: initialState)
        XCTAssertNil(plugin.cachedSession)
    }
}
