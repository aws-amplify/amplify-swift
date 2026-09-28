//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSCognitoIdentity
import AWSCognitoIdentityProvider
import AWSPluginsCore
import Foundation
import XCTest
@testable import Amplify
@testable import AWSCognitoAuthPlugin
@testable import InternalAWSCognitoAuth

// swiftlint:disable file_length
// swiftlint:disable type_body_length
// `@unchecked Sendable`: `XCTestCase` is not `Sendable`, but the test body is captured by the
// `@Sendable` closures the API now takes. XCTest runs one test at a time.
/// With refresh-token rotation, `GetTokensFromRefreshToken` returns a new refresh token and revokes the
/// old one. When the identity-pool step after it fails, the new user-pool tokens must still be stored
/// and used by the next refresh, as they are when the refresh succeeds. The error returned to the
/// caller is the same as before.
class AWSAuthFetchSessionTokenRotationTests: XCTestCase, @unchecked Sendable {

    private let rotatedRefreshTokens = ["rotatedRefreshToken-1", "rotatedRefreshToken-2"]

    /// The refreshed user-pool tokens are kept when fetching AWS credentials for the known identity fails
    ///
    /// - Given: A signed-in user with expired user-pool tokens, an identity ID and AWS credentials
    /// - When:
    ///    - fetchAuthSession refreshes the user-pool tokens, which returns a rotated refresh token
    ///    - GetCredentialsForIdentity then fails
    /// - Then:
    ///    - The session reports the identity-pool error, as before
    ///    - The rotated tokens are stored, with the existing identity ID and AWS credentials
    ///    - The next refresh sends the rotated refresh token, not the revoked one
    ///
    func testRotatedTokensArePersistedWhenAWSCredentialsFetchFails() async throws {
        let existing = AmplifyCredentials.testDataWithExpiredTokens
        let harness = makeHarness(
            existing: existing,
            identity: MockIdentity(mockGetCredentialsResponse: { _ in
                throw AWSCognitoIdentity.InternalErrorException(message: "identity pool is down")
            })
        )

        let session = try await harness.plugin.fetchAuthSession(options: AuthFetchSessionRequest.Options())

        assertIdentityPoolServiceError(session)
        let stored = try XCTUnwrap(harness.store.lastStoredCredentials, "The refreshed tokens were not stored")
        guard case .userPoolAndIdentityPool(let signedInData, let identityID, let awsCredentials) = stored,
              case .userPoolAndIdentityPool(_, let existingIdentityID, let existingAWSCredentials) = existing
        else {
            XCTFail("Stored \(stored), expected user pool and identity pool credentials")
            return
        }
        XCTAssertEqual(signedInData.cognitoUserPoolTokens.refreshToken, rotatedRefreshTokens[0])
        XCTAssertEqual(signedInData.cognitoUserPoolTokens.accessToken, harness.issuedAccessTokens.values.first)
        XCTAssertEqual(identityID, existingIdentityID)
        XCTAssertEqual(awsCredentials, existingAWSCredentials)

        _ = try await harness.plugin.fetchAuthSession(options: .forceRefresh())

        XCTAssertEqual(harness.refreshTokensSent.values, [
            SignedInData.expiredTestData.cognitoUserPoolTokens.refreshToken,
            rotatedRefreshTokens[0]
        ])
    }

    /// The refreshed user-pool tokens are kept when fetching the identity ID fails
    ///
    /// - Given: A signed-in user with expired user-pool tokens and no identity-pool credentials yet
    /// - When:
    ///    - fetchAuthSession refreshes the user-pool tokens, which returns a rotated refresh token
    ///    - GetId then fails
    /// - Then:
    ///    - The session reports the identity-pool error, as before
    ///    - The rotated tokens are stored as user-pool-only credentials
    ///    - The next refresh sends the rotated refresh token, not the revoked one
    ///
    func testRotatedTokensArePersistedWhenIdentityIdFetchFails() async throws {
        let harness = makeHarness(
            existing: .userPoolOnly(signedInData: .expiredTestData),
            identity: MockIdentity(mockGetIdResponse: { _ in
                throw AWSCognitoIdentity.InternalErrorException(message: "identity pool is down")
            })
        )

        let session = try await harness.plugin.fetchAuthSession(options: AuthFetchSessionRequest.Options())

        assertIdentityPoolServiceError(session)
        let stored = try XCTUnwrap(harness.store.lastStoredCredentials, "The refreshed tokens were not stored")
        guard case .userPoolOnly(let signedInData) = stored else {
            XCTFail("Stored \(stored), expected user-pool-only credentials")
            return
        }
        XCTAssertEqual(signedInData.cognitoUserPoolTokens.refreshToken, rotatedRefreshTokens[0])

        _ = try await harness.plugin.fetchAuthSession(options: .forceRefresh())

        XCTAssertEqual(harness.refreshTokensSent.values, [
            SignedInData.expiredTestData.cognitoUserPoolTokens.refreshToken,
            rotatedRefreshTokens[0]
        ])
    }

    /// A later fetch retries the identity pool after the refreshed tokens were kept
    ///
    /// - Given: A signed-in user with expired user-pool tokens and no identity-pool credentials yet
    /// - When:
    ///    - fetchAuthSession refreshes the user-pool tokens and GetId fails
    ///    - fetchAuthSession is called again, without force refresh
    /// - Then:
    ///    - The second call retries GetId instead of returning the stored tokens with no AWS credentials
    ///    - It refreshes with the rotated refresh token
    ///
    func testNextFetchRetriesTheIdentityPoolAfterIdentityIdFetchFails() async throws {
        let getIdCalls = RecordedValues()
        let harness = makeHarness(
            existing: .userPoolOnly(signedInData: .expiredTestData),
            identity: MockIdentity(mockGetIdResponse: { _ in
                _ = getIdCalls.append("GetId")
                throw AWSCognitoIdentity.InternalErrorException(message: "identity pool is down")
            })
        )

        _ = try await harness.plugin.fetchAuthSession(options: AuthFetchSessionRequest.Options())
        let session = try await harness.plugin.fetchAuthSession(options: AuthFetchSessionRequest.Options())

        XCTAssertEqual(getIdCalls.values.count, 2, "The second fetch did not retry the identity pool")
        assertIdentityPoolServiceError(session)
        XCTAssertEqual(harness.refreshTokensSent.values, [
            SignedInData.expiredTestData.cognitoUserPoolTokens.refreshToken,
            rotatedRefreshTokens[0]
        ])
    }

    /// The refreshed user-pool tokens are kept when the identity step fails with an authorization error
    ///
    /// - Given: A signed-in user with expired user-pool tokens, and an identity client that cannot be built
    /// - When:
    ///    - fetchAuthSession refreshes the user-pool tokens, which returns a rotated refresh token
    ///    - Fetching the identity ID then fails with `AuthorizationError.configuration`, sent directly
    /// - Then:
    ///    - The session reports the configuration error, as before
    ///    - The rotated tokens are stored as user-pool-only credentials
    ///
    func testRotatedTokensArePersistedWhenIdentityStepThrowsAuthorizationError() async throws {
        let harness = makeHarness(
            existing: .userPoolOnly(signedInData: .expiredTestData),
            identity: MockIdentity(),
            identityClientFails: true
        )

        let session = try await harness.plugin.fetchAuthSession(options: AuthFetchSessionRequest.Options())

        XCTAssertTrue(session.isSignedIn)
        let results: [(String, AuthError?)] = [
            ("tokens", (session as? AuthCognitoTokensProvider)?.getCognitoTokens().failure),
            ("identity ID", (session as? AuthCognitoIdentityProvider)?.getIdentityId().failure),
            ("AWS credentials", (session as? AuthAWSCredentialsProvider)?.getAWSCredentials().failure)
        ]
        for (name, error) in results {
            guard case .configuration(let description, _, _) = error else {
                XCTFail("\(name): expected a configuration error, got \(String(describing: error))")
                continue
            }
            XCTAssertEqual(
                description,
                AuthPluginErrorConstants.signedInIdentityIdWithNoCIDPError.errorDescription,
                name
            )
        }
        let stored = try XCTUnwrap(harness.store.lastStoredCredentials, "The refreshed tokens were not stored")
        guard case .userPoolOnly(let signedInData) = stored else {
            XCTFail("Stored \(stored), expected user-pool-only credentials")
            return
        }
        XCTAssertEqual(signedInData.cognitoUserPoolTokens.refreshToken, rotatedRefreshTokens[0])
    }

    /// The refreshed user-pool tokens are kept when GetId succeeds and fetching AWS credentials fails
    ///
    /// - Given: A signed-in user with expired user-pool tokens and no identity-pool credentials yet
    /// - When:
    ///    - fetchAuthSession refreshes the user-pool tokens, which returns a rotated refresh token
    ///    - GetId succeeds and GetCredentialsForIdentity then fails
    /// - Then:
    ///    - The session reports the identity-pool error, as before
    ///    - The rotated tokens are stored as user-pool-only credentials
    ///
    func testRotatedTokensArePersistedWhenAWSCredentialsFetchFailsAfterGetId() async throws {
        let harness = makeHarness(
            existing: .userPoolOnly(signedInData: .expiredTestData),
            identity: MockIdentity(
                mockGetIdResponse: { _ in GetIdOutput(identityId: "newIdentityId") },
                mockGetCredentialsResponse: { _ in
                    throw AWSCognitoIdentity.InternalErrorException(message: "identity pool is down")
                }
            )
        )

        let session = try await harness.plugin.fetchAuthSession(options: AuthFetchSessionRequest.Options())

        assertIdentityPoolServiceError(session)
        let stored = try XCTUnwrap(harness.store.lastStoredCredentials, "The refreshed tokens were not stored")
        guard case .userPoolOnly(let signedInData) = stored else {
            XCTFail("Stored \(stored), expected user-pool-only credentials")
            return
        }
        XCTAssertEqual(signedInData.cognitoUserPoolTokens.refreshToken, rotatedRefreshTokens[0])
    }

    /// With rotation off, the refreshed access and ID tokens are kept with the existing refresh token
    ///
    /// - Given: A signed-in user with expired user-pool tokens, an identity ID and AWS credentials
    /// - When:
    ///    - fetchAuthSession refreshes the user-pool tokens, and the response has no refresh token
    ///    - GetCredentialsForIdentity then fails
    /// - Then:
    ///    - The new access token is stored with the existing refresh token
    ///    - The next refresh sends the existing refresh token again
    ///
    func testRefreshedTokensArePersistedWithoutRotation() async throws {
        let harness = makeHarness(
            existing: .testDataWithExpiredTokens,
            identity: MockIdentity(mockGetCredentialsResponse: { _ in
                throw AWSCognitoIdentity.InternalErrorException(message: "identity pool is down")
            }),
            userPoolRefresh: .noRotation
        )
        let existingRefreshToken = SignedInData.expiredTestData.cognitoUserPoolTokens.refreshToken

        let session = try await harness.plugin.fetchAuthSession(options: AuthFetchSessionRequest.Options())

        assertIdentityPoolServiceError(session)
        let stored = try XCTUnwrap(harness.store.lastStoredCredentials, "The refreshed tokens were not stored")
        guard case .userPoolAndIdentityPool(let signedInData, _, _) = stored else {
            XCTFail("Stored \(stored), expected user pool and identity pool credentials")
            return
        }
        XCTAssertEqual(signedInData.cognitoUserPoolTokens.refreshToken, existingRefreshToken)
        XCTAssertEqual(signedInData.cognitoUserPoolTokens.accessToken, harness.issuedAccessTokens.values.first)

        _ = try await harness.plugin.fetchAuthSession(options: .forceRefresh())

        XCTAssertEqual(harness.refreshTokensSent.values, [existingRefreshToken, existingRefreshToken])
    }

    /// Nothing is stored when the user-pool refresh itself fails
    ///
    /// - Given: A signed-in user with expired user-pool tokens, an identity ID and AWS credentials
    /// - When:
    ///    - GetTokensFromRefreshToken fails with NotAuthorizedException, or with RefreshTokenReuseException
    /// - Then:
    ///    - One refresh was attempted, with the existing refresh token
    ///    - No credentials were stored
    ///
    func testNothingIsStoredWhenTheUserPoolRefreshFails() async throws {
        let failures: [(String, any Error & Sendable)] = [
            ("NotAuthorizedException", AWSCognitoIdentityProvider.NotAuthorizedException(message: "revoked")),
            ("RefreshTokenReuseException", AWSCognitoIdentityProvider.RefreshTokenReuseException(message: "reused"))
        ]
        for (name, failure) in failures {
            let harness = makeHarness(
                existing: .testDataWithExpiredTokens,
                identity: MockIdentity(),
                userPoolRefresh: .fail(failure)
            )

            let session = try await harness.plugin.fetchAuthSession(options: AuthFetchSessionRequest.Options())

            XCTAssertTrue(session.isSignedIn, name)
            XCTAssertNotNil((session as? AuthCognitoTokensProvider)?.getCognitoTokens().failure, name)
            XCTAssertEqual(
                harness.refreshTokensSent.values,
                [SignedInData.expiredTestData.cognitoUserPoolTokens.refreshToken],
                name
            )
            XCTAssertNil(harness.store.lastStoredCredentials, name)
        }
    }

    /// Nothing is stored when the user-pool tokens were not refreshed
    ///
    /// - Given: A signed-in user with valid user-pool tokens and expired AWS credentials
    /// - When:
    ///    - fetchAuthSession fetches AWS credentials without refreshing the user-pool tokens, and that fails
    /// - Then:
    ///    - The session reports the identity-pool error, as before
    ///    - No user-pool refresh was made, and no credentials were stored
    ///
    func testNothingIsStoredWhenOnlyTheAWSCredentialsFetchFails() async throws {
        let claims = [
            "sub": "1234567890",
            "username": "John Doe",
            "iat": "1516239022",
            "exp": String(Date(timeIntervalSinceNow: 3_600).timeIntervalSince1970)
        ]
        let validTokens = EngineUserPoolTokens(
            idToken: CognitoAuthTestHelper.buildToken(for: claims),
            accessToken: CognitoAuthTestHelper.buildToken(for: claims),
            refreshToken: "refreshToken"
        )
        let signedInData = SignedInData(
            signedInDate: Date(),
            signInMethod: .apiBased(.userSRP),
            cognitoUserPoolTokens: validTokens
        )
        let harness = makeHarness(
            existing: .userPoolAndIdentityPool(
                signedInData: signedInData,
                identityID: "identityId",
                credentials: .expiredTestData
            ),
            identity: MockIdentity(mockGetCredentialsResponse: { _ in
                throw AWSCognitoIdentity.InternalErrorException(message: "identity pool is down")
            })
        )

        let session = try await harness.plugin.fetchAuthSession(options: AuthFetchSessionRequest.Options())

        assertIdentityPoolServiceError(session)
        XCTAssertEqual(harness.refreshTokensSent.values, [])
        XCTAssertNil(harness.store.lastStoredCredentials)
    }

    // MARK: - Helpers

    private struct Harness {
        let plugin: AWSCognitoAuthPlugin
        let store: RecordingCredentialStore
        let refreshTokensSent: RecordedValues
        /// The access tokens GetTokensFromRefreshToken returned, in order.
        let issuedAccessTokens: RecordedValues
    }

    /// What the mock `GetTokensFromRefreshToken` does.
    private enum UserPoolRefresh {
        /// Returns new tokens and the next of `rotatedRefreshTokens`.
        case rotate
        /// Returns new tokens and no refresh token, as with rotation off.
        case noRotation
        case fail(any Error & Sendable)
    }

    /// A JWT that is valid for an hour and unique to `number`.
    private static func issuedToken(_ number: Int) -> String {
        CognitoAuthTestHelper.buildToken(for: [
            "sub": "1234567890",
            "username": "John Doe",
            "iat": "1516239022",
            "tokenNumber": String(number),
            "exp": String(Date(timeIntervalSinceNow: 3_600).timeIntervalSince1970)
        ])
    }

    private func makeHarness(
        existing: AmplifyCredentials,
        identity: MockIdentity,
        userPoolRefresh: UserPoolRefresh = .rotate,
        identityClientFails: Bool = false
    ) -> Harness {
        let refreshTokensSent = RecordedValues()
        let issuedAccessTokens = RecordedValues()
        let rotatedRefreshTokens = rotatedRefreshTokens
        let userPool = MockIdentityProvider(mockGetTokensFromRefreshTokenResponse: { input in
            let index = refreshTokensSent.append(input.refreshToken ?? "")
            let refreshToken: String?
            switch userPoolRefresh {
            case .rotate:
                refreshToken = rotatedRefreshTokens[min(index, rotatedRefreshTokens.count - 1)]
            case .noRotation:
                refreshToken = nil
            case .fail(let error):
                throw error
            }
            let accessToken = Self.issuedToken(index + 1)
            _ = issuedAccessTokens.append(accessToken)
            return GetTokensFromRefreshTokenOutput(authenticationResult: .init(
                accessToken: accessToken,
                expiresIn: 3_600,
                idToken: Self.issuedToken(index + 1),
                refreshToken: refreshToken
            ))
        })
        let store = RecordingCredentialStore()
        let baseEnvironment = Defaults.makeDefaultAuthEnvironment(
            identityPoolFactory: {
                if identityClientFails {
                    throw AuthError.configuration("No identity client", "")
                }
                return identity
            },
            userPoolFactory: { userPool }
        )
        let environment = AuthEnvironment(
            configuration: baseEnvironment.configuration,
            userPoolConfigData: baseEnvironment.userPoolConfigData,
            identityPoolConfigData: baseEnvironment.identityPoolConfigData,
            authenticationEnvironment: baseEnvironment.authenticationEnvironment,
            authorizationEnvironment: baseEnvironment.authorizationEnvironment,
            credentialsClient: store,
            logger: baseEnvironment.logger
        )
        let initialState = AuthState.configured(
            .signedIn(.testData),
            .sessionEstablished(existing),
            .notStarted
        )
        let stateMachine = AuthStateMachine(
            resolver: AuthState.Resolver(),
            environment: environment,
            initialState: initialState
        )
        let plugin = AWSCognitoAuthPlugin()
        plugin.configure(
            authConfiguration: Defaults.makeDefaultAuthConfigData(),
            authEnvironment: environment,
            authStateMachine: stateMachine,
            credentialStoreStateMachine: Defaults.makeDefaultCredentialStateMachine(),
            hubEventHandler: MockAuthHubEventBehavior(),
            analyticsHandler: MockAnalyticsHandler()
        )
        settleConfigureOperationOnTeardown(of: plugin)
        return Harness(
            plugin: plugin,
            store: store,
            refreshTokensSent: refreshTokensSent,
            issuedAccessTokens: issuedAccessTokens
        )
    }

    /// The result the plugin has always returned for an identity-pool service error after sign-in: every
    /// result fails with `AuthError.unknown`, carrying the service error's message and no underlying error.
    private func assertIdentityPoolServiceError(
        _ session: AuthSession,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertTrue(session.isSignedIn, file: file, line: line)
        let results: [(String, AuthError?)] = [
            ("tokens", (session as? AuthCognitoTokensProvider)?.getCognitoTokens().failure),
            ("identity ID", (session as? AuthCognitoIdentityProvider)?.getIdentityId().failure),
            ("AWS credentials", (session as? AuthAWSCredentialsProvider)?.getAWSCredentials().failure)
        ]
        for (name, error) in results {
            guard case .unknown(let description, let underlying) = error else {
                XCTFail("\(name): expected an unknown error, got \(String(describing: error))", file: file, line: line)
                continue
            }
            XCTAssertTrue(description.contains("identity pool is down"), "\(name): \(description)", file: file, line: line)
            XCTAssertNil(underlying, "\(name): underlying error", file: file, line: line)
        }
    }
}

private extension Result {
    var failure: Failure? {
        if case .failure(let error) = self { return error }
        return nil
    }
}

private final class RecordedValues: @unchecked Sendable {
    private let lock = NSLock()
    private var recorded: [String] = []

    var values: [String] {
        lock.withLock { recorded }
    }

    /// Appends `value` and returns its index.
    func append(_ value: String) -> Int {
        lock.withLock {
            recorded.append(value)
            return recorded.count - 1
        }
    }
}

/// A credential store that keeps what it is given and records the last credentials stored.
private final class RecordingCredentialStore: CredentialStoreStateBehavior, @unchecked Sendable {
    private let lock = NSLock()
    private var stored: AmplifyCredentials?

    var lastStoredCredentials: AmplifyCredentials? {
        lock.withLock { stored }
    }

    func fetchData(type: CredentialStoreDataType) async throws -> CredentialStoreData {
        switch type {
        case .amplifyCredentials:
            guard let stored = lastStoredCredentials else { throw EngineCredentialStoreError.itemNotFound }
            return .amplifyCredentials(stored)
        case .deviceMetadata(let username):
            return .deviceMetadata(.noData, username)
        case .asfDeviceId(let username):
            return .asfDeviceId("", username)
        }
    }

    func storeData(data: CredentialStoreData) async throws {
        if case .amplifyCredentials(let credentials) = data {
            lock.withLock { stored = credentials }
        }
    }

    func deleteData(type: CredentialStoreDataType) async throws { }
}
