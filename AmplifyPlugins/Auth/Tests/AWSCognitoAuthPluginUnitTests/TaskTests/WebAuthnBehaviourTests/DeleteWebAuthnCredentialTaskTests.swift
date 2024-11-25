//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import AWSCognitoAuthPlugin
import enum Amplify.AuthError
import enum AWSCognitoIdentity.CognitoIdentityClientTypes
import struct AWSCognitoIdentityProvider.WebAuthnClientMismatchException
import XCTest

class DeleteWebAuthnCredentialTaskTests: XCTestCase {
    private var task: DeleteWebAuthnCredentialTask!
    private var identityProvider: MockIdentityProvider!

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

        task = DeleteWebAuthnCredentialTask(
            request: .init(credentialId: "credentialId", options: .init()),
            authStateMachine: stateMachine,
            userPoolFactory: {
                return self.identityProvider
            }
        )
    }

    override func tearDown() {
        identityProvider = nil
        task = nil
    }

    func testExecute_withSuccess_shouldSucceed() async throws {
        var deleteWebAuthnCredentialCallCount = 0
        identityProvider.mockDeleteWebAuthnCredentialResponse = { _ in
            deleteWebAuthnCredentialCallCount += 1
            return .init()
        }

        try await task.execute()
        XCTAssertEqual(deleteWebAuthnCredentialCallCount, 1)
    }

    func testExecute_withServiceError_shouldFailWithServiceError() async {
        identityProvider.mockDeleteWebAuthnCredentialResponse = { _ in
            throw WebAuthnClientMismatchException(message: "Client mismatch")
        }

        do {
            _ = try await task.execute()
            XCTFail("Task should have failed")
        } catch let error as AuthError {
            guard case .service(_, _, let underlyingError) = error else {
                XCTFail("Expected AuthError.service error, got \(error)")
                return
            }
            XCTAssertEqual(underlyingError as? AWSCognitoAuthError, AWSCognitoAuthError.webAuthnClientMismatch)
        } catch {
            XCTFail("Expected AuthError error, got \(error)")
        }
    }

    func testExecute_withOtherError_shouldFailWithUnknownServiceError() async {
        identityProvider.mockDeleteWebAuthnCredentialResponse = { _ in
            throw CancellationError()
        }

        do {
            _ = try await task.execute()
            XCTFail("Task should have failed")
        } catch let error as AuthError {
            guard case .service(let description, _, _) = error else {
                XCTFail("Expected AuthError.service error, got \(error)")
                return
            }
            XCTAssertEqual(description, "An unknown error type was thrown by the service. Unable to delete WebAuthn credential.")
        } catch {
            XCTFail("Expected AuthError error, got \(error)")
        }
    }
}
