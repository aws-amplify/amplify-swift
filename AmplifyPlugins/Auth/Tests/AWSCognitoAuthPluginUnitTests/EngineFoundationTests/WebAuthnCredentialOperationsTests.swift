//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

#if os(iOS) || os(macOS) || os(visionOS)
import AuthenticationServices
#endif
import enum Amplify.AuthError
import struct AWSCognitoIdentityProvider.WebAuthnNotEnabledException
import struct AWSCognitoIdentityProvider.WebAuthnRelyingPartyMismatchException
import XCTest
@testable import AWSCognitoAuthPlugin
import InternalAWSCognitoAuth

/// The engine's WebAuthn credential operations, in engine terms: the cases the
/// plugin's `*WebAuthnCredential*TaskTests` cover through the tasks, plus the error contract the tasks rely
/// on (the caller's closures' errors pass through unchanged, every other error is an `EngineAuthError`).
///
/// - Note: `@unchecked Sendable` so the test body can be captured by the mocks' `@Sendable` closures.
///   `XCTestCase` is not `Sendable`, and each test runs alone.
final class WebAuthnCredentialOperationsTests: XCTestCase, @unchecked Sendable {
    private var fixture: WebAuthnOperationsFixture!
    private var identityProvider: MockIdentityProvider {
        get { fixture.identityProvider }
        set { fixture.identityProvider = newValue }
    }
    private var userPoolCalls: TestCounter { fixture.userPoolCalls }

    override func setUp() {
        fixture = WebAuthnOperationsFixture()
    }

    override func tearDown() {
        fixture = nil
    }

    private func accessToken() -> WebAuthnCredentialOperations.AccessTokenProvider { fixture.accessToken() }
    private func userPool() -> UserPoolEnvironment.CognitoUserPoolFactory { fixture.userPool() }

    // MARK: - List

    /// List maps Cognito's page
    ///
    /// - Given: a page of five descriptions: one complete, one with an empty friendly name, one without
    ///   `createdAt`, one without `relyingPartyId`, one without `credentialId`
    /// - When:
    ///    - `list` runs with a page size and a next token
    /// - Then:
    ///    - the request carries the caller's token, the page size and the next token
    ///    - the three entries missing a required field are dropped, the empty friendly name is `nil`
    ///    - the next token is Cognito's
    ///
    func testList_mapsThePageAndSendsTheRequest() async throws {
        let createdAt = Date(timeIntervalSince1970: 1_700_000_000)
        let inputs = TestBox<[WebAuthnListInput]>([])
        identityProvider.mockListWebAuthnCredentialsResponse = { input in
            inputs.with { $0.append(.init(input.accessToken, input.maxResults, input.nextToken)) }
            return .init(
                credentials: [
                    .init(createdAt: createdAt, credentialId: "id1", friendlyCredentialName: "Phone", relyingPartyId: "rp"),
                    .init(createdAt: createdAt, credentialId: "id2", friendlyCredentialName: "", relyingPartyId: "rp"),
                    .init(createdAt: nil, credentialId: "id3", friendlyCredentialName: "x", relyingPartyId: "rp"),
                    .init(createdAt: createdAt, credentialId: "id4", friendlyCredentialName: "x", relyingPartyId: nil),
                    .init(createdAt: createdAt, credentialId: nil, friendlyCredentialName: "x", relyingPartyId: "rp")
                ],
                nextToken: "next"
            )
        }

        let page = try await WebAuthnCredentialOperations.list(
            accessToken: accessToken(),
            pageSize: 7,
            nextToken: "start",
            userPool: userPool()
        )

        XCTAssertEqual(inputs.get(), [.init("token-1", 7, "start")])
        XCTAssertEqual(page, EngineWebAuthnCredentialPage(
            credentials: [
                .init(credentialId: "id1", createdAt: createdAt, relyingPartyId: "rp", friendlyName: "Phone"),
                .init(credentialId: "id2", createdAt: createdAt, relyingPartyId: "rp", friendlyName: nil)
            ],
            nextToken: "next"
        ))
        XCTAssertEqual(userPoolCalls.get(), 1)
    }

    /// List with no credentials
    ///
    /// - Given: Cognito answers with no `credentials` and no next token
    /// - When:
    ///    - `list` runs
    /// - Then:
    ///    - the page is empty, with no next token
    ///
    func testList_withNoCredentials_returnsAnEmptyPage() async throws {
        identityProvider.mockListWebAuthnCredentialsResponse = { _ in .init(credentials: nil, nextToken: nil) }

        let page = try await WebAuthnCredentialOperations.list(
            accessToken: accessToken(),
            pageSize: 20,
            nextToken: nil,
            userPool: userPool()
        )

        XCTAssertEqual(page, EngineWebAuthnCredentialPage(credentials: [], nextToken: nil))
    }

    /// List, service error
    ///
    /// - Given: Cognito throws `WebAuthnRelyingPartyMismatchException`
    /// - When:
    ///    - `list` runs
    /// - Then:
    ///    - it throws `EngineAuthError.service` with the engine service code `webAuthnRelyingPartyMismatch`
    ///
    func testList_withServiceError_throwsTheEngineServiceError() async {
        identityProvider.mockListWebAuthnCredentialsResponse = { _ in
            throw WebAuthnRelyingPartyMismatchException(message: "Operation is forbidden")
        }

        await assertEngineServiceError(code: .webAuthnRelyingPartyMismatch) {
            _ = try await WebAuthnCredentialOperations.list(
                accessToken: self.accessToken(),
                pageSize: 20,
                nextToken: nil,
                userPool: self.userPool()
            )
        }
    }

    /// List, other error
    ///
    /// - Given: Cognito's call throws `CancellationError`
    /// - When:
    ///    - `list` runs
    /// - Then:
    ///    - it throws `WebAuthnError.unknown`'s `EngineAuthError.service`, with the list message
    ///
    func testList_withOtherError_throwsTheUnknownServiceError() async {
        identityProvider.mockListWebAuthnCredentialsResponse = { _ in throw CancellationError() }

        await assertUnknownServiceError(
            "An unknown error type was thrown by the service. Unable to list WebAuthn credentials."
        ) {
            _ = try await WebAuthnCredentialOperations.list(
                accessToken: self.accessToken(),
                pageSize: 20,
                nextToken: nil,
                userPool: self.userPool()
            )
        }
    }

    /// List, the caller's errors
    ///
    /// - Given: the access-token closure, then (separately) the user-pool closure, throws the caller's error
    /// - When:
    ///    - `list` runs
    /// - Then:
    ///    - that error is rethrown unchanged, and Cognito is not called
    ///
    func testList_callerErrorsPassThroughUnchanged() async {
        identityProvider.mockListWebAuthnCredentialsResponse = { _ in
            XCTFail("Cognito should not be called")
            return .init()
        }

        await assertCallerError(.token) {
            _ = try await WebAuthnCredentialOperations.list(
                accessToken: { throw CallerOwnedError.token },
                pageSize: 20,
                nextToken: nil,
                userPool: self.userPool()
            )
        }
        await assertCallerError(.userPool) {
            _ = try await WebAuthnCredentialOperations.list(
                accessToken: self.accessToken(),
                pageSize: 20,
                nextToken: nil,
                userPool: { throw CallerOwnedError.userPool }
            )
        }
    }

    // MARK: - Delete

    /// Delete sends the request
    ///
    /// - Given: Cognito accepts the call
    /// - When:
    ///    - `delete` runs
    /// - Then:
    ///    - the request carries the caller's token and the credential ID
    ///
    func testDelete_sendsTheRequest() async throws {
        let inputs = TestBox<[[String?]]>([])
        identityProvider.mockDeleteWebAuthnCredentialResponse = { input in
            inputs.with { $0.append([input.accessToken, input.credentialId]) }
            return .init()
        }

        try await WebAuthnCredentialOperations.delete(
            accessToken: accessToken(),
            credentialId: "credentialId",
            userPool: userPool()
        )

        XCTAssertEqual(inputs.get(), [["token-1", "credentialId"]])
        XCTAssertEqual(userPoolCalls.get(), 1)
    }

    /// Delete, service error
    ///
    /// - Given: Cognito throws `WebAuthnNotEnabledException`
    /// - When:
    ///    - `delete` runs
    /// - Then:
    ///    - it throws `EngineAuthError.service` with the engine service code `webAuthnNotEnabled`
    ///
    func testDelete_withServiceError_throwsTheEngineServiceError() async {
        identityProvider.mockDeleteWebAuthnCredentialResponse = { _ in
            throw WebAuthnNotEnabledException(message: "WebAuthn is not enabled")
        }

        await assertEngineServiceError(code: .webAuthnNotEnabled) {
            try await WebAuthnCredentialOperations.delete(
                accessToken: self.accessToken(),
                credentialId: "credentialId",
                userPool: self.userPool()
            )
        }
    }

    /// Delete, other error
    ///
    /// - Given: Cognito's call throws `CancellationError`
    /// - When:
    ///    - `delete` runs
    /// - Then:
    ///    - it throws `WebAuthnError.unknown`'s `EngineAuthError.service`, with the delete message
    ///
    func testDelete_withOtherError_throwsTheUnknownServiceError() async {
        identityProvider.mockDeleteWebAuthnCredentialResponse = { _ in throw CancellationError() }

        await assertUnknownServiceError(
            "An unknown error type was thrown by the service. Unable to delete WebAuthn credential."
        ) {
            try await WebAuthnCredentialOperations.delete(
                accessToken: self.accessToken(),
                credentialId: "credentialId",
                userPool: self.userPool()
            )
        }
    }

    /// Delete, the caller's errors
    ///
    /// - Given: the access-token closure, then (separately) the user-pool closure, throws the caller's error
    /// - When:
    ///    - `delete` runs
    /// - Then:
    ///    - that error is rethrown unchanged, and Cognito is not called
    ///
    func testDelete_callerErrorsPassThroughUnchanged() async {
        identityProvider.mockDeleteWebAuthnCredentialResponse = { _ in
            XCTFail("Cognito should not be called")
            return .init()
        }

        await assertCallerError(.token) {
            try await WebAuthnCredentialOperations.delete(
                accessToken: { throw CallerOwnedError.token },
                credentialId: "credentialId",
                userPool: self.userPool()
            )
        }
        await assertCallerError(.userPool) {
            try await WebAuthnCredentialOperations.delete(
                accessToken: self.accessToken(),
                credentialId: "credentialId",
                userPool: { throw CallerOwnedError.userPool }
            )
        }
    }

    // MARK: - The plugin's former conversion

    /// The engine error bridges to the plugin's former `AuthError`
    ///
    /// - Given: each kind of error the three tasks could meet: a Cognito exception, a ceremony
    ///   `WebAuthnError`, an options-decoding `WebAuthnCredentialError`, and an unconvertible error
    /// - When:
    ///    - `engineError(for:failureMessage:)` re-expresses it and the plugin bridges it back with
    ///      `AuthError(converting:)`
    /// - Then:
    ///    - the result equals what the task's former catch produced from the raw error: `AuthError(converting:)`,
    ///      else `WebAuthnError.unknown(message:error:).authError` (same case, strings and underlying error)
    ///
    func testEngineErrorBridgesToThePluginsFormerAuthError() throws {
        var errors: [Error] = [
            WebAuthnNotEnabledException(message: "WebAuthn is not enabled"),
            WebAuthnRelyingPartyMismatchException(message: nil),
            CancellationError(),
            WebAuthnError.unknown(message: "inner", error: nil)
        ]
#if os(iOS) || os(macOS) || os(visionOS)
        errors += [
            WebAuthnError.creationFailed(error: ASAuthorizationError(.canceled)),
            WebAuthnError.creationFailed(error: ASAuthorizationError(ASAuthorizationError.Code(rawValue: 1_006)!)),
            WebAuthnError.creationFailed(error: ASAuthorizationError(.failed)),
            WebAuthnCredentialError.missingValue("challenge", type: CredentialCreationOptions.self)
        ]
#endif
        let message = WebAuthnCredentialOperations.associateFailureMessage
        for error in errors {
            let former = AuthError(converting: error)
                ?? WebAuthnError.unknown(message: message, error: error).authError
            let engineError = WebAuthnCredentialOperations.engineError(for: error, failureMessage: message)
            let bridged = try XCTUnwrap(AuthError(converting: engineError))

            XCTAssertEqual(authErrorFingerprint(bridged), authErrorFingerprint(former), "\(error)")
        }
    }
}
