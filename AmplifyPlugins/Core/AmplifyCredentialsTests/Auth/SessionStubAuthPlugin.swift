//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Security

@testable import Amplify
@testable import AmplifyTestCommon
import AWSPluginsCore

/// An Auth plugin whose `fetchAuthSession` returns a fixed session, installed as `Amplify.Auth`.
///
/// `@unchecked Sendable`: a test double driven from one test at a time.
final class SessionStubAuthPlugin: MockAuthCategoryPlugin, @unchecked Sendable {
    let session: AuthSession

    init(session: AuthSession) {
        self.session = session
        super.init()
    }

    override func fetchAuthSession(options: AuthFetchSessionRequest.Options? = nil) async throws -> AuthSession {
        session
    }

    /// Makes `session` what `Amplify.Auth.fetchAuthSession()` returns. Undo with `Amplify.reset()`.
    static func install(session: AuthSession) throws {
        let category = AuthCategory()
        try category.add(plugin: SessionStubAuthPlugin(session: session))
        category.isConfigured = true
        Amplify.Auth = category
    }
}

/// What a third-party Auth plugin might return when no one is signed in: a bare `AuthSession`.
struct StubSignedOutSession: AuthSession {
    let isSignedIn = false
}

/// A signed-in user pool session with no identity pool behind it.
struct StubUserPoolOnlySession: AuthSession, AuthCognitoTokensProvider {
    let isSignedIn = true

    func getCognitoTokens() -> Result<AuthCognitoTokens, AuthError> {
        .success(StubTokens())
    }
}

/// A session that conforms to every provider protocol and fails each with a locked keychain, shaped
/// the way `AWSCognitoAuthPlugin` reports it (`KeychainStoreError.securityError` → `AuthError.service`).
struct StubKeychainLockedSession: AuthSession, AuthAWSCredentialsProvider, AuthCognitoTokensProvider,
    AuthCognitoIdentityProvider {

    static let errorDescription = "The keychain could not be read"

    let isSignedIn = true

    private var error: AuthError {
        .service(
            Self.errorDescription,
            "Unlock the device and retry",
            KeychainStoreError.securityError(errSecInteractionNotAllowed)
        )
    }

    func getAWSCredentials() -> Result<AWSCredentials, AuthError> { .failure(error) }
    func getCognitoTokens() -> Result<AuthCognitoTokens, AuthError> { .failure(error) }
    func getIdentityId() -> Result<String, AuthError> { .failure(error) }
    func getUserSub() -> Result<String, AuthError> { .failure(error) }
}

struct StubTokens: AuthCognitoTokens {
    let idToken = "idToken"
    let accessToken = "accessToken"
    let refreshToken = "refreshToken"
}
