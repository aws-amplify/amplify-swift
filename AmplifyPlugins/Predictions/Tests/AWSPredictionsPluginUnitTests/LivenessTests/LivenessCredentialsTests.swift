//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPluginsCore
import XCTest
@testable import AWSPredictionsPlugin
@_spi(PredictionsFaceLiveness) import AWSPredictionsPlugin

/// The credentials a Face Liveness session is signed with, when they come from the Auth session.
///
/// `@unchecked Sendable`: `XCTestCase` is not `Sendable`, but the test body is captured by the
/// `@Sendable` closures the API now takes. XCTest runs one test at a time.
class LivenessCredentialsTests: XCTestCase, @unchecked Sendable {

    /// A signed-out session is reported as signed out, not as a Rekognition permissions failure.
    ///
    /// - Given: No injected credentials provider, and an Auth session that is signed out and cannot vend
    ///   credentials
    /// - When:
    ///    - The Liveness signing credential is resolved
    /// - Then:
    ///    - It throws `AuthError.invalidState`
    ///    - It does not throw `FaceLivenessSessionError.accessDenied`
    ///
    func testCredential_signedOutSession_throwsInvalidStateNotAccessDenied() async {
        do {
            _ = try await credential(from: nil, fetchAuthSession: { SignedOutSession() })
            XCTFail("Expected resolving the credential to fail")
        } catch let error as FaceLivenessSessionError {
            XCTFail("Expected an AuthError, got FaceLivenessSessionError(code: \(error.code))")
        } catch let error as AuthError {
            guard case .invalidState = error else {
                return XCTFail("Expected AuthError.invalidState, got \(error)")
            }
        } catch {
            XCTFail("Expected AuthError.invalidState, got \(error)")
        }
    }

    /// A user-pool-only session is reported as a missing identity pool.
    ///
    /// - Given: No injected credentials provider, and a signed-in session with user pool tokens but no
    ///   credentials
    /// - When:
    ///    - The Liveness signing credential is resolved
    /// - Then:
    ///    - It throws `AuthError.configuration` naming the missing identity pool
    ///
    func testCredential_userPoolOnlySession_throwsNoIdentityPoolConfiguration() async {
        do {
            _ = try await credential(from: nil, fetchAuthSession: { UserPoolOnlySession() })
            XCTFail("Expected resolving the credential to fail")
        } catch let error as AuthError {
            guard case .configuration(let description, _, _) = error else {
                return XCTFail("Expected AuthError.configuration, got \(error)")
            }
            XCTAssertTrue(description.contains("no identity pool"), description)
        } catch {
            XCTFail("Expected AuthError.configuration, got \(error)")
        }
    }

    /// A session with credentials signs with them.
    ///
    /// - Given: No injected credentials provider, and a session with temporary credentials
    /// - When:
    ///    - The Liveness signing credential is resolved
    /// - Then:
    ///    - It carries the session's access key, secret and session token
    ///
    func testCredential_sessionWithCredentials_usesThem() async throws {
        let signerCredential = try await credential(from: nil, fetchAuthSession: { CredentialsSession() })

        XCTAssertEqual(signerCredential.accessKey, "accessKeyId")
        XCTAssertEqual(signerCredential.secretKey, "secretAccessKey")
        XCTAssertEqual(signerCredential.sessionToken, "sessionToken")
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

private struct CredentialsSession: AuthSession, AuthAWSCredentialsProvider {
    let isSignedIn = true

    func getAWSCredentials() -> Result<AWSCredentials, AuthError> {
        .success(Credentials())
    }

    private struct Credentials: AWSTemporaryCredentials {
        let accessKeyId = "accessKeyId"
        let secretAccessKey = "secretAccessKey"
        let sessionToken = "sessionToken"
        let expiration = Date(timeIntervalSinceNow: 3_600)
    }
}
