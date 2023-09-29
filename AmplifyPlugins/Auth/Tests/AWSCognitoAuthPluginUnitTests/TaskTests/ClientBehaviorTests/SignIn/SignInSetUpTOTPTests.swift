//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import AWSCognitoIdentity
@testable import Amplify
@testable import AWSCognitoAuthPlugin
import AWSCognitoIdentityProvider
import AWSClientRuntime

class SignInSetUpTOTPTests: BasePluginTest {

    override var initialState: AuthState {
        AuthState.configured(.signedOut(.init(lastKnownUserName: nil)), .configured)
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
        self.mockIdentityProvider = MockIdentityProvider(mockInitiateAuthResponse: { input in
            return InitiateAuthOutputResponse(
                authenticationResult: .none,
                challengeName: .passwordVerifier,
                challengeParameters: InitiateAuthOutputResponse.validChalengeParams,
                session: "someSession")
        }, mockRespondToAuthChallengeResponse: { input in
            return .testData(
                challenge: .mfaSetup,
                challengeParameters: ["MFAS_CAN_SETUP": "[\"SMS_MFA\",\"SOFTWARE_TOKEN_MFA\"]"])
        }, mockAssociateSoftwareTokenResponse: { input in
            return .init(secretCode: "sharedSecret", session: "newSession")
        })
        let options = AuthSignInRequest.Options()

        do {
            let result = try await plugin.signIn(
                username: "username",
                password: "password",
                options: options)
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

        self.mockIdentityProvider = MockIdentityProvider(mockInitiateAuthResponse: { _ in
            InitiateAuthOutputResponse(
                authenticationResult: .none,
                challengeName: .passwordVerifier,
                challengeParameters: InitiateAuthOutputResponse.validChalengeParams,
                session: "someSession")
        }, mockRespondToAuthChallengeResponse: { _ in
            RespondToAuthChallengeOutputResponse(
                authenticationResult: .none,
                challengeName: .mfaSetup,
                challengeParameters: ["MFAS_CAN_SETUP": "[\"SMS_MFA\"]"],
                session: "session")
        }, mockAssociateSoftwareTokenResponse: { _ in
            return .init(secretCode: "123456", session: "session")
        } )

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
        self.mockIdentityProvider = MockIdentityProvider(mockInitiateAuthResponse: { input in
            return InitiateAuthOutputResponse(
                authenticationResult: .none,
                challengeName: .passwordVerifier,
                challengeParameters: InitiateAuthOutputResponse.validChalengeParams,
            session: "someSession")
        }, mockRespondToAuthChallengeResponse: { input in
            return .testData(
                challenge: .mfaSetup,
                challengeParameters: [:])
        }, mockAssociateSoftwareTokenResponse: { input in
            return .init(secretCode: "sharedSecret", session: "newSession")
        })
        let options = AuthSignInRequest.Options()

        do {
            _ = try await plugin.signIn(
                username: "username",
                password: "password",
                options: options)
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

        self.mockIdentityProvider = MockIdentityProvider(mockInitiateAuthResponse: { input in
            return InitiateAuthOutputResponse(
                authenticationResult: .none,
                challengeName: .passwordVerifier,
                challengeParameters: InitiateAuthOutputResponse.validChalengeParams,
                session: "someSession")
        }, mockRespondToAuthChallengeResponse: { input in
            return .testData(
                challenge: .mfaSetup,
                challengeParameters: [:])
        }, mockAssociateSoftwareTokenResponse: { input in
            return .init()
        })
        let options = AuthSignInRequest.Options()

        do {
            _ = try await plugin.signIn(
                username: "username",
                password: "password",
                options: options)
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

        self.mockIdentityProvider = MockIdentityProvider(mockInitiateAuthResponse: { input in
            return InitiateAuthOutputResponse(
                authenticationResult: .none,
                challengeName: .passwordVerifier,
                challengeParameters: InitiateAuthOutputResponse.validChalengeParams,
                session: "someSession")
        }, mockRespondToAuthChallengeResponse: { input in
            return .testData(
                challenge: .mfaSetup,
                challengeParameters: ["MFAS_CAN_SETUP": "[\"SMS_MFA\",\"SOFTWARE_TOKEN_MFA\"]"])
        }, mockAssociateSoftwareTokenResponse: { input in
            return .init()
        })
        let options = AuthSignInRequest.Options()
        do {
            let result = try await plugin.signIn(username: "username", password: "password", options: options)
            XCTFail("Should not receive a success response \(result)")
        } catch {
            self.mockIdentityProvider = MockIdentityProvider(mockInitiateAuthResponse: { input in
                return InitiateAuthOutputResponse(
                    authenticationResult: .none,
                    challengeName: .passwordVerifier,
                    challengeParameters: InitiateAuthOutputResponse.validChalengeParams,
                    session: "someSession")
            }, mockRespondToAuthChallengeResponse: { input in
                return .testData(
                    challenge: .mfaSetup,
                    challengeParameters: ["MFAS_CAN_SETUP": "[\"SMS_MFA\",\"SOFTWARE_TOKEN_MFA\"]"])
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

        self.mockIdentityProvider = MockIdentityProvider(mockInitiateAuthResponse: { input in
            return InitiateAuthOutputResponse(
                authenticationResult: .none,
                challengeName: .passwordVerifier,
                challengeParameters: InitiateAuthOutputResponse.validChalengeParams,
                session: "someSession")
        }, mockRespondToAuthChallengeResponse: { input in
            return .testData(
                challenge: .mfaSetup,
                challengeParameters: ["MFAS_CAN_SETUP": "[\"SMS_MFA\",\"SOFTWARE_TOKEN_MFA\"]"])
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

        self.mockIdentityProvider = MockIdentityProvider(mockInitiateAuthResponse: { input in
            return InitiateAuthOutputResponse(
                authenticationResult: .none,
                challengeName: .passwordVerifier,
                challengeParameters: InitiateAuthOutputResponse.validChalengeParams,
                session: "someSession")
        }, mockRespondToAuthChallengeResponse: { input in
            return .testData(
                challenge: .mfaSetup,
                challengeParameters: ["MFAS_CAN_SETUP": "[\"SMS_MFA\",\"SOFTWARE_TOKEN_MFA\"]"])
        }, mockAssociateSoftwareTokenResponse: { input in
            throw AWSCognitoIdentityProvider.InvalidParameterException()
        })

        let options = AuthSignInRequest.Options()
        do {
            let result = try await plugin.signIn(username: "username", password: "password", options: options)
            XCTFail("Should not produce result - \(result)")
        } catch {
            guard case AuthError.service(_, _, let underlyingError) = error,
                  case .invalidParameter = (underlyingError as? AWSCognitoAuthError) else {
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

        self.mockIdentityProvider = MockIdentityProvider(mockInitiateAuthResponse: { input in
            return InitiateAuthOutputResponse(
                authenticationResult: .none,
                challengeName: .passwordVerifier,
                challengeParameters: InitiateAuthOutputResponse.validChalengeParams,
                session: "someSession")
        }, mockRespondToAuthChallengeResponse: { input in
            return .testData(
                challenge: .mfaSetup,
                challengeParameters: ["MFAS_CAN_SETUP": "[\"SMS_MFA\",\"SOFTWARE_TOKEN_MFA\"]"])
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

        self.mockIdentityProvider = MockIdentityProvider(mockInitiateAuthResponse: { input in
            return InitiateAuthOutputResponse(
                authenticationResult: .none,
                challengeName: .passwordVerifier,
                challengeParameters: InitiateAuthOutputResponse.validChalengeParams,
                session: "someSession")
        }, mockRespondToAuthChallengeResponse: { input in
            return .testData(
                challenge: .mfaSetup,
                challengeParameters: ["MFAS_CAN_SETUP": "[\"SMS_MFA\",\"SOFTWARE_TOKEN_MFA\"]"])
        }, mockAssociateSoftwareTokenResponse: { input in
            throw AWSCognitoIdentityProvider.ResourceNotFoundException()
        })

        let options = AuthSignInRequest.Options()
        do {
            let result = try await plugin.signIn(username: "username", password: "password", options: options)
            XCTFail("Should not produce result - \(result)")
        } catch {
            guard case AuthError.service(_, _, let underlyingError) = error,
                  case .resourceNotFound = (underlyingError as? AWSCognitoAuthError) else {
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

        self.mockIdentityProvider = MockIdentityProvider(mockInitiateAuthResponse: { input in
            return InitiateAuthOutputResponse(
                authenticationResult: .none,
                challengeName: .passwordVerifier,
                challengeParameters: InitiateAuthOutputResponse.validChalengeParams,
                session: "someSession")
        }, mockRespondToAuthChallengeResponse: { input in
            return .testData(
                challenge: .mfaSetup,
                challengeParameters: ["MFAS_CAN_SETUP": "[\"SMS_MFA\",\"SOFTWARE_TOKEN_MFA\"]"])
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

        self.mockIdentityProvider = MockIdentityProvider(mockInitiateAuthResponse: { input in
            return InitiateAuthOutputResponse(
                authenticationResult: .none,
                challengeName: .passwordVerifier,
                challengeParameters: InitiateAuthOutputResponse.validChalengeParams,
                session: "someSession")
        }, mockRespondToAuthChallengeResponse: { input in
            return .testData(
                challenge: .mfaSetup,
                challengeParameters: ["MFAS_CAN_SETUP": "[\"SMS_MFA\",\"SOFTWARE_TOKEN_MFA\"]"])
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

        self.mockIdentityProvider = MockIdentityProvider(mockInitiateAuthResponse: { input in
            return InitiateAuthOutputResponse(
                authenticationResult: .none,
                challengeName: .passwordVerifier,
                challengeParameters: InitiateAuthOutputResponse.validChalengeParams,
                session: "someSession")
        }, mockRespondToAuthChallengeResponse: { input in
            return .testData(
                challenge: .mfaSetup,
                challengeParameters: ["MFAS_CAN_SETUP": "[\"SMS_MFA\",\"SOFTWARE_TOKEN_MFA\"]"])
        }, mockAssociateSoftwareTokenResponse: { input in
            throw AWSCognitoIdentityProvider.SoftwareTokenMFANotFoundException()
        })

        let options = AuthSignInRequest.Options()
        do {
            let result = try await plugin.signIn(username: "username", password: "password", options: options)
            XCTFail("Should not produce result - \(result)")
        } catch {
            guard case AuthError.service(_, _, let underlyingError) = error,
                  case .softwareTokenMFANotEnabled = (underlyingError as? AWSCognitoAuthError) else {
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

        self.mockIdentityProvider = MockIdentityProvider(mockInitiateAuthResponse: { input in
            return InitiateAuthOutputResponse(
                authenticationResult: .none,
                challengeName: .passwordVerifier,
                challengeParameters: InitiateAuthOutputResponse.validChalengeParams,
                session: "someSession")
        }, mockRespondToAuthChallengeResponse: { input in
            return .testData(
                challenge: .mfaSetup,
                challengeParameters: ["MFAS_CAN_SETUP": "[\"SMS_MFA\",\"SOFTWARE_TOKEN_MFA\"]"])
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
}
