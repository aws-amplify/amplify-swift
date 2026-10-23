//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPluginsCore
import Smithy
import SmithyIdentity
import XCTest
@testable import AWSPredictionsPlugin

/// `AWSTranscribeStreamingAdapter` keeps the reason a session has no credentials.
///
/// `@unchecked Sendable`: `XCTestCase` is not `Sendable`, but the test body is captured by the
/// `@Sendable` closures the API now takes. XCTest runs one test at a time.
class TranscribeCredentialsTests: XCTestCase, @unchecked Sendable {

    private let input = AWSTranscribeStreamingAdapter.StartStreamInput(
        audioStream: Data(),
        languageCode: .enUs,
        mediaEncoding: .pcm,
        mediaSampleRateHertz: 8_000
    )

    /// A signed-out session is still `PredictionsError.client`, now carrying `AuthError.invalidState`.
    ///
    /// - Given: An adapter whose Auth session is signed out and cannot vend credentials
    /// - When:
    ///    - A transcription stream is started
    /// - Then:
    ///    - It throws the same `PredictionsError.client` as before
    ///    - Its underlying error is `AuthError.invalidState` rather than `nil`
    ///
    func testStartStream_signedOutSession_throwsClientErrorCarryingInvalidState() async {
        let error = await startStreamError(session: SignedOutSession())

        guard case .client(let clientError) = error as? PredictionsError else {
            return XCTFail("Expected PredictionsError.client, got \(String(describing: error))")
        }
        XCTAssertEqual(clientError.description, "Error retrieving credentials")
        XCTAssertEqual(clientError.recoverySuggestion, "Ensure that the Auth plugin is properly configured")
        guard case .invalidState = clientError.underlyingError as? AuthError else {
            return XCTFail("Expected AuthError.invalidState, got \(String(describing: clientError.underlyingError))")
        }
    }

    /// A user-pool-only session carries a no-identity-pool `AuthError.configuration`.
    ///
    /// - Given: An adapter whose Auth session has user pool tokens but no credentials
    /// - When:
    ///    - A transcription stream is started
    /// - Then:
    ///    - It throws `PredictionsError.client` whose underlying error is `AuthError.configuration`
    ///
    func testStartStream_userPoolOnlySession_throwsClientErrorCarryingConfiguration() async {
        let error = await startStreamError(session: UserPoolOnlySession())

        guard case .client(let clientError) = error as? PredictionsError else {
            return XCTFail("Expected PredictionsError.client, got \(String(describing: error))")
        }
        guard case .configuration(let description, _, _) = clientError.underlyingError as? AuthError else {
            return XCTFail("Expected AuthError.configuration, got \(String(describing: clientError.underlyingError))")
        }
        XCTAssertTrue(description.contains("no identity pool"), description)
    }

    /// A conforming session's own error is rethrown unchanged.
    ///
    /// - Given: An adapter whose Auth session conforms but reports expired credentials
    /// - When:
    ///    - A transcription stream is started
    /// - Then:
    ///    - It throws the session's `AuthError.sessionExpired` directly, as before
    ///
    func testStartStream_expiredSession_rethrowsSessionError() async {
        let error = await startStreamError(session: ExpiredSession())

        guard case .sessionExpired = error as? AuthError else {
            return XCTFail("Expected AuthError.sessionExpired, got \(String(describing: error))")
        }
    }

    private func startStreamError(session: AuthSession) async -> Error? {
        let adapter = AWSTranscribeStreamingAdapter(
            credentialIdentityResolver: UnusedCredentialIdentityResolver(),
            region: "us-east-1",
            fetchAuthSession: { session }
        )
        do {
            _ = try await adapter.startStreamTranscription(input: input)
            XCTFail("Expected starting the stream to fail")
            return nil
        } catch {
            return error
        }
    }
}

private struct SignedOutSession: AuthSession {
    let isSignedIn = false
}

private struct UserPoolOnlySession: AuthSession, AuthCognitoTokensProvider {
    let isSignedIn = true

    func getCognitoTokens() -> Result<AuthCognitoTokens, AuthError> {
        .success(Tokens())
    }

    private struct Tokens: AuthCognitoTokens {
        let idToken = "idToken"
        let accessToken = "accessToken"
        let refreshToken = "refreshToken"
    }
}

private struct ExpiredSession: AuthSession, AuthAWSCredentialsProvider {
    let isSignedIn = true

    func getAWSCredentials() -> Result<AWSCredentials, AuthError> {
        .failure(.sessionExpired("AWS Credentials are expired", ""))
    }
}

/// The adapter stores a resolver it does not read on this path.
private struct UnusedCredentialIdentityResolver: AWSCredentialIdentityResolver {
    func getIdentity(identityProperties: Smithy.Attributes?) async throws -> AWSCredentialIdentity {
        XCTFail("Not expected to be called")
        return AWSCredentialIdentity(accessKey: "", secret: "")
    }
}
