//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import enum AWSCognitoIdentity.CognitoIdentityClientTypes
import Amplify
import XCTest
@testable import AWSCognitoAuthPlugin
import InternalAWSCognitoAuth

/// The three WebAuthn tasks with no signed-in user: the token lookup's own `AuthError` reaches the caller
/// unchanged, as it did before the task bodies moved into the engine. The engine
/// rethrows the errors of the caller's token closure as they are; if it re-expressed them, these would be
/// `AuthError.service` ("An unknown error type was thrown by the service. …").
///
/// - Note: `@unchecked Sendable` so the test body can be captured by the mocks' `@Sendable` closures.
///   `XCTestCase` is not `Sendable`, and each test runs alone.
class WebAuthnTaskTokenLookupTests: XCTestCase, @unchecked Sendable {
    private var identityProvider: MockIdentityProvider!
    private var stateMachine: AuthStateMachine!

    override func setUp() {
        identityProvider = MockIdentityProvider()
        identityProvider.mockListWebAuthnCredentialsResponse = { _ in
            XCTFail("Cognito should not be called")
            return .init()
        }
        identityProvider.mockDeleteWebAuthnCredentialResponse = { _ in
            XCTFail("Cognito should not be called")
            return .init()
        }
        identityProvider.mockStartWebAuthnRegistrationResponse = { _ in
            XCTFail("Cognito should not be called")
            return .init()
        }
        let identity = MockIdentity(
            mockGetIdResponse: { _ in
                return .init(identityId: "mockIdentityId")
            },
            mockGetCredentialsResponse: { _ in
                let credentials = CognitoIdentityClientTypes.Credentials(
                    accessKeyId: "accessKey",
                    expiration: Date(),
                    secretKey: "secret",
                    sessionToken: "session"
                )
                return .init(credentials: credentials, identityId: "responseIdentityID")
            }
        )
        stateMachine = Defaults.makeDefaultAuthStateMachine(
            initialState: AuthState.configured(
                AuthenticationState.signedOut(.testData),
                AuthorizationState.configured,
                .notStarted
            ),
            identityPoolFactory: { identity },
            userPoolFactory: { self.identityProvider }
        )
    }

    override func tearDown() {
        identityProvider = nil
        stateMachine = nil
    }

    /// List, signed out
    ///
    /// - Given: no signed-in user
    /// - When:
    ///    - the list task runs
    /// - Then:
    ///    - it throws the token lookup's `AuthError.signedOut`, and Cognito is not called
    ///
    func testList_whenSignedOut_throwsTheTokenLookupsSignedOutError() async {
        let task = ListWebAuthnCredentialsTask(
            request: .init(options: .init()),
            authStateMachine: stateMachine,
            userPoolFactory: { self.identityProvider }
        )

        await assertSignedOut { _ = try await task.execute() }
    }

    /// Delete, signed out
    ///
    /// - Given: no signed-in user
    /// - When:
    ///    - the delete task runs
    /// - Then:
    ///    - it throws the token lookup's `AuthError.signedOut`, and Cognito is not called
    ///
    func testDelete_whenSignedOut_throwsTheTokenLookupsSignedOutError() async {
        let task = DeleteWebAuthnCredentialTask(
            request: .init(credentialId: "credentialId", options: .init()),
            authStateMachine: stateMachine,
            userPoolFactory: { self.identityProvider }
        )

        await assertSignedOut { try await task.execute() }
    }

#if os(iOS) || os(macOS) || os(visionOS)
    /// Associate, signed out
    ///
    /// - Given: no signed-in user
    /// - When:
    ///    - the associate task runs
    /// - Then:
    ///    - it throws the token lookup's `AuthError.signedOut`; neither Cognito nor the ceremony is called
    ///
    @available(iOS 17.4, macOS 13.5, visionOS 1.0, *)
    func testAssociate_whenSignedOut_throwsTheTokenLookupsSignedOutError() async {
        let registrant = MockCredentialRegistrant()
        let task = AssociateWebAuthnCredentialTask(
            request: .init(presentationAnchor: nil, options: .init()),
            authStateMachine: stateMachine,
            userPoolFactory: { self.identityProvider },
            registrantFactory: { _ in registrant }
        )

        await assertSignedOut { try await task.execute() }
        XCTAssertEqual(registrant.createCallCount.get(), 0)
    }
#endif

    private func assertSignedOut(
        file: StaticString = #filePath,
        line: UInt = #line,
        _ body: () async throws -> Void
    ) async {
        do {
            try await body()
            XCTFail("Task should have failed", file: file, line: line)
        } catch let error as AuthError {
            guard case .signedOut = error else {
                return XCTFail("Expected AuthError.signedOut, got \(error)", file: file, line: line)
            }
        } catch {
            XCTFail("Expected AuthError, got \(error)", file: file, line: line)
        }
    }
}
