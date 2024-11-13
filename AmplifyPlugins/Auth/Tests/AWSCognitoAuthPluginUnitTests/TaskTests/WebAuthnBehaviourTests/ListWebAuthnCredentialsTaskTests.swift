//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import AWSCognitoAuthPlugin
import enum Amplify.AuthError
import enum AWSCognitoIdentity.CognitoIdentityClientTypes
import struct AWSCognitoIdentityProvider.WebAuthnRelyingPartyMismatchException
import XCTest

class ListWebAuthnCredentialsTaskTests: XCTestCase {
    private var task: ListWebAuthnCredentialsTask!
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

        task = ListWebAuthnCredentialsTask(
            request: .init(options: .init()),
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
        var listWebAuthnCredentialsCallCount = 0
        identityProvider.mockListWebAuthnCredentialsResponse = { _ in
            listWebAuthnCredentialsCallCount += 1
            return .init(
                credentials: [
                    .init(
                        authenticatorAttachment: "authenticatorAttachment1",
                        authenticatorTransports: [],
                        createdAt: Date(),
                        credentialId: "credentialId1",
                        friendlyCredentialName: "friendlyCredentialName1",
                        relyingPartyId: "relyingPartyId"
                    ),
                    .init(
                        authenticatorAttachment: "authenticatorAttachment2",
                        authenticatorTransports: [],
                        createdAt: Date(),
                        credentialId: "credentialId2",
                        friendlyCredentialName: "friendlyCredentialName2",
                        relyingPartyId: "relyingPartyId"
                    )
                ],
                nextToken: "nextToken"
            )
        }

        let result = try await task.execute()
        let credentials = try XCTUnwrap(result.credentials)
        let nextToken = try XCTUnwrap(result.nextToken)
        XCTAssertEqual(listWebAuthnCredentialsCallCount, 1)
        XCTAssertEqual(credentials.count, 2)
        XCTAssertEqual(nextToken, "nextToken")
        XCTAssertTrue(credentials.contains(where: { $0.credentialId == "credentialId1" }))
        XCTAssertTrue(credentials.contains(where: { $0.credentialId == "credentialId2" }))
    }

    func testExecute_withServiceError_shouldFailWithServiceError() async {
        identityProvider.mockListWebAuthnCredentialsResponse = { _ in
            throw WebAuthnRelyingPartyMismatchException(message: "Operation is forbidden")
        }

        do {
            _ = try await task.execute()
            XCTFail("Task should have failed")
        } catch let error as AuthError {
            guard case .service(_, _, let underlyingError) = error else {
                XCTFail("Expected AuthError.service error, got \(error)")
                return
            }
            XCTAssertEqual(underlyingError as? AWSCognitoAuthError, AWSCognitoAuthError.webAuthnRelyingPartyMismatch)
        } catch {
            XCTFail("Expected AuthError error, got \(error)")
        }
    }

    func testExecute_withOtherError_shouldFailWithUnknownServiceError() async {
        identityProvider.mockListWebAuthnCredentialsResponse = { _ in
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
            XCTAssertEqual(description, "An unknown error type was thrown by the service. Unable to list WebAuthn credentials.")
        } catch {
            XCTFail("Expected AuthError error, got \(error)")
        }
    }
}
