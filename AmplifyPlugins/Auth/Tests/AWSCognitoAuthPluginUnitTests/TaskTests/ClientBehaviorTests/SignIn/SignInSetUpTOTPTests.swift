//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSClientRuntime
import AWSCognitoIdentity
import AWSCognitoIdentityProvider
import XCTest
@testable import Amplify
@testable import AWSCognitoAuthPlugin
@_spi(UnknownAWSHTTPServiceError) import AWSClientRuntime
import InternalAWSCognitoAuth

class SignInSetUpTOTPTests: BasePluginTest, @unchecked Sendable {

    override var initialState: AuthState {
        AuthState.configured(.signedOut(.init(lastKnownUserName: nil)), .configured, .notStarted)
    }

    /// Test a signIn with valid inputs getting continueSignInWithTOTPSetup challenge
    ///
    /// - Given: Given an auth plugin with mocked service.
    ///
    /// - When:
    ///    - I invoke signIn with valid values
    /// - Then:
    ///    - I should get a .continueSignInWithTOTPSetup response
    ///
    func testSuccessfulTOTPSetupChallenge() async {
        mockIdentityProvider = MockIdentityProvider(mockInitiateAuthResponse: { input in
            return InitiateAuthOutput(
                authenticationResult: .none,
                challengeName: .passwordVerifier,
                challengeParameters: InitiateAuthOutput.validChalengeParams,
                session: "someSession"
            )
        }, mockRespondToAuthChallengeResponse: { input in
            return .testData(
                challenge: .mfaSetup,
                challengeParameters: ["MFAS_CAN_SETUP": "[\"SMS_MFA\",\"SOFTWARE_TOKEN_MFA\"]"]
            )
        }, mockAssociateSoftwareTokenResponse: { input in
            return .init(secretCode: "sharedSecret", session: "newSession")
        })
        let options = AuthSignInRequest.Options()

        do {
            let result = try await plugin.signIn(
                username: "username",
                password: "password",
                options: options
            )
            guard case .continueSignInWithTOTPSetup(let totpDetails) = result.nextStep else {
                XCTFail("Result should be .continueSignInWithTOTPSetup for next step")
                return
            }
            XCTAssertEqual(totpDetails.sharedSecret, "sharedSecret")
            XCTAssertEqual(totpDetails.username, "username")
            XCTAssertFalse(result.isSignedIn, "Signin result should be complete")
        } catch {
            XCTFail("Received failure with error \(error)")
        }
    }

    func testSignInWithNextStepSetupMFAWithUnavailableMFAType() async {

        mockIdentityProvider = MockIdentityProvider(mockInitiateAuthResponse: { _ in
            InitiateAuthOutput(
                authenticationResult: .none,
                challengeName: .passwordVerifier,
                challengeParameters: InitiateAuthOutput.validChalengeParams,
                session: "someSession"
            )
        }, mockRespondToAuthChallengeResponse: { _ in
            RespondToAuthChallengeOutput(
                authenticationResult: .none,
                challengeName: .mfaSetup,
                challengeParameters: ["MFAS_CAN_SETUP": "[\"SMS_MFA\"]"],
                session: "session"
            )
        }, mockAssociateSoftwareTokenResponse: { _ in
            return .init(secretCode: "123456", session: "session")
        })

        let options = AuthSignInRequest.Options()
        do {
            _ = try await plugin.signIn(username: "username", password: "password", options: options)
            XCTFail("Should not continue as MFA type is not available for setup")
        } catch {
            guard case AuthError.service = error else {
                XCTFail("Should produce as service error")
                return
            }
        }
    }


    /// Test a signIn with valid inputs getting continueSignInWithTOTPSetup challenge
    ///
    /// - Given: Given an auth plugin with mocked service.
    ///
    /// - When:
    ///    - I invoke signIn with valid values
    /// - Then:
    ///    - I should get a .continueSignInWithTOTPSetup response
    ///
    func testSuccessfulTOTPSetupChallengeWithEmptyMFASCanSetup() async {
        mockIdentityProvider = MockIdentityProvider(mockInitiateAuthResponse: { input in
            return InitiateAuthOutput(
                authenticationResult: .none,
                challengeName: .passwordVerifier,
                challengeParameters: InitiateAuthOutput.validChalengeParams,
                session: "someSession"
            )
        }, mockRespondToAuthChallengeResponse: { input in
            return .testData(
                challenge: .mfaSetup,
                challengeParameters: [:]
            )
        }, mockAssociateSoftwareTokenResponse: { input in
            return .init(secretCode: "sharedSecret", session: "newSession")
        })
        let options = AuthSignInRequest.Options()

        do {
            _ = try await plugin.signIn(
                username: "username",
                password: "password",
                options: options
            )
            XCTFail("Should throw an error")
        } catch {
            guard case AuthError.service(_, _, _) = error else {
                XCTFail("Should receive service error instead got \(error)")
                return
            }
        }
    }


    /// Test a signIn with nil as reponse from service
    ///
    /// - Given: Given an auth plugin with mocked service. Mock nil response from service
    ///
    /// - When:
    ///    - I invoke signIn
    /// - Then:
    ///    - I should get a .unknown error
    ///
    func testSignInWithInvalidResult() async {

        mockIdentityProvider = MockIdentityProvider(mockInitiateAuthResponse: { input in
            return InitiateAuthOutput(
                authenticationResult: .none,
                challengeName: .passwordVerifier,
                challengeParameters: InitiateAuthOutput.validChalengeParams,
                session: "someSession"
            )
        }, mockRespondToAuthChallengeResponse: { input in
            return .testData(
                challenge: .mfaSetup,
                challengeParameters: [:]
            )
        }, mockAssociateSoftwareTokenResponse: { input in
            return .init()
        })
        let options = AuthSignInRequest.Options()

        do {
            _ = try await plugin.signIn(
                username: "username",
                password: "password",
                options: options
            )
            XCTFail("Should throw an error")
        } catch {
            guard case AuthError.service(_, _, _) = error else {
                XCTFail("Should receive service error instead got \(error)")
                return
            }
        }
    }

    /// Test a signIn with nil as reponse from service followed by a second signIn with a valid response
    ///
    /// - Given: Given an auth plugin with mocked service. Mock nil response from service followed by a valid response
    ///
    /// - When:
    ///    - I invoke signIn a second time
    /// - Then:
    ///    - I should get signed in
    ///
    func testSecondSignInAfterSignInWithInvalidResult() async {

        mockIdentityProvider = MockIdentityProvider(mockInitiateAuthResponse: { input in
            return InitiateAuthOutput(
                authenticationResult: .none,
                challengeName: .passwordVerifier,
                challengeParameters: InitiateAuthOutput.validChalengeParams,
                session: "someSession"
            )
        }, mockRespondToAuthChallengeResponse: { input in
            return .testData(
                challenge: .mfaSetup,
                challengeParameters: ["MFAS_CAN_SETUP": "[\"SMS_MFA\",\"SOFTWARE_TOKEN_MFA\"]"]
            )
        }, mockAssociateSoftwareTokenResponse: { input in
            return .init()
        })
        let options = AuthSignInRequest.Options()
        do {
            let result = try await plugin.signIn(username: "username", password: "password", options: options)
            XCTFail("Should not receive a success response \(result)")
        } catch {
            mockIdentityProvider = MockIdentityProvider(mockInitiateAuthResponse: { input in
                return InitiateAuthOutput(
                    authenticationResult: .none,
                    challengeName: .passwordVerifier,
                    challengeParameters: InitiateAuthOutput.validChalengeParams,
                    session: "someSession"
                )
            }, mockRespondToAuthChallengeResponse: { input in
                return .testData(
                    challenge: .mfaSetup,
                    challengeParameters: ["MFAS_CAN_SETUP": "[\"SMS_MFA\",\"SOFTWARE_TOKEN_MFA\"]"]
                )
            }, mockAssociateSoftwareTokenResponse: { input in
                return .init(secretCode: "sharedSecret", session: "newSession")
            })

            do {
                let result2 = try await plugin.signIn(username: "username", password: "password", options: options)
                guard case .continueSignInWithTOTPSetup(let totpDetails) = result2.nextStep else {
                    XCTFail("Result should be .continueSignInWithTOTPSetup for next step")
                    return
                }
                XCTAssertEqual(totpDetails.sharedSecret, "sharedSecret")
                XCTAssertEqual(totpDetails.username, "username")
                XCTAssertFalse(result2.isSignedIn, "Signin result should be complete")
            } catch {
                XCTFail("Received failure with error \(error)")
            }
        }
    }

    // MARK: - Service error for initiateAuth

    /// Test a signIn with `InternalErrorException` from service
    ///
    /// - Given: Given an auth plugin with mocked service. Mocked service should mock a
    ///   InternalErrorException response for signIn
    ///
    /// - When:
    ///    - I invoke signIn
    /// - Then:
    ///    - I should get a .unknown error
    ///
    func testSignInWithInternalErrorException() async {

        mockIdentityProvider = MockIdentityProvider(mockInitiateAuthResponse: { input in
            return InitiateAuthOutput(
                authenticationResult: .none,
                challengeName: .passwordVerifier,
                challengeParameters: InitiateAuthOutput.validChalengeParams,
                session: "someSession"
            )
        }, mockRespondToAuthChallengeResponse: { input in
            return .testData(
                challenge: .mfaSetup,
                challengeParameters: ["MFAS_CAN_SETUP": "[\"SMS_MFA\",\"SOFTWARE_TOKEN_MFA\"]"]
            )
        }, mockAssociateSoftwareTokenResponse: { input in
            throw AWSCognitoIdentityProvider.InternalErrorException()
        })

        let options = AuthSignInRequest.Options()
        do {
            let result = try await plugin.signIn(username: "username", password: "password", options: options)
            XCTFail("Should not produce result - \(result)")
        } catch {
            guard case AuthError.unknown = error else {
                XCTFail("Should produce unknown error")
                return
            }
        }
    }

    /// Test a signIn with `InvalidParameterException` from service
    ///
    /// - Given: Given an auth plugin with mocked service. Mocked service should mock a
    ///   InvalidParameterException response for signIn
    ///
    /// - When:
    ///    - I invoke signIn
    /// - Then:
    ///    - I should get a .service error with .invalidParameter error
    ///
    func testSignInWithInvalidParameterException() async {

        mockIdentityProvider = MockIdentityProvider(mockInitiateAuthResponse: { input in
            return InitiateAuthOutput(
                authenticationResult: .none,
                challengeName: .passwordVerifier,
                challengeParameters: InitiateAuthOutput.validChalengeParams,
                session: "someSession"
            )
        }, mockRespondToAuthChallengeResponse: { input in
            return .testData(
                challenge: .mfaSetup,
                challengeParameters: ["MFAS_CAN_SETUP": "[\"SMS_MFA\",\"SOFTWARE_TOKEN_MFA\"]"]
            )
        }, mockAssociateSoftwareTokenResponse: { input in
            throw AWSCognitoIdentityProvider.InvalidParameterException()
        })

        let options = AuthSignInRequest.Options()
        do {
            let result = try await plugin.signIn(username: "username", password: "password", options: options)
            XCTFail("Should not produce result - \(result)")
        } catch {
            guard case AuthError.service(_, _, let underlyingError) = error,
                  case .invalidParameter = (underlyingError as? AWSCognitoAuthError)
            else {
                XCTFail("Should produce invalidParameter error but instead produced \(error)")
                return
            }
        }
    }

    /// Test a signIn with `NotAuthorizedException` from service
    ///
    /// - Given: Given an auth plugin with mocked service. Mocked service should mock a
    ///   NotAuthorizedException response for signIn
    ///
    /// - When:
    ///    - I invoke signIn
    /// - Then:
    ///    - I should get a .notAuthorized error
    ///
    func testSignInWithNotAuthorizedException() async {

        mockIdentityProvider = MockIdentityProvider(mockInitiateAuthResponse: { input in
            return InitiateAuthOutput(
                authenticationResult: .none,
                challengeName: .passwordVerifier,
                challengeParameters: InitiateAuthOutput.validChalengeParams,
                session: "someSession"
            )
        }, mockRespondToAuthChallengeResponse: { input in
            return .testData(
                challenge: .mfaSetup,
                challengeParameters: ["MFAS_CAN_SETUP": "[\"SMS_MFA\",\"SOFTWARE_TOKEN_MFA\"]"]
            )
        }, mockAssociateSoftwareTokenResponse: { input in
            throw AWSCognitoIdentityProvider.NotAuthorizedException()
        })

        let options = AuthSignInRequest.Options()
        do {
            let result = try await plugin.signIn(username: "username", password: "password", options: options)
            XCTFail("Should not produce result - \(result)")
        } catch {
            guard case AuthError.notAuthorized = error else {
                XCTFail("Should produce notAuthorized error but instead produced \(error)")
                return
            }
        }
    }

    /// Test a signIn with `ResourceNotFoundException` from service
    ///
    /// - Given: Given an auth plugin with mocked service. Mocked service should mock a
    ///   ResourceNotFoundException response for signIn
    ///
    /// - When:
    ///    - I invoke signIn
    /// - Then:
    ///    - I should get a .service error with .resourceNotFound error
    ///
    func testSignInWithResourceNotFoundException() async {

        mockIdentityProvider = MockIdentityProvider(mockInitiateAuthResponse: { input in
            return InitiateAuthOutput(
                authenticationResult: .none,
                challengeName: .passwordVerifier,
                challengeParameters: InitiateAuthOutput.validChalengeParams,
                session: "someSession"
            )
        }, mockRespondToAuthChallengeResponse: { input in
            return .testData(
                challenge: .mfaSetup,
                challengeParameters: ["MFAS_CAN_SETUP": "[\"SMS_MFA\",\"SOFTWARE_TOKEN_MFA\"]"]
            )
        }, mockAssociateSoftwareTokenResponse: { input in
            throw AWSCognitoIdentityProvider.ResourceNotFoundException()
        })

        let options = AuthSignInRequest.Options()
        do {
            let result = try await plugin.signIn(username: "username", password: "password", options: options)
            XCTFail("Should not produce result - \(result)")
        } catch {
            guard case AuthError.service(_, _, let underlyingError) = error,
                  case .resourceNotFound = (underlyingError as? AWSCognitoAuthError)
            else {
                XCTFail("Should produce resourceNotFound error but instead produced \(error)")
                return
            }
        }
    }

    /// Test a signIn with `ResourceNotFoundException` from service
    ///
    /// - Given: Given an auth plugin with mocked service. Mocked service should mock a
    ///   ConcurrentModificationException response for signIn
    ///
    /// - When:
    ///    - I invoke signIn
    /// - Then:
    ///    - I should get a .service error
    ///
    func testSignInWithConcurrentModificationException() async {

        mockIdentityProvider = MockIdentityProvider(mockInitiateAuthResponse: { input in
            return InitiateAuthOutput(
                authenticationResult: .none,
                challengeName: .passwordVerifier,
                challengeParameters: InitiateAuthOutput.validChalengeParams,
                session: "someSession"
            )
        }, mockRespondToAuthChallengeResponse: { input in
            return .testData(
                challenge: .mfaSetup,
                challengeParameters: ["MFAS_CAN_SETUP": "[\"SMS_MFA\",\"SOFTWARE_TOKEN_MFA\"]"]
            )
        }, mockAssociateSoftwareTokenResponse: { input in
            throw AWSCognitoIdentityProvider.ConcurrentModificationException()
        })

        let options = AuthSignInRequest.Options()
        do {
            let result = try await plugin.signIn(username: "username", password: "password", options: options)
            XCTFail("Should not produce result - \(result)")
        } catch {
            guard case AuthError.service(_, _, _) = error else {
                XCTFail("Should produce service error but instead produced \(error)")
                return
            }
        }
    }

    /// Test a signIn with `ForbiddenException` from service
    ///
    /// - Given: Given an auth plugin with mocked service. Mocked service should mock a
    ///   ForbiddenException response for signIn
    ///
    /// - When:
    ///    - I invoke signIn
    /// - Then:
    ///    - I should get a .service error
    ///
    func testSignInWithForbiddenException() async {

        mockIdentityProvider = MockIdentityProvider(mockInitiateAuthResponse: { input in
            return InitiateAuthOutput(
                authenticationResult: .none,
                challengeName: .passwordVerifier,
                challengeParameters: InitiateAuthOutput.validChalengeParams,
                session: "someSession"
            )
        }, mockRespondToAuthChallengeResponse: { input in
            return .testData(
                challenge: .mfaSetup,
                challengeParameters: ["MFAS_CAN_SETUP": "[\"SMS_MFA\",\"SOFTWARE_TOKEN_MFA\"]"]
            )
        }, mockAssociateSoftwareTokenResponse: { input in
            throw AWSCognitoIdentityProvider.ForbiddenException()
        })

        let options = AuthSignInRequest.Options()
        do {
            let result = try await plugin.signIn(username: "username", password: "password", options: options)
            XCTFail("Should not produce result - \(result)")
        } catch {
            guard case AuthError.service(_, _, _) = error else {
                XCTFail("Should produce service error but instead produced \(error)")
                return
            }
        }
    }

    /// Test a signIn with `SoftwareTokenMFANotFoundException` from service
    ///
    /// - Given: Given an auth plugin with mocked service. Mocked service should mock a
    ///   SoftwareTokenMFANotFoundException response for signIn
    ///
    /// - When:
    ///    - I invoke signIn
    /// - Then:
    ///    - I should get a .service error
    ///
    func testSignInWithSoftwareTokenMFANotFoundException() async {

        mockIdentityProvider = MockIdentityProvider(mockInitiateAuthResponse: { input in
            return InitiateAuthOutput(
                authenticationResult: .none,
                challengeName: .passwordVerifier,
                challengeParameters: InitiateAuthOutput.validChalengeParams,
                session: "someSession"
            )
        }, mockRespondToAuthChallengeResponse: { input in
            return .testData(
                challenge: .mfaSetup,
                challengeParameters: ["MFAS_CAN_SETUP": "[\"SMS_MFA\",\"SOFTWARE_TOKEN_MFA\"]"]
            )
        }, mockAssociateSoftwareTokenResponse: { input in
            throw AWSCognitoIdentityProvider.SoftwareTokenMFANotFoundException()
        })

        let options = AuthSignInRequest.Options()
        do {
            let result = try await plugin.signIn(username: "username", password: "password", options: options)
            XCTFail("Should not produce result - \(result)")
        } catch {
            guard case AuthError.service(_, _, let underlyingError) = error,
                  case .softwareTokenMFANotEnabled = (underlyingError as? AWSCognitoAuthError)
            else {
                XCTFail("Should produce resourceNotFound error but instead produced \(error)")
                return
            }
        }
    }

    /// Test a signIn with `UnknownAWSHttpServiceError` from service
    ///
    /// - Given: Given an auth plugin with mocked service. Mocked service should mock a
    ///   UnknownAWSHttpServiceError response for signIn
    ///
    /// - When:
    ///    - I invoke signIn
    /// - Then:
    ///    - I should get a .service error
    ///
    func testSignInWithUnknownAWSHttpServiceError() async {

        mockIdentityProvider = MockIdentityProvider(mockInitiateAuthResponse: { input in
            return InitiateAuthOutput(
                authenticationResult: .none,
                challengeName: .passwordVerifier,
                challengeParameters: InitiateAuthOutput.validChalengeParams,
                session: "someSession"
            )
        }, mockRespondToAuthChallengeResponse: { input in
            return .testData(
                challenge: .mfaSetup,
                challengeParameters: ["MFAS_CAN_SETUP": "[\"SMS_MFA\",\"SOFTWARE_TOKEN_MFA\"]"]
            )
        }, mockAssociateSoftwareTokenResponse: { input in
            throw AWSClientRuntime.UnknownAWSHTTPServiceError(
                httpResponse: .init(body: .empty, statusCode: .ok),
                message: nil,
                requestID: nil,
                requestID2: nil,
                typeName: nil
            )
        })

        let options = AuthSignInRequest.Options()
        do {
            let result = try await plugin.signIn(username: "username", password: "password", options: options)
            XCTFail("Should not produce result - \(result)")
        } catch {
            guard case AuthError.unknown = error else {
                XCTFail("Should produce resourceNotFound error but instead produced \(error)")
                return
            }
        }
    }

    /// A `USER_AUTH` sign-in with the password factor that Cognito answers with `MFA_SETUP` offering TOTP but
    /// not email OTP is the TOTP setup step.
    ///
    /// - Given: an auth plugin with mocked service. `InitiateAuth` answers `MFA_SETUP` with `SMS_MFA` and
    ///   `SOFTWARE_TOKEN_MFA`, and `AssociateSoftwareToken` answers a secret
    /// - When:
    ///    - I invoke signIn with a password and `.userAuth(preferredFirstFactor: .password)`
    /// - Then:
    ///    - it returns `.continueSignInWithTOTPSetup` with the secret within the bound, instead of never
    ///      returning
    ///
    func testUserAuthPasswordSignInAnsweredWithMFASetupIsTheTOTPSetup() async {
        mockIdentityProvider = MockIdentityProvider(mockInitiateAuthResponse: { input in
            XCTAssertEqual(input.authFlow, .userAuth)
            XCTAssertEqual(input.authParameters?["PREFERRED_CHALLENGE"], "PASSWORD")
            return InitiateAuthOutput(
                authenticationResult: .none,
                challengeName: .mfaSetup,
                challengeParameters: ["MFAS_CAN_SETUP": "[\"SMS_MFA\",\"SOFTWARE_TOKEN_MFA\"]"],
                session: "someSession"
            )
        }, mockAssociateSoftwareTokenResponse: { _ in
            return .init(secretCode: "sharedSecret", session: "newSession")
        })
        let pluginOptions = AWSAuthSignInOptions(authFlowType: .userAuth(preferredFirstFactor: .password))
        let options = AuthSignInRequest.Options(pluginOptions: pluginOptions)
        let returned = expectation(description: "signIn returns")

        Task {
            defer { returned.fulfill() }
            do {
                let result = try await self.plugin.signIn(username: "username", password: "password", options: options)
                guard case .continueSignInWithTOTPSetup(let totpDetails) = result.nextStep else {
                    XCTFail("Result should be .continueSignInWithTOTPSetup for next step, got \(result.nextStep)")
                    return
                }
                XCTAssertEqual(totpDetails.sharedSecret, "sharedSecret")
                XCTAssertEqual(totpDetails.username, "username")
            } catch {
                XCTFail("Received failure with error \(error)")
            }
        }

        await fulfillment(of: [returned], timeout: 5)
    }

    /// A TOTP setup whose `AssociateSoftwareToken` fails, after the user picked TOTP, throws, and a retried
    /// confirmSignIn is refused instead of never returning.
    ///
    /// - Given: an auth plugin with mocked service. SRP is answered with `MFA_SETUP` offering TOTP and email
    ///   OTP, and `AssociateSoftwareToken` fails with `InternalErrorException`
    /// - When:
    ///    - I invoke signIn, then confirmSignIn selecting TOTP, then confirmSignIn selecting TOTP again
    /// - Then:
    ///    - signIn returns `.continueSignInWithMFASetupSelection`
    ///    - the first confirmSignIn throws an `.unknown` error
    ///    - the second throws `.invalidState`
    ///    - each within the bound
    ///
    func testRetryAfterAFailedTOTPAssociationIsRefused() async {
        mockIdentityProvider = MockIdentityProvider(mockInitiateAuthResponse: { _ in
            return InitiateAuthOutput(
                authenticationResult: .none,
                challengeName: .passwordVerifier,
                challengeParameters: InitiateAuthOutput.validChalengeParams,
                session: "someSession"
            )
        }, mockRespondToAuthChallengeResponse: { _ in
            return .testData(
                challenge: .mfaSetup,
                challengeParameters: ["MFAS_CAN_SETUP": "[\"SOFTWARE_TOKEN_MFA\",\"EMAIL_OTP\"]"]
            )
        }, mockAssociateSoftwareTokenResponse: { _ in
            throw AWSCognitoIdentityProvider.InternalErrorException(message: "Exception")
        })
        let selected = expectation(description: "the TOTP selection returns")
        let retried = expectation(description: "the retried TOTP selection returns")

        Task {
            do {
                let result = try await self.plugin.signIn(username: "username", password: "password", options: .init())
                guard case .continueSignInWithMFASetupSelection = result.nextStep else {
                    XCTFail("Result should be .continueSignInWithMFASetupSelection for next step, got \(result.nextStep)")
                    return
                }
                _ = try await self.plugin.confirmSignIn(challengeResponse: MFAType.totp.challengeResponse)
                XCTFail("Should not succeed")
            } catch {
                guard case AuthError.unknown = error else {
                    XCTFail("Should produce an unknown error instead of \(error)")
                    return
                }
            }
            selected.fulfill()
            do {
                _ = try await self.plugin.confirmSignIn(challengeResponse: MFAType.totp.challengeResponse)
                XCTFail("Should not succeed")
            } catch {
                guard case AuthError.invalidState = error else {
                    XCTFail("Should produce an invalidState error instead of \(error)")
                    return
                }
            }
            retried.fulfill()
        }

        await fulfillment(of: [selected, retried], timeout: 5, enforceOrder: true)
    }
}
