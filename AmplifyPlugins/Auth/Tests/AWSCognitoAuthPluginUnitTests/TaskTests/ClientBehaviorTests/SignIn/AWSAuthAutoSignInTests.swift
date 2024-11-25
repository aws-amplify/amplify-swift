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
@_spi(UnknownAWSHTTPServiceError) import AWSClientRuntime

class AWSAuthAutoSignInTests: BasePluginTest {
    
    override var initialState: AuthState {
        AuthState.configured(
            .signedOut(.init(lastKnownUserName: nil)),
            .configured,
            .signedUp(
                .init(username: "jeffb", session: "session"),
                .init(.completeAutoSignIn("session"))))
    }
    
    /// Test successful auto sign in
    ///
    /// - Given: Given an auth plugin with mocked service and in signed up state
    ///
    /// - When:
    ///    - I invoke autoSignIn
    /// - Then:
    ///    - I should get a successful result with tokens
    ///
    func testSuccessfulAutoSignIn() async {
        self.mockIdentityProvider = MockIdentityProvider(mockInitiateAuthResponse: { input in
            return InitiateAuthOutput(
                authenticationResult: .init(
                    accessToken: Defaults.validAccessToken,
                    expiresIn: 300,
                    idToken: "idToken",
                    newDeviceMetadata: nil,
                    refreshToken: "refreshToken",
                    tokenType: ""))
        })
        
        do {
            let result = try await plugin.autoSignIn()
            guard case .done = result.nextStep else {
                XCTFail("Result should be .done for next step")
                return
            }
            XCTAssertTrue(result.isSignedIn, "Signin result should be complete")
        } catch {
            XCTFail("Received failure with error \(error)")
        }
    }
    
    /// Test auto sign in success
    ///
    /// - Given: Given an auth plugin with mocked service and in `.signingIn` authentication state and
    /// `.signedUp` sign up state
    ///
    /// - When:
    ///    - I invoke autoSignIn
    /// - Then:
    ///    - I should get a successful result with tokens
    ///
    func testAutoSignInSuccessFromSigningInAuthenticationState() async {
        let mockIdentityProvider = MockIdentityProvider(
            mockSignUpResponse: { _ in
                return .init(
                    codeDeliveryDetails: .init(
                        attributeName: "some attribute",
                        deliveryMedium: .email,
                        destination: "jeffb@amazon.com"
                    ),
                    userConfirmed: false,
                    userSub: "userSub"
                )
            },
            mockInitiateAuthResponse: { input in
                return InitiateAuthOutput(
                    authenticationResult: .init(
                        accessToken: Defaults.validAccessToken,
                        expiresIn: 300,
                        idToken: "idToken",
                        newDeviceMetadata: nil,
                        refreshToken: "refreshToken",
                        tokenType: ""))
            },
            mockConfirmSignUpResponse: { request in
                XCTAssertNil(request.clientMetadata)
                XCTAssertNil(request.forceAliasCreation)
                return .init(session: "session")
            }
        )
        
        let initialStateSigningIn = AuthState.configured(
            .signingIn(.resolvingChallenge(
                .waitingForAnswer(
                    .init(
                        challenge: .emailOtp,
                        availableChallenges: [.emailOtp],
                        username: "jeffb",
                        session: nil,
                        parameters: nil),
                    .apiBased(.userAuth),
                    .confirmSignInWithOTP(.init(destination: .email("jeffb@amazon.com")))),
                .emailOTP,
                .apiBased(.userAuth))),
            .configured,
            .signedUp(
                .init(username: "jeffb", session: "session"),
                .init(.completeAutoSignIn("session"))))
        
        let authPluginSigningIn = configureCustomPluginWith(userPool: { mockIdentityProvider },
                                                        initialState: initialStateSigningIn)
        
        do {
            let result = try await authPluginSigningIn.autoSignIn()
            guard case .done = result.nextStep else {
                XCTFail("Result should be .done for next step")
                return
            }
            XCTAssertTrue(result.isSignedIn, "Signin result should be complete")
        } catch {
            XCTFail("Received failure with error \(error)")
        }
    }
    
    /// Test auto sign in failure
    ///
    /// - Given: Given an auth plugin with mocked service and in `.notStarted` sign up state
    ///
    /// - When:
    ///    - I invoke autoSignIn
    /// - Then:
    ///    - I should get a failure with error response
    ///
    func testAutoSignInFailureFromNotStartedState() async {
        let mockIdentityProvider = MockIdentityProvider(
            mockSignUpResponse: { _ in
                return .init(
                    codeDeliveryDetails: .init(
                        attributeName: "some attribute",
                        deliveryMedium: .email,
                        destination: ""
                    ),
                    userConfirmed: false,
                    userSub: "userSub"
                )
            },
            mockInitiateAuthResponse: { input in
                return InitiateAuthOutput(
                    authenticationResult: .init(
                        accessToken: Defaults.validAccessToken,
                        expiresIn: 300,
                        idToken: "idToken",
                        newDeviceMetadata: nil,
                        refreshToken: "refreshToken",
                        tokenType: ""))
            },
            mockConfirmSignUpResponse: { request in
                XCTAssertNil(request.clientMetadata)
                XCTAssertNil(request.forceAliasCreation)
                return .init(session: "session")
            }
        )

        let initialStateNotStarted = AuthState.configured(
            .signedOut(.init(lastKnownUserName: nil)),
            .configured,
            .notStarted)
        
        
        let authPluginNotStarted = configureCustomPluginWith(userPool: { mockIdentityProvider },
                                                             initialState: initialStateNotStarted)
        do {
            let _ = try await authPluginNotStarted.autoSignIn()
            XCTFail("Auto sign in should not be successful from .notStarted state")
        } catch {
            XCTAssertNotNil(error)
        }
    }
    
    /// Test auto sign in failure
    ///
    /// - Given: Given an auth plugin with mocked service and in `.initiatingSignUp` sign up state
    ///
    /// - When:
    ///    - I invoke autoSignIn
    /// - Then:
    ///    - I should get a failure with error response
    ///
    func testAutoSignInFailureFromInitiatingSignUpState() async {
        let mockIdentityProvider = MockIdentityProvider(
            mockSignUpResponse: { _ in
                return .init(
                    codeDeliveryDetails: .init(
                        attributeName: "some attribute",
                        deliveryMedium: .email,
                        destination: ""
                    ),
                    userConfirmed: false,
                    userSub: "userSub"
                )
            },
            mockInitiateAuthResponse: { input in
                return InitiateAuthOutput(
                    authenticationResult: .init(
                        accessToken: Defaults.validAccessToken,
                        expiresIn: 300,
                        idToken: "idToken",
                        newDeviceMetadata: nil,
                        refreshToken: "refreshToken",
                        tokenType: ""))
            },
            mockConfirmSignUpResponse: { request in
                XCTAssertNil(request.clientMetadata)
                XCTAssertNil(request.forceAliasCreation)
                return .init(session: "session")
            }
        )
        
        let initialStateInitiatingSignUp = AuthState.configured(
            .signedOut(.init(lastKnownUserName: nil)),
            .configured,
            .initiatingSignUp(.init(username: "user")))
        
        let authPluginInitiatingSignUp = configureCustomPluginWith(userPool: { mockIdentityProvider },
                                                                   initialState: initialStateInitiatingSignUp)
        
        do {
            let _ = try await authPluginInitiatingSignUp.autoSignIn()
            XCTFail("Auto sign in should not be successful from .initiatingSignUp state")
        } catch {
            XCTAssertNotNil(error)
        }
    }
    
    /// Test auto sign in failure
    ///
    /// - Given: Given an auth plugin with mocked service and in `.awaitingUserConfirmation` sign up state
    ///
    /// - When:
    ///    - I invoke autoSignIn
    /// - Then:
    ///    - I should get a failure with error response
    ///
    func testAutoSignInFailureFromAwaitingUserConfirmationState() async {
        let mockIdentityProvider = MockIdentityProvider(
            mockSignUpResponse: { _ in
                return .init(
                    codeDeliveryDetails: .init(
                        attributeName: "some attribute",
                        deliveryMedium: .email,
                        destination: ""
                    ),
                    userConfirmed: false,
                    userSub: "userSub"
                )
            },
            mockInitiateAuthResponse: { input in
                return InitiateAuthOutput(
                    authenticationResult: .init(
                        accessToken: Defaults.validAccessToken,
                        expiresIn: 300,
                        idToken: "idToken",
                        newDeviceMetadata: nil,
                        refreshToken: "refreshToken",
                        tokenType: ""))
            },
            mockConfirmSignUpResponse: { request in
                XCTAssertNil(request.clientMetadata)
                XCTAssertNil(request.forceAliasCreation)
                return .init(session: "session")
            }
        )
        
        let initialStateAwaitingUserConfirmation = AuthState.configured(
            .signedOut(.init(lastKnownUserName: nil)),
            .configured,
            .awaitingUserConfirmation(.init(username: "user"), .init(.completeAutoSignIn("session"))))
        
        let authPluginAwaitingUserConfirmation = configureCustomPluginWith(userPool: { mockIdentityProvider },
                                                                           initialState: initialStateAwaitingUserConfirmation)
        
        do {
            let _ = try await authPluginAwaitingUserConfirmation.autoSignIn()
            XCTFail("Auto sign in should not be successful from .awaitingUserConfirmation state")
        } catch {
            XCTAssertNotNil(error)
        }
    }
    
    /// Test auto sign in failure
    ///
    /// - Given: Given an auth plugin with mocked service and in `.confirmingSignUp` sign up state
    ///
    /// - When:
    ///    - I invoke autoSignIn
    /// - Then:
    ///    - I should get a failure with error response
    ///
    func testAutoSignInFailureFromConfirmingSignUpState() async {
        let mockIdentityProvider = MockIdentityProvider(
            mockSignUpResponse: { _ in
                return .init(
                    codeDeliveryDetails: .init(
                        attributeName: "some attribute",
                        deliveryMedium: .email,
                        destination: ""
                    ),
                    userConfirmed: false,
                    userSub: "userSub"
                )
            },
            mockInitiateAuthResponse: { input in
                return InitiateAuthOutput(
                    authenticationResult: .init(
                        accessToken: Defaults.validAccessToken,
                        expiresIn: 300,
                        idToken: "idToken",
                        newDeviceMetadata: nil,
                        refreshToken: "refreshToken",
                        tokenType: ""))
            },
            mockConfirmSignUpResponse: { request in
                XCTAssertNil(request.clientMetadata)
                XCTAssertNil(request.forceAliasCreation)
                return .init(session: "session")
            }
        )
        
        let initialStateConfirmingSignUp = AuthState.configured(
            .signedOut(.init(lastKnownUserName: nil)),
            .configured,
            .confirmingSignUp(.init(username: "user")))
        
        let authPluginConfirmingSignUp = configureCustomPluginWith(userPool: { mockIdentityProvider },
                                                                   initialState: initialStateConfirmingSignUp)
        
        do {
            let _ = try await authPluginConfirmingSignUp.autoSignIn()
            XCTFail("Auto sign in should not be successful from .confirmingSignUp state")
        } catch {
            XCTAssertNotNil(error)
        }
    }
    
    /// Test auto sign in failure
    ///
    /// - Given: Given an auth plugin with mocked service and in `.error` sign up state
    ///
    /// - When:
    ///    - I invoke autoSignIn
    /// - Then:
    ///    - I should get a failure with error response
    ///
    func testAutoSignInFailureFromErrorState() async {
        let mockIdentityProvider = MockIdentityProvider(
            mockSignUpResponse: { _ in
                return .init(
                    codeDeliveryDetails: .init(
                        attributeName: "some attribute",
                        deliveryMedium: .email,
                        destination: ""
                    ),
                    userConfirmed: false,
                    userSub: "userSub"
                )
            },
            mockInitiateAuthResponse: { input in
                return InitiateAuthOutput(
                    authenticationResult: .init(
                        accessToken: Defaults.validAccessToken,
                        expiresIn: 300,
                        idToken: "idToken",
                        newDeviceMetadata: nil,
                        refreshToken: "refreshToken",
                        tokenType: ""))
            },
            mockConfirmSignUpResponse: { request in
                XCTAssertNil(request.clientMetadata)
                XCTAssertNil(request.forceAliasCreation)
                return .init(session: "session")
            }
        )
        
        let initialStateError = AuthState.configured(
            .signedOut(.init(lastKnownUserName: nil)),
            .configured,
            .error(.service(error: AuthError.service("Unknown error", "Unknown error"))))
        
        let authPluginError = configureCustomPluginWith(userPool: { mockIdentityProvider },
                                                        initialState: initialStateError)
        
        do {
            let _ = try await authPluginError.autoSignIn()
            XCTFail("Auto sign in should not be successful from .error state")
        } catch {
            XCTAssertNotNil(error)
        }
    }
    
    // MARK: - Service error for initiateAuth
    
    /// Test a autoSignIn with an `InternalErrorException` from service
    ///
    /// - Given: Given an auth plugin with mocked service. Mocked service should mock an
    ///   InternalErrorException response for autoSignIn
    ///
    /// - When:
    ///    - I invoke autoSignIn
    /// - Then:
    ///    - I should get an error of .service type
    ///
    func testAutoSignInWithInternalErrorException() async {

        self.mockIdentityProvider = MockIdentityProvider(mockInitiateAuthResponse: { _ in
            throw AWSCognitoIdentityProvider.InternalErrorException()
        })

        do {
            let result = try await plugin.autoSignIn()
            XCTFail("Should not produce result - \(result)")
        } catch {
            guard case AuthError.unknown = error else {
                XCTFail("Should produce unknown error")
                return
            }
        }
    }

    /// Test a autoSignIn with `InvalidLambdaResponseException` from service
    ///
    /// - Given: Given an auth plugin with mocked service. Mocked service should mock a
    ///   InvalidLambdaResponseException response for autoSignIn
    ///
    /// - When:
    ///    - I invoke autoSignIn
    /// - Then:
    ///    - I should get a .service error with .lambda error
    ///
    func testSignInWithInvalidLambdaResponseException() async {

        self.mockIdentityProvider = MockIdentityProvider(mockInitiateAuthResponse: { _ in
            throw AWSCognitoIdentityProvider.InvalidLambdaResponseException()
        })

        do {
            let result = try await plugin.autoSignIn()
            XCTFail("Should not produce result - \(result)")
        } catch {
            guard case AuthError.service(_, _, let underlyingError) = error,
                  case .lambda = (underlyingError as? AWSCognitoAuthError) else {
                XCTFail("Should produce lambda error but instead produced \(error)")
                return
            }
        }
    }

    /// Test a autoSignIn with `InvalidParameterException` from service
    ///
    /// - Given: Given an auth plugin with mocked service. Mocked service should mock a
    ///   InvalidParameterException response for autoSignIn
    ///
    /// - When:
    ///    - I invoke autoSignIn
    /// - Then:
    ///    - I should get a .service error with .invalidParameter error
    ///
    func testSignInWithInvalidParameterException() async {

        self.mockIdentityProvider = MockIdentityProvider(mockInitiateAuthResponse: { _ in
            throw AWSCognitoIdentityProvider.InvalidParameterException()
        })

        do {
            let result = try await plugin.autoSignIn()
            XCTFail("Should not produce result - \(result)")
        } catch {
            guard case AuthError.service(_, _, let underlyingError) = error,
                  case .invalidParameter = (underlyingError as? AWSCognitoAuthError) else {
                XCTFail("Should produce invalidParameter error but instead produced \(error)")
                return
            }
        }
    }
    
    /// Test a autoSignIn with `InvalidUserPoolConfigurationException` from service
    ///
    /// - Given: Given an auth plugin with mocked service. Mocked service should mock a
    ///   InvalidUserPoolConfigurationException response for autoSignIn
    ///
    /// - When:
    ///    - I invoke autoSignIn
    /// - Then:
    ///    - I should get a .configuration error
    ///
    func testSignInWithInvalidUserPoolConfigurationException() async {

        self.mockIdentityProvider = MockIdentityProvider(mockInitiateAuthResponse: { _ in
            throw AWSCognitoIdentityProvider.InvalidUserPoolConfigurationException()
        })

        do {
            let result = try await plugin.autoSignIn()
            XCTFail("Should not produce result - \(result)")
        } catch {
            guard case AuthError.configuration = error else {
                XCTFail("Should produce configuration intead produced \(error)")
                return
            }
        }
    }
    
    /// Test a autoSignIn with `NotAuthorizedException` from service
    ///
    /// - Given: Given an auth plugin with mocked service. Mocked service should mock a
    ///   NotAuthorizedException response for autoSignIn
    ///
    /// - When:
    ///    - I invoke autoSignIn
    /// - Then:
    ///    - I should get a .notAuthorized error
    ///
    func testSignInWithNotAuthorizedException() async {

        self.mockIdentityProvider = MockIdentityProvider(mockInitiateAuthResponse: { _ in
            throw AWSCognitoIdentityProvider.NotAuthorizedException()
        })

        do {
            let result = try await plugin.autoSignIn()
            XCTFail("Should not produce result - \(result)")
        } catch {
            guard case AuthError.notAuthorized = error else {
                XCTFail("Should produce notAuthorized error but instead produced \(error)")
                return
            }
        }
    }
    
    /// Test a autoSignIn with `ResourceNotFoundException` from service
    ///
    /// - Given: Given an auth plugin with mocked service. Mocked service should mock a
    ///   ResourceNotFoundException response for autoSignIn
    ///
    /// - When:
    ///    - I invoke autoSignIn
    /// - Then:
    ///    - I should get a .service error with .resourceNotFound error
    ///
    func testSignInWithResourceNotFoundException() async {

        self.mockIdentityProvider = MockIdentityProvider(mockInitiateAuthResponse: { _ in
            throw AWSCognitoIdentityProvider.ResourceNotFoundException()
        })

        do {
            let result = try await plugin.autoSignIn()
            XCTFail("Should not produce result - \(result)")
        } catch {
            guard case AuthError.service(_, _, let underlyingError) = error,
                  case .resourceNotFound = (underlyingError as? AWSCognitoAuthError) else {
                XCTFail("Should produce resourceNotFound error but instead produced \(error)")
                return
            }
        }
    }

    /// Test a autoSignIn with `TooManyRequestsException` from service
    ///
    /// - Given: Given an auth plugin with mocked service. Mocked service should mock a
    ///   TooManyRequestsException response for autoSignIn
    ///
    /// - When:
    ///    - I invoke autoSignIn
    /// - Then:
    ///    - I should get a .service error with .requestLimitExceeded error
    ///
    func testSignInWithTooManyRequestsException() async {

        self.mockIdentityProvider = MockIdentityProvider(mockInitiateAuthResponse: { _ in
            throw AWSCognitoIdentityProvider.TooManyRequestsException()
        })

        do {
            let result = try await plugin.autoSignIn()
            XCTFail("Should not produce result - \(result)")
        } catch {
            guard case AuthError.service(_, _, let underlyingError) = error,
                  case .requestLimitExceeded = (underlyingError as? AWSCognitoAuthError) else {
                XCTFail("Should produce requestLimitExceeded error but instead produced \(error)")
                return
            }
        }
    }
    
    /// Test a autoSignIn with `UnexpectedLambdaException` from service
    ///
    /// - Given: Given an auth plugin with mocked service. Mocked service should mock a
    ///   UnexpectedLambdaException response for autoSignIn
    ///
    /// - When:
    ///    - I invoke autoSignIn
    /// - Then:
    ///    - I should get a .service error with .lambda error
    ///
    func testSignInWithUnexpectedLambdaException() async {

        self.mockIdentityProvider = MockIdentityProvider(mockInitiateAuthResponse: { _ in
            throw AWSCognitoIdentityProvider.UnexpectedLambdaException()
        })

        do {
            let result = try await plugin.autoSignIn()
            XCTFail("Should not produce result - \(result)")
        } catch {
            guard case AuthError.service(_, _, let underlyingError) = error,
                  case .lambda = (underlyingError as? AWSCognitoAuthError) else {
                XCTFail("Should produce lambda error but instead produced \(error)")
                return
            }
        }
    }

    /// Test a autoSignIn with `UserLambdaValidationException` from service
    ///
    /// - Given: Given an auth plugin with mocked service. Mocked service should mock a
    ///   UserLambdaValidationException response for autoSignIn
    ///
    /// - When:
    ///    - I invoke autoSignIn
    /// - Then:
    ///    - I should get a .service error with .lambda error
    ///
    func testSignInWithUserLambdaValidationException() async {

        self.mockIdentityProvider = MockIdentityProvider(mockInitiateAuthResponse: { _ in
            throw AWSCognitoIdentityProvider.UserLambdaValidationException()
        })

        do {
            let result = try await plugin.autoSignIn()
            XCTFail("Should not produce result - \(result)")
        } catch {
            guard case AuthError.service(_, _, let underlyingError) = error,
                  case .lambda = (underlyingError as? AWSCognitoAuthError) else {
                XCTFail("Should produce lambda error but instead produced \(error)")
                return
            }
        }
    }
}
