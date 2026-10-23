//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

import Amplify
import AWSCognitoIdentityProvider
import XCTest
@testable import AWSCognitoAuthPlugin
import InternalAWSCognitoAuth

// swiftlint:disable type_body_length
// swiftlint:disable file_length
class ConfirmSignInWithSetUpMFATaskTests: BasePluginTest, @unchecked Sendable {

    override var initialState: AuthState {
        AuthState.configured(
            AuthenticationState.signingIn(
                .resolvingTOTPSetup(
                    .waitingForAnswer(.init(
                        secretCode: "sharedSecret",
                        session: "session",
                        username: "username"
                    )),
                    .testData
                )),
            AuthorizationState.sessionEstablished(.testData),
            .notStarted
        )
    }

    /// Test a successful confirmSignIn call with .done as next step
    ///
    /// - Given: an auth plugin with mocked service. Mocked service calls should mock a successful response
    /// - When:
    ///    - I invoke confirmSignIn with a valid confirmation code
    /// - Then:
    ///    - I should get a successful result with .done as the next step
    ///
    func testSuccessfulTOTPMFASetupStep() async {

        mockIdentityProvider = MockIdentityProvider(
            mockRespondToAuthChallengeResponse: { request in
                XCTAssertEqual(request.session, "verifiedSession")
                return .testData()
            },
            mockVerifySoftwareTokenResponse: { request in
                XCTAssertEqual(request.session, "session")
                XCTAssertEqual(request.userCode, "123456")
                XCTAssertEqual(request.friendlyDeviceName, "device")
                return .init(session: "verifiedSession", status: .success)
            }
        )

        do {
            let pluginOptions = AWSAuthConfirmSignInOptions(friendlyDeviceName: "device")
            let confirmSignInResult = try await plugin.confirmSignIn(
                challengeResponse: "123456",
                options: .init(pluginOptions: pluginOptions)
            )
            guard case .done = confirmSignInResult.nextStep else {
                XCTFail("Result should be .done for next step")
                return
            }
            XCTAssertTrue(confirmSignInResult.isSignedIn, "Signin result should NOT be complete")
        } catch {
            XCTFail("Received failure with error \(error)")
        }
    }


    /// Test a confirmSignIn call with an empty confirmation code
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a successful response
    /// - When:
    ///    - I invoke confirmSignIn with an empty confirmation code
    /// - Then:
    ///    - I should get an .validation error
    ///
    func testConfirmSignInWithEmptyResponse() async {

        mockIdentityProvider = MockIdentityProvider(
            mockRespondToAuthChallengeResponse: { _ in
                XCTFail("Cognito service should not be called")
                return .testData()
            })

        do {
            _ = try await plugin.confirmSignIn(challengeResponse: "")
            XCTFail("Should not succeed")
        } catch {
            guard case AuthError.validation = error else {
                XCTFail("Should produce validation error instead of \(error)")
                return
            }
        }
    }

    /// Test a confirmSignIn call with an empty confirmation code followed by a second valid confirmSignIn call
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a successful response
    /// - When:
    ///    - I invoke second confirmSignIn after confirmSignIn with an empty confirmation code
    /// - Then:
    ///    - I should get a successful result with .done as the next step
    ///
    func testSuccessfullyConfirmSignInAfterAFailedConfirmSignIn() async {

        mockIdentityProvider = MockIdentityProvider(
            mockRespondToAuthChallengeResponse: { request in
                XCTAssertEqual(request.session, "verifiedSession")
                return .testData()
            },
            mockVerifySoftwareTokenResponse: { request in
                XCTAssertEqual(request.session, "session")
                XCTAssertEqual(request.userCode, "123456")
                return .init(session: "verifiedSession", status: .success)
            }
        )
        do {
            _ = try await plugin.confirmSignIn(challengeResponse: "")
            XCTFail("Should not succeed")
        } catch {
            guard case AuthError.validation = error else {
                XCTFail("Should produce validation error instead of \(error)")
                return
            }

            do {
                let confirmSignInResult = try await plugin.confirmSignIn(challengeResponse: "123456")
                guard case .done = confirmSignInResult.nextStep else {
                    XCTFail("Result should be .done for next step")
                    return
                }
                XCTAssertTrue(confirmSignInResult.isSignedIn, "Signin result should be complete")
            } catch {
                XCTFail("Received failure with error \(error)")
            }
        }
    }

    // MARK: Service error handling test

    /// Test a confirmSignIn call with CodeMismatchException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   CodeMismatchException response
    /// - When:
    ///    - I invoke confirmSignIn with a valid confirmation code
    /// - Then:
    ///    - I should get a .service error with .codeMismatch as underlyingError
    ///
    func testConfirmSignInWithCodeMismatchException() async {

        mockIdentityProvider = MockIdentityProvider(
            mockVerifySoftwareTokenResponse: { request in
                throw AWSCognitoIdentityProvider.CodeMismatchException(
                    message: "Exception"
                )
            }
        )

        do {
            _ = try await plugin.confirmSignIn(challengeResponse: "12345")
            XCTFail("Should return an error if the result from service is invalid")
        } catch {
            guard case AuthError.service(_, _, let underlyingError) = error else {
                XCTFail("Should produce service error instead of \(error)")
                return
            }
            guard case .codeMismatch = (underlyingError as? AWSCognitoAuthError) else {
                XCTFail("Underlying error should be codeMismatch \(error)")
                return
            }
        }
    }

    /// Test a confirmSignIn call with CodeMismatchException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   CodeMismatchException response
    /// - When:
    ///    - I invoke confirmSignIn with a valid confirmation code
    /// - Then:
    ///    - I should get a .service error with .codeMismatch as underlyingError
    ///   Then:
    ///    - RETRY SHOULD ALSO SUCCEED
    ///
    func testConfirmSignInRetryWithCodeMismatchException() async {
        mockIdentityProvider = MockIdentityProvider(
            mockVerifySoftwareTokenResponse: { request in
                throw AWSCognitoIdentityProvider.CodeMismatchException(
                    message: "Exception"
                )
            }
        )

        do {
            _ = try await plugin.confirmSignIn(challengeResponse: "123456")
            XCTFail("Should return an error if the result from service is invalid")
        } catch {
            guard case AuthError.service(_, _, let underlyingError) = error else {
                XCTFail("Should produce service error instead of \(error)")
                return
            }
            guard case .codeMismatch = (underlyingError as? AWSCognitoAuthError) else {
                XCTFail("Underlying error should be codeMismatch \(error)")
                return
            }

            mockIdentityProvider = MockIdentityProvider(
                mockRespondToAuthChallengeResponse: { request in
                    XCTAssertEqual(request.session, "verifiedSession")
                    return .testData()
                },
                mockVerifySoftwareTokenResponse: { request in
                    XCTAssertEqual(request.session, "session")
                    XCTAssertEqual(request.userCode, "123456")
                    return .init(session: "verifiedSession", status: .success)
                }
            )
            do {
                let confirmSignInResult = try await plugin.confirmSignIn(challengeResponse: "123456")
                XCTAssertTrue(confirmSignInResult.isSignedIn, "Signin result should be complete")
            } catch {
                XCTFail("Received failure with error \(error)")
            }

        }
    }

    /// Test a confirmSignIn call with InternalErrorException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a InternalErrorException response
    /// - When:
    ///    - I invoke confirmSignIn with a valid confirmation code
    /// - Then:
    ///    - I should get an .unknown error
    ///
    func testConfirmSignInWithInternalErrorException() async {

        mockIdentityProvider = MockIdentityProvider(
            mockVerifySoftwareTokenResponse: { request in
                throw AWSCognitoIdentityProvider.InternalErrorException(
                    message: "Exception"
                )
            }
        )

        do {
            _ = try await plugin.confirmSignIn(challengeResponse: "123456")
            XCTFail("Should return an error if the result from service is invalid")
        } catch {
            guard case AuthError.unknown = error else {
                XCTFail("Should produce an unknown error instead of \(error)")
                return
            }
        }
    }

    /// Test a confirmSignIn call with InvalidParameterException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   InvalidParameterException response
    ///
    /// - When:
    ///    - I invoke confirmSignIn with a valid confirmation code
    /// - Then:
    ///    - I should get a .service error with  .invalidParameter as underlyingError
    ///
    func testConfirmSignInWithInvalidParameterException() async {

        mockIdentityProvider = MockIdentityProvider(
            mockVerifySoftwareTokenResponse: { request in
                throw AWSCognitoIdentityProvider.InvalidParameterException(
                    message: "Exception"
                )
            })

        do {
            _ = try await plugin.confirmSignIn(challengeResponse: MFAType.totp.challengeResponse)
            XCTFail("Should return an error if the result from service is invalid")
        } catch {
            guard case AuthError.service(_, _, let underlyingError) = error else {
                XCTFail("Should produce service error instead of \(error)")
                return
            }
            guard case .invalidParameter = (underlyingError as? AWSCognitoAuthError) else {
                XCTFail("Underlying error should be invalidParameter \(error)")
                return
            }
        }
    }

    /// Test a confirmSignIn with User pool configuration from service
    ///
    /// - Given: an auth plugin with mocked service with no User Pool configuration
    ///
    /// - When:
    ///    - I invoke confirmSignIn with a valid confirmation code
    /// - Then:
    ///    - I should get a .configuration error
    ///
    func testConfirmSignInWithInvalidUserPoolConfigurationException() async {
        let identityPoolConfigData = Defaults.makeIdentityConfigData()
        let authorizationEnvironment = BasicAuthorizationEnvironment(
            identityPoolConfiguration: identityPoolConfigData,
            cognitoIdentityFactory: Defaults.makeIdentity
        )
        let environment = AuthEnvironment(
            configuration: .identityPools(identityPoolConfigData),
            userPoolConfigData: nil,
            identityPoolConfigData: identityPoolConfigData,
            authenticationEnvironment: nil,
            authorizationEnvironment: authorizationEnvironment,
            credentialsClient: Defaults.makeCredentialStoreOperationBehavior(),
            logger: AmplifyEngineLogRouter(scope: .category("awsCognitoAuthPluginTest"))
        )
        let stateMachine = Defaults.authStateMachineWith(
            environment: environment,
            initialState: .notConfigured
        )
        let plugin = AWSCognitoAuthPlugin()
        plugin.configure(
            authConfiguration: .identityPools(identityPoolConfigData),
            authEnvironment: environment,
            authStateMachine: stateMachine,
            credentialStoreStateMachine: Defaults.makeDefaultCredentialStateMachine(),
            hubEventHandler: MockAuthHubEventBehavior(),
            analyticsHandler: MockAnalyticsHandler()
        )
        settleConfigureOperationOnTeardown(of: plugin)

        do {
            _ = try await plugin.confirmSignIn(challengeResponse: "")
            XCTFail("Should return an error if the result from service is invalid")
        } catch {
            guard case AuthError.configuration(_, _, _) = error else {
                XCTFail("Should produce configuration instead produced \(error)")
                return
            }
        }

    }

    /// Test a confirmSignIn call with NotAuthorizedException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   NotAuthorizedException response
    ///
    /// - When:
    ///    - I invoke confirmSignIn with a valid confirmation code
    /// - Then:
    ///    - I should get a .notAuthorized error
    ///
    func testConfirmSignInWithNotAuthorizedException() async {

        mockIdentityProvider = MockIdentityProvider(
            mockVerifySoftwareTokenResponse: { request in
                throw AWSCognitoIdentityProvider.NotAuthorizedException(
                    message: "Exception"
                )
            })

        do {
            _ = try await plugin.confirmSignIn(challengeResponse: "123456")
            XCTFail("Should return an error if the result from service is invalid")
        } catch {
            guard case AuthError.notAuthorized = error else {
                XCTFail("Should produce notAuthorized error instead of \(error)")
                return
            }
        }
    }

    /// Test a confirmSignIn with PasswordResetRequiredException from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   PasswordResetRequiredException response
    ///
    /// - When:
    ///    - I invoke confirmSignIn with a valid confirmation code
    /// - Then:
    ///    - I should get a .resetPassword as next step
    ///
    func testConfirmSignInWithPasswordResetRequiredException() async {

        mockIdentityProvider = MockIdentityProvider(
            mockVerifySoftwareTokenResponse: { request in
                throw AWSCognitoIdentityProvider.PasswordResetRequiredException(
                    message: "Exception"
                )
            })

        do {
            let confirmSignInResult = try await plugin.confirmSignIn(challengeResponse: "123456")
            guard case .resetPassword = confirmSignInResult.nextStep else {
                XCTFail("Result should be .resetPassword for next step")
                return
            }
        } catch {
            XCTFail("Should not return error \(error)")
        }
    }


    /// Test a confirmSignIn call with SoftwareTokenMFANotFoundException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   SoftwareTokenMFANotFoundException response
    ///
    /// - When:
    ///    - I invoke confirmSignIn with a valid confirmation code
    /// - Then:
    ///    - I should get a .service error with .softwareTokenMFANotEnabled as underlyingError
    ///
    func testConfirmSignInWithSoftwareTokenMFANotFoundException() async {

        mockIdentityProvider = MockIdentityProvider(
            mockVerifySoftwareTokenResponse: { request in
                throw AWSCognitoIdentityProvider.SoftwareTokenMFANotFoundException(
                    message: "Exception"
                )
            })

        do {
            _ = try await plugin.confirmSignIn(challengeResponse: "1")
            XCTFail("Should return an error if the result from service is invalid")
        } catch {
            guard case AuthError.service(_, _, let underlyingError) = error else {
                XCTFail("Should produce service error instead of \(error)")
                return
            }
            guard case .softwareTokenMFANotEnabled = (underlyingError as? AWSCognitoAuthError) else {
                XCTFail("Underlying error should be softwareTokenMFANotEnabled \(error)")
                return
            }
        }
    }

    /// Test a confirmSignIn call with TooManyRequestsException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   TooManyRequestsException response
    ///
    /// - When:
    ///    - I invoke confirmSignIn with a valid confirmation code
    /// - Then:
    ///    - I should get a .service error with .requestLimitExceeded as underlyingError
    ///
    func testConfirmSignInWithTooManyRequestsException() async {

        mockIdentityProvider = MockIdentityProvider(
            mockVerifySoftwareTokenResponse: { request in
                throw AWSCognitoIdentityProvider.TooManyRequestsException(
                    message: "Exception"
                )
            })

        do {
            _ = try await plugin.confirmSignIn(challengeResponse: "1")
            XCTFail("Should return an error if the result from service is invalid")
        } catch {
            guard case AuthError.service(_, _, let underlyingError) = error else {
                XCTFail("Should produce service error instead of \(error)")
                return
            }
            guard case .requestLimitExceeded = (underlyingError as? AWSCognitoAuthError) else {
                XCTFail("Underlying error should be requestLimitExceeded \(error)")
                return
            }
        }
    }

    /// Test a confirmSignIn call with UserNotConfirmedException response from service
    ///
    /// - Given: Given an auth plugin with mocked service. Mocked service should mock a
    ///   UserNotConfirmedException response
    ///
    /// - When:
    ///    - I invoke confirmSignIn with a valid confirmation code
    /// - Then:
    ///    - I should get .confirmSignUp as next step
    ///
    func testConfirmSignInWithUserNotConfirmedException() async {

        mockIdentityProvider = MockIdentityProvider(
            mockVerifySoftwareTokenResponse: { request in
                throw AWSCognitoIdentityProvider.UserNotConfirmedException(
                    message: "Exception"
                )
            })

        do {
            let confirmSignInResult = try await plugin.confirmSignIn(challengeResponse: "1")
            guard case .confirmSignUp = confirmSignInResult.nextStep else {
                XCTFail("Result should be .confirmSignUp for next step")
                return
            }
        } catch {
            XCTFail("Should not return error \(error)")
        }
    }

    /// Test a confirmSignIn call with UserNotFound response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   UserNotFoundException response
    ///
    /// - When:
    ///    - I invoke confirmSignIn with a valid confirmation code
    /// - Then:
    ///    - I should get a .userNotFound error
    ///
    func testConfirmSignInWithUserNotFoundException() async {

        mockIdentityProvider = MockIdentityProvider(
            mockVerifySoftwareTokenResponse: { request in
                throw AWSCognitoIdentityProvider.UserNotFoundException(
                    message: "Exception"
                )
            })

        do {
            _ = try await plugin.confirmSignIn(challengeResponse: "1")
            XCTFail("Should return an error if the result from service is invalid")
        } catch {
            guard case AuthError.service(_, _, let underlyingError) = error else {
                XCTFail("Should produce service error instead of \(error)")
                return
            }
            guard case .userNotFound = (underlyingError as? AWSCognitoAuthError) else {
                XCTFail("Underlying error should be userNotFound \(error)")
                return
            }
        }
    }

    /// A confirmSignIn whose TOTP setup's last call fails throws, instead of never returning. A retried
    /// confirmSignIn is refused, and a new signIn works.
    ///
    /// - Given: an auth plugin with mocked service. `VerifySoftwareToken` accepts the code, the setup's
    ///   `RespondToAuthChallenge` fails with `UserLambdaValidationException`, and `InitiateAuth` answers tokens
    /// - When:
    ///    - I invoke confirmSignIn with a valid confirmation code, then again, then signIn with `.userPassword`
    /// - Then:
    ///    - the first confirmSignIn throws a `.service` error with `.lambda` as underlyingError
    ///    - the second throws `.invalidState`
    ///    - signIn finishes `.done`
    ///    - each within the bound
    ///
    func testConfirmSignInWithAFailedSetupAnswerThrows() async {
        mockIdentityProvider = MockIdentityProvider(
            mockInitiateAuthResponse: { _ in
                return .init(authenticationResult: .init(
                    accessToken: Defaults.validAccessToken,
                    expiresIn: 300,
                    idToken: "idToken",
                    refreshToken: "refreshToken"
                ))
            },
            mockRespondToAuthChallengeResponse: { _ in
                throw AWSCognitoIdentityProvider.UserLambdaValidationException(
                    message: "PostAuthentication failed with error unavailable."
                )
            },
            mockVerifySoftwareTokenResponse: { _ in
                return .init(session: "verifiedSession", status: .success)
            }
        )
        let confirmed = expectation(description: "confirmSignIn returns")
        let retried = expectation(description: "the retried confirmSignIn returns")
        let signedIn = expectation(description: "signIn returns")

        Task {
            do {
                let result = try await self.plugin.confirmSignIn(challengeResponse: "123456")
                XCTFail("Should not succeed, got \(result)")
            } catch {
                guard case AuthError.service(_, _, let underlyingError) = error,
                      case .lambda = (underlyingError as? AWSCognitoAuthError) else {
                    XCTFail("Should produce a .service error with .lambda instead of \(error)")
                    return
                }
            }
            confirmed.fulfill()
            do {
                let result = try await self.plugin.confirmSignIn(challengeResponse: "123456")
                XCTFail("Should not succeed, got \(result)")
            } catch {
                guard case AuthError.invalidState = error else {
                    XCTFail("Should produce an invalidState error instead of \(error)")
                    return
                }
            }
            retried.fulfill()
            do {
                let pluginOptions = AWSAuthSignInOptions(authFlowType: .userPassword)
                let result = try await self.plugin.signIn(
                    username: "username",
                    password: "password",
                    options: AuthSignInRequest.Options(pluginOptions: pluginOptions)
                )
                guard case .done = result.nextStep else {
                    XCTFail("Result should be .done for next step, got \(result.nextStep)")
                    return
                }
            } catch {
                XCTFail("Received failure with error \(error)")
                return
            }
            signedIn.fulfill()
        }

        await fulfillment(of: [confirmed, retried, signedIn], timeout: 5, enforceOrder: true)
    }
}
