//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

#if os(iOS) || os(macOS) || os(visionOS)
@testable import AWSCognitoAuthPlugin
import enum Amplify.AuthError
import enum AWSCognitoIdentity.CognitoIdentityClientTypes
import struct AWSCognitoIdentityProvider.WebAuthnNotEnabledException
import struct AWSCognitoIdentityProvider.StartWebAuthnRegistrationOutput
import XCTest

@available(iOS 17.4, macOS 13.5, *)
class AssociateWebAuthnCredentialTaskTests: XCTestCase {
    private var task: AssociateWebAuthnCredentialTask!
    private var identityProvider: MockIdentityProvider!
    private var credentialRegistrant: MockCredentialRegistrant!

    override func setUp() {
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
                return .init(
                    credentials: credentials,
                    identityId: "responseIdentityID"
                )
            }
        )
        identityProvider = MockIdentityProvider()
        let initialState = AuthState.configured(
            .signedIn(
                SignedInData(
                    signedInDate: Date(),
                    signInMethod: .apiBased(.userSRP),
                    cognitoUserPoolTokens: AWSCognitoUserPoolTokens.testData
                )
            ),
            .sessionEstablished(AmplifyCredentials.testData),
            .notStarted
        )

        let stateMachine = Defaults.makeDefaultAuthStateMachine(
            initialState: initialState,
            identityPoolFactory: {
                return identity
            },
            userPoolFactory: {
                return self.identityProvider
            }
        )

        credentialRegistrant = MockCredentialRegistrant()
        credentialRegistrant.mockedCreateResponse = .success(
            .init(
                credentialId: "credentialId",
                attestationObject: "attestationObject",
                clientDataJSON: "clientDataJSON"
            )
        )

        task = AssociateWebAuthnCredentialTask(
            request: .init(presentationAnchor: nil, options: .init()),
            authStateMachine: stateMachine,
            userPoolFactory: {
                return self.identityProvider
            },
            registrantFactory: { _ in
                return self.credentialRegistrant
            }
        )
    }

    override func tearDown() {
        credentialRegistrant = nil
        identityProvider = nil
        task = nil
    }

    func testExecute_withSuccess_shouldSucceed() async throws {
        var startWebAuthnRegistrationCallCount = 0
        identityProvider.mockStartWebAuthnRegistrationResponse = { _ in
            startWebAuthnRegistrationCallCount += 1
            return self.startWebAuthnRegistrationResponse()
        }

        var completeWebAuthnRegistrationCallCount = 0
        identityProvider.mockCompleteWebAuthnRegistrationResponse = { _ in
            completeWebAuthnRegistrationCallCount += 1
            return .init()
        }

        try await task.execute()
        XCTAssertEqual(startWebAuthnRegistrationCallCount, 1)
        XCTAssertEqual(credentialRegistrant.createCallCount, 1)
        XCTAssertEqual(completeWebAuthnRegistrationCallCount, 1)
    }

    func testExecute_withRegistrationFailed_shouldFail() async {
        var startWebAuthnRegistrationCallCount = 0
        identityProvider.mockStartWebAuthnRegistrationResponse = { _ in
            startWebAuthnRegistrationCallCount += 1
            return self.startWebAuthnRegistrationResponse()
        }

        var completeWebAuthnRegistrationCallCount = 0
        identityProvider.mockCompleteWebAuthnRegistrationResponse = { _ in
            completeWebAuthnRegistrationCallCount += 1
            return .init()
        }

        credentialRegistrant.mockedCreateResponse = .failure(
            WebAuthnError.creationFailed(error: .init(.failed))
        )

        do {
            try await task.execute()
            XCTFail("Task should have failed")
        } catch let error as AuthError {
            guard case .service = error else {
                XCTFail("Expected AuthError.service error, got \(error)")
                return
            }

            XCTAssertEqual(startWebAuthnRegistrationCallCount, 1)
            XCTAssertEqual(credentialRegistrant.createCallCount, 1)
            XCTAssertEqual(completeWebAuthnRegistrationCallCount, 0)
        } catch {
            XCTFail("Expected AuthError error, got \(error)")
        }
    }

    func testExecute_withServiceErrorOnStart_shouldFailWithServiceError() async {
        identityProvider.mockStartWebAuthnRegistrationResponse = { _ in
            throw WebAuthnNotEnabledException(message: "WebAuthn is not enabled")
        }

        var completeWebAuthnRegistrationCallCount = 0
        identityProvider.mockCompleteWebAuthnRegistrationResponse = { _ in
            completeWebAuthnRegistrationCallCount += 1
            return .init()
        }

        do {
            try await task.execute()
            XCTFail("Task should have failed")
        } catch let error as AuthError {
            guard case .service(_, _, let underlyingError) = error else {
                XCTFail("Expected AuthError.service error, got \(error)")
                return
            }

            XCTAssertEqual(underlyingError as? AWSCognitoAuthError, AWSCognitoAuthError.webAuthnNotEnabled)
            XCTAssertEqual(credentialRegistrant.createCallCount, 0)
            XCTAssertEqual(completeWebAuthnRegistrationCallCount, 0)
        } catch {
            XCTFail("Expected AuthError error, got \(error)")
        }
    }

    func testExecute_withOtherErrorOnStart_shouldFailWithUnknownServiceError() async {
        identityProvider.mockStartWebAuthnRegistrationResponse = { _ in
            throw CancellationError()
        }

        var completeWebAuthnRegistrationCallCount = 0
        identityProvider.mockCompleteWebAuthnRegistrationResponse = { _ in
            completeWebAuthnRegistrationCallCount += 1
            return .init()
        }

        do {
            try await task.execute()
            XCTFail("Task should have failed")
        } catch let error as AuthError {
            guard case .service(let description, _, _) = error else {
                XCTFail("Expected AuthError.service error, got \(error)")
                return
            }

            XCTAssertEqual(description, "An unknown error type was thrown by the service. Unable to associate WebAuthn credential.")
            XCTAssertEqual(credentialRegistrant.createCallCount, 0)
            XCTAssertEqual(completeWebAuthnRegistrationCallCount, 0)
        } catch {
            XCTFail("Expected AuthError error, got \(error)")
        }
    }

    func testExecute_withServiceErrorOnComplete_shouldFailWithServiceError() async {
        var startWebAuthnRegistrationCallCount = 0
        identityProvider.mockStartWebAuthnRegistrationResponse = { _ in
            startWebAuthnRegistrationCallCount += 1
            return self.startWebAuthnRegistrationResponse()
        }

        identityProvider.mockCompleteWebAuthnRegistrationResponse = { _ in
            throw WebAuthnNotEnabledException(message: "WebAuthn is not enabled")
        }

        do {
            try await task.execute()
            XCTFail("Task should have failed")
        } catch let error as AuthError {
            guard case .service(_, _, let underlyingError) = error else {
                XCTFail("Expected AuthError.service error, got \(error)")
                return
            }

            XCTAssertEqual(underlyingError as? AWSCognitoAuthError, AWSCognitoAuthError.webAuthnNotEnabled)
            XCTAssertEqual(startWebAuthnRegistrationCallCount, 1)
            XCTAssertEqual(credentialRegistrant.createCallCount, 1)
        } catch {
            XCTFail("Expected AuthError error, got \(error)")
        }
    }

    func testExecute_withOtherErrorOnComplete_shouldFailWithUnknownServiceError() async {
        var startWebAuthnRegistrationCallCount = 0
        identityProvider.mockStartWebAuthnRegistrationResponse = { _ in
            startWebAuthnRegistrationCallCount += 1
            return self.startWebAuthnRegistrationResponse()
        }

        identityProvider.mockCompleteWebAuthnRegistrationResponse = { _ in
            throw CancellationError()
        }

        do {
            try await task.execute()
            XCTFail("Task should have failed")
        } catch let error as AuthError {
            guard case .service(let description, _, _) = error else {
                XCTFail("Expected AuthError.service error, got \(error)")
                return
            }

            XCTAssertEqual(description, "An unknown error type was thrown by the service. Unable to associate WebAuthn credential.")
            XCTAssertEqual(startWebAuthnRegistrationCallCount, 1)
            XCTAssertEqual(credentialRegistrant.createCallCount, 1)
        } catch {
            XCTFail("Expected AuthError error, got \(error)")
        }
    }

    private func startWebAuthnRegistrationResponse() -> StartWebAuthnRegistrationOutput {
        return .init(credentialCreationOptions: [
            "challenge": "Y2hhbGxlbmdl",
            "rp": [
                "id": "relyingPartyId"
            ],
            "user": [
                "id": "dXNlcklk",
                "name": "User"
            ],
            "excludeCredentials": []
        ])
    }

}

#endif
