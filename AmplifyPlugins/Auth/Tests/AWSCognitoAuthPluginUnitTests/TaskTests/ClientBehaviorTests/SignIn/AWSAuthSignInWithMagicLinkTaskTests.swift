//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0

import XCTest
import AWSCognitoIdentity
@testable import Amplify
@testable import AWSCognitoAuthPlugin
import AWSCognitoIdentityProvider
import ClientRuntime

class AWSAuthSignInWithMagicLinkTaskTests: BasePluginTest {

    let username = "username"
    let redirectURL = "https://example.com/magic-link/##code##"

    override var initialState: AuthState {
        AuthState.configured(.signedOut(.init(lastKnownUserName: nil)), .configured)
    }
    
    override func setUp() {
        plugin = AWSCognitoAuthPlugin()
    }

    private func setUpWith(
        authPasswordlessEnvironment: AuthPasswordlessEnvironment? = nil,
        authConfiguration: AuthConfiguration = Defaults.makeDefaultAuthConfigData()) {
            let environment = Defaults.makeDefaultAuthEnvironment(
                identityPoolFactory: { self.mockIdentity },
                userPoolFactory: { self.mockIdentityProvider },
                authPasswordlessEnvironment: authPasswordlessEnvironment
            )

            let statemachine = Defaults.makeDefaultAuthStateMachine(
                initialState: initialState,
                identityPoolFactory: { self.mockIdentity },
                userPoolFactory: { self.mockIdentityProvider })

            plugin?.configure(
                authConfiguration: authConfiguration,
                authEnvironment: environment,
                authStateMachine: statemachine,
                credentialStoreStateMachine: Defaults.makeDefaultCredentialStateMachine(),
                hubEventHandler: MockAuthHubEventBehavior(),
                analyticsHandler: MockAnalyticsHandler())
        }

    private func makeAuthPasswordlessClient() -> AuthPasswordlessBehavior {
        self.mockAuthPasswordlessProvider
    }

    /// Test happy path for signInWithMagicLink
    ///
    /// - Given: An auth plugin with mocked service.
    ///
    /// - When:
    ///    - I invoke signInWithMagicLink
    /// - Then:
    ///    - I should get the info in next step
    ///
    func testSignInWithMagicLink() async {
        setUpWith(authPasswordlessEnvironment:
                    BasicPasswordlessEnvironment(authPasswordlessFactory: makeAuthPasswordlessClient))
        let clientMetadata = [
            "somekey": "somevalue"
        ]
        self.mockIdentityProvider = MockIdentityProvider(mockInitiateAuthResponse: { input in
            XCTAssertEqual(input.clientMetadata?["somekey"], "somevalue")
            return InitiateAuthOutput(
                authenticationResult: .none,
                challengeName: .customChallenge,
                challengeParameters: [
                    "nextStep": "PROVIDE_AUTH_PARAMETERS"
                ],
                session: "someSession")
        }, mockRespondToAuthChallengeResponse: { input in
            XCTAssertEqual(input.clientMetadata?["Amplify.Passwordless.signInMethod"], "MAGIC_LINK")
            XCTAssertEqual(input.clientMetadata?["Amplify.Passwordless.action"], "REQUEST")
            XCTAssertEqual(input.clientMetadata?["Amplify.Passwordless.deliveryMedium"], "EMAIL")
            XCTAssertEqual(input.clientMetadata?["Amplify.Passwordless.redirectUri"], self.redirectURL)
            XCTAssertEqual(input.clientMetadata?["somekey"], "somevalue")

            return RespondToAuthChallengeOutput(
                authenticationResult: .none,
                challengeName: .customChallenge,
                challengeParameters: [
                    "nextStep": "PROVIDE_CHALLENGE_RESPONSE",
                    "attributeName": "email",
                    "deliveryMedium": "EMAIL",
                    "destination": "S***@g***"
                ],
                session: "session")
        })

        let pluginOptions = AWSAuthSignInPasswordlessOptions(clientMetadata: clientMetadata)
        let options = AuthSignInWithMagicLinkRequest.Options(pluginOptions: pluginOptions)
        do {
            let result = try await plugin.signInWithMagicLink(
                username: username,
                flow: .signIn,
                redirectURL: redirectURL,
                options: options)
            
           guard case .confirmSignInWithMagicLink(let codeDeliveryDetails, _) = result.nextStep else {
                XCTFail("Result should be .confirmSignInWithMagicLink for next step")
                return
            }

            guard case .email(let destination) = codeDeliveryDetails.destination else {
                XCTFail("Result should contain codeDeliveryDetails.destination")
                return
            }

            XCTAssertNotNil(destination, "Destination should not be nil")
            XCTAssertEqual(destination, "S***@g***")

            guard case .email = codeDeliveryDetails.attributeKey else {
                XCTFail("Result for codeDeliveryDetails.attributeKey should be email")
                return
            }

            XCTAssertFalse(result.isSignedIn, "Signin result should not be complete")
        } catch {
            XCTFail("Received failure with error \(error)")
        }
    }

    /// Test happy path for signInAndSignUpWithMagicLink
    ///
    /// - Given: An auth plugin with mocked service.
    ///
    /// - When:
    ///    - I invoke signInWithMagicLink with flow as `.signUpAndSignIn`
    /// - Then:
    ///    - I should get the correct info in next step
    ///
    func testSignUpAndSignInWithMagicLink() async {
        self.mockAuthPasswordlessProvider = MockAuthPasswordlessBehavior(mockGetAuthPasswordlessResponse: { url, payload in
            XCTAssertEqual(url.absoluteString, Defaults.passwordlessSignUpEndpoint)
            XCTAssertEqual(payload.username, self.username)
            XCTAssertEqual(payload.deliveryMedium, "EMAIL")
            XCTAssertEqual(payload.userAttributes?["somekey"], "somevalue")
            XCTAssertEqual(payload.userPoolId, Defaults.userPoolId)
            XCTAssertEqual(payload.region, Defaults.regionString)
        })
        
        setUpWith(authPasswordlessEnvironment:
                    BasicPasswordlessEnvironment(authPasswordlessFactory: makeAuthPasswordlessClient))
        
        let clientMetadata = [
            "somekey": "somevalue"
        ]
        let userAttributes = [
            "somekey": "somevalue"
        ]
        self.mockIdentityProvider = MockIdentityProvider(mockInitiateAuthResponse: { input in
            XCTAssertEqual(input.clientMetadata?["somekey"], "somevalue")
            return InitiateAuthOutput(
                authenticationResult: .none,
                challengeName: .customChallenge,
                challengeParameters: [
                    "nextStep": "PROVIDE_AUTH_PARAMETERS"
                ],
                session: "someSession")
        }, mockRespondToAuthChallengeResponse: { input in
            XCTAssertEqual(input.clientMetadata?["Amplify.Passwordless.signInMethod"], "MAGIC_LINK")
            XCTAssertEqual(input.clientMetadata?["Amplify.Passwordless.action"], "REQUEST")
            XCTAssertEqual(input.clientMetadata?["Amplify.Passwordless.deliveryMedium"], "EMAIL")
            XCTAssertEqual(input.clientMetadata?["Amplify.Passwordless.redirectUri"], self.redirectURL)
            XCTAssertEqual(input.clientMetadata?["somekey"], "somevalue")

            return RespondToAuthChallengeOutput(
                authenticationResult: .none,
                challengeName: .customChallenge,
                challengeParameters: [
                    "nextStep": "PROVIDE_CHALLENGE_RESPONSE",
                    "attributeName": "email",
                    "deliveryMedium": "EMAIL",
                    "destination": "S***@g***"
                ],
                session: "session")
        })

        let pluginOptions = AWSAuthSignUpAndSignInPasswordlessOptions(userAttributes: userAttributes,
                                                                      clientMetadata: clientMetadata)
        let options = AuthSignInWithMagicLinkRequest.Options(pluginOptions: pluginOptions)
        do {
            let result = try await plugin.signInWithMagicLink(
                username: username,
                flow: .signUpAndSignIn,
                redirectURL: redirectURL,
                options: options)
            
            
            guard case .confirmSignInWithMagicLink(let codeDeliveryDetails, _) = result.nextStep else {
                XCTFail("Result should be .confirmSignInWithMagicLink for next step")
                return
            }

            guard case .email(let destination) = codeDeliveryDetails.destination else {
                XCTFail("Result should contain codeDeliveryDetails.destination")
                return
            }

            XCTAssertNotNil(destination, "Destination should not be nil")
            XCTAssertEqual(destination, "S***@g***")

            guard case .email = codeDeliveryDetails.attributeKey else {
                XCTFail("Result for codeDeliveryDetails.attributeKey should be email")
                return
            }

            XCTAssertFalse(result.isSignedIn, "Signin result should not be complete")
        } catch {
            XCTFail("Received failure with error \(error)")
        }
    }
    
    /// Test failure path for signInAndSignUpWithMagicLink
    ///
    /// - Given: An auth plugin with mocked service and userpool config missing the passwordless endpoint URL
    ///
    /// - When:
    ///    - I invoke signInWithMagicLink with flow as `.signUpAndSignIn`
    /// - Then:
    ///    - I should get an error
    ///
    func testSignUpAndSignInWithMagicLinkWithMissingEndpointURL() async {
        self.mockAuthPasswordlessProvider = MockAuthPasswordlessBehavior(mockGetAuthPasswordlessResponse: { url, payload in
            XCTAssertEqual(url.absoluteString, Defaults.passwordlessSignUpEndpoint)
            XCTAssertEqual(payload.username, self.username)
            XCTAssertEqual(payload.deliveryMedium, "EMAIL")
            XCTAssertEqual(payload.userAttributes?["somekey"], "somevalue")
            XCTAssertEqual(payload.userPoolId, Defaults.userPoolId)
            XCTAssertEqual(payload.region, Defaults.regionString)
        })
        
        setUpWith(
            authPasswordlessEnvironment:
                        BasicPasswordlessEnvironment(authPasswordlessFactory: makeAuthPasswordlessClient),
            authConfiguration: .userPoolsAndIdentityPools(
                Defaults.makeDefaultUserPoolConfigDataWithNilPasswordlessSignUpEndpoint(),
                Defaults.makeIdentityConfigData())
        )
        
        let clientMetadata = [
            "somekey": "somevalue"
        ]
        let userAttributes = [
            "somekey": "somevalue"
        ]
        self.mockIdentityProvider = MockIdentityProvider(mockInitiateAuthResponse: { input in
            XCTAssertEqual(input.clientMetadata?["somekey"], "somevalue")
            return InitiateAuthOutput(
                authenticationResult: .none,
                challengeName: .customChallenge,
                challengeParameters: [
                    "nextStep": "PROVIDE_AUTH_PARAMETERS"
                ],
                session: "someSession")
        }, mockRespondToAuthChallengeResponse: { input in
            XCTAssertEqual(input.clientMetadata?["Amplify.Passwordless.signInMethod"], "MAGIC_LINK")
            XCTAssertEqual(input.clientMetadata?["Amplify.Passwordless.action"], "REQUEST")
            XCTAssertEqual(input.clientMetadata?["Amplify.Passwordless.deliveryMedium"], "EMAIL")
            XCTAssertEqual(input.clientMetadata?["Amplify.Passwordless.redirectUri"], self.redirectURL)
            XCTAssertEqual(input.clientMetadata?["somekey"], "somevalue")

            return RespondToAuthChallengeOutput(
                authenticationResult: .none,
                challengeName: .customChallenge,
                challengeParameters: [
                    "nextStep": "PROVIDE_CHALLENGE_RESPONSE",
                    "attributeName": "email",
                    "deliveryMedium": "EMAIL",
                    "destination": "S***@g***"
                ],
                session: "session")
        })

        let pluginOptions = AWSAuthSignUpAndSignInPasswordlessOptions(userAttributes: userAttributes,
                                                                      clientMetadata: clientMetadata)
        let options = AuthSignInWithMagicLinkRequest.Options(pluginOptions: pluginOptions)
        do {
            let _ = try await plugin.signInWithMagicLink(
                username: username,
                flow: .signUpAndSignIn,
                redirectURL: redirectURL,
                options: options)
            
            XCTFail("Should fail due to missing endpoint URL in configuration")
        } catch {
            guard let authError = error as? AuthError else {
                XCTFail("Error should be of type AuthError")
                return
            }
            
            guard case let .configuration(errorDescription, recoverySuggestion, _) = authError else {
                XCTFail("Error should be of type .configuration")
                return
            }

            
            XCTAssertEqual(errorDescription, "API Gateway endpoint not found in configuration")
            XCTAssertEqual(recoverySuggestion, AuthPluginErrorConstants.configurationError)
        }
    }
    
    /// Test failure path for signInAndSignUpWithMagicLink
    ///
    /// - Given: An auth plugin with mocked service and `nil` passwordless environment
    ///
    /// - When:
    ///    - I invoke signInWithMagicLink with flow as `.signUpAndSignIn`
    /// - Then:
    ///    - I should get an error
    ///
    func testSignUpAndSignInWithMagicLinkWithNilPasswordlessClient() async {
        self.mockAuthPasswordlessProvider = MockAuthPasswordlessBehavior(mockGetAuthPasswordlessResponse: { url, payload in
            XCTAssertEqual(url.absoluteString, Defaults.passwordlessSignUpEndpoint)
            XCTAssertEqual(payload.username, self.username)
            XCTAssertEqual(payload.deliveryMedium, "EMAIL")
            XCTAssertEqual(payload.userAttributes?["somekey"], "somevalue")
            XCTAssertEqual(payload.userPoolId, Defaults.userPoolId)
            XCTAssertEqual(payload.region, Defaults.regionString)
        })
        setUpWith()
        
        let clientMetadata = [
            "somekey": "somevalue"
        ]
        let userAttributes = [
            "somekey": "somevalue"
        ]
        self.mockIdentityProvider = MockIdentityProvider(mockInitiateAuthResponse: { input in
            XCTAssertEqual(input.clientMetadata?["somekey"], "somevalue")
            return InitiateAuthOutput(
                authenticationResult: .none,
                challengeName: .customChallenge,
                challengeParameters: [
                    "nextStep": "PROVIDE_AUTH_PARAMETERS"
                ],
                session: "someSession")
        }, mockRespondToAuthChallengeResponse: { input in
            XCTAssertEqual(input.clientMetadata?["Amplify.Passwordless.signInMethod"], "MAGIC_LINK")
            XCTAssertEqual(input.clientMetadata?["Amplify.Passwordless.action"], "REQUEST")
            XCTAssertEqual(input.clientMetadata?["Amplify.Passwordless.deliveryMedium"], "EMAIL")
            XCTAssertEqual(input.clientMetadata?["Amplify.Passwordless.redirectUri"], self.redirectURL)
            XCTAssertEqual(input.clientMetadata?["somekey"], "somevalue")

            return RespondToAuthChallengeOutput(
                authenticationResult: .none,
                challengeName: .customChallenge,
                challengeParameters: [
                    "nextStep": "PROVIDE_CHALLENGE_RESPONSE",
                    "attributeName": "email",
                    "deliveryMedium": "EMAIL",
                    "destination": "S***@g***"
                ],
                session: "session")
        })

        let pluginOptions = AWSAuthSignUpAndSignInPasswordlessOptions(userAttributes: userAttributes,
                                                                      clientMetadata: clientMetadata)
        let options = AuthSignInWithMagicLinkRequest.Options(pluginOptions: pluginOptions)
        do {
            let _ = try await plugin.signInWithMagicLink(
                username: username,
                flow: .signUpAndSignIn,
                redirectURL: redirectURL,
                options: options)
            
            XCTFail("Should fail")
        } catch {
            guard let authError = error as? AuthError else {
                XCTFail("Error should be of type AuthError")
                return
            }
            
            guard case let .configuration(errorDescription, recoverySuggestion, _) = authError else {
                XCTFail("Error should be of type .configuration")
                return
            }

            
            XCTAssertEqual(errorDescription, "URL Session client is not set up")
            XCTAssertEqual(recoverySuggestion, AuthPluginErrorConstants.configurationError)
        }
    }
    
    /// Test failure path for signInAndSignUpWithMagicLink
    ///
    /// - Given: An auth plugin with mocked service and missing userpool config
    ///
    /// - When:
    ///    - I invoke signInWithMagicLink with flow as `.signUpAndSignIn`
    /// - Then:
    ///    - I should get an error
    ///
    func testSignUpAndSignInWithMagicLinkWithMissingUserPoolConfig() async {
        self.mockAuthPasswordlessProvider = MockAuthPasswordlessBehavior(mockGetAuthPasswordlessResponse: { url, payload in
            XCTAssertEqual(url.absoluteString, Defaults.passwordlessSignUpEndpoint)
            XCTAssertEqual(payload.username, self.username)
            XCTAssertEqual(payload.deliveryMedium, "EMAIL")
            XCTAssertEqual(payload.userAttributes?["somekey"], "somevalue")
            XCTAssertEqual(payload.userPoolId, Defaults.userPoolId)
            XCTAssertEqual(payload.region, Defaults.regionString)
        })
        setUpWith(authConfiguration: .identityPools(Defaults.makeIdentityConfigData()))
        
        let clientMetadata = [
            "somekey": "somevalue"
        ]
        let userAttributes = [
            "somekey": "somevalue"
        ]
        self.mockIdentityProvider = MockIdentityProvider(mockInitiateAuthResponse: { input in
            XCTAssertEqual(input.clientMetadata?["somekey"], "somevalue")
            return InitiateAuthOutput(
                authenticationResult: .none,
                challengeName: .customChallenge,
                challengeParameters: [
                    "nextStep": "PROVIDE_AUTH_PARAMETERS"
                ],
                session: "someSession")
        }, mockRespondToAuthChallengeResponse: { input in
            XCTAssertEqual(input.clientMetadata?["Amplify.Passwordless.signInMethod"], "MAGIC_LINK")
            XCTAssertEqual(input.clientMetadata?["Amplify.Passwordless.action"], "REQUEST")
            XCTAssertEqual(input.clientMetadata?["Amplify.Passwordless.deliveryMedium"], "EMAIL")
            XCTAssertEqual(input.clientMetadata?["Amplify.Passwordless.redirectUri"], self.redirectURL)
            XCTAssertEqual(input.clientMetadata?["somekey"], "somevalue")

            return RespondToAuthChallengeOutput(
                authenticationResult: .none,
                challengeName: .customChallenge,
                challengeParameters: [
                    "nextStep": "PROVIDE_CHALLENGE_RESPONSE",
                    "attributeName": "email",
                    "deliveryMedium": "EMAIL",
                    "destination": "S***@g***"
                ],
                session: "session")
        })

        let pluginOptions = AWSAuthSignUpAndSignInPasswordlessOptions(userAttributes: userAttributes,
                                                                      clientMetadata: clientMetadata)
        let options = AuthSignInWithMagicLinkRequest.Options(pluginOptions: pluginOptions)
        do {
            let _ = try await plugin.signInWithMagicLink(
                username: username,
                flow: .signUpAndSignIn,
                redirectURL: redirectURL,
                options: options)
            
            XCTFail("Should fail")
        } catch {
            guard let authError = error as? AuthError else {
                XCTFail("Error should be of type AuthError")
                return
            }
            
            guard case let .configuration(errorDescription, recoverySuggestion, _) = authError else {
                XCTFail("Error should be of type .configuration")
                return
            }

            
            XCTAssertEqual(errorDescription, "Could not find user pool configuration")
            XCTAssertEqual(recoverySuggestion, AuthPluginErrorConstants.configurationError)
        }
    }
    
    /// Test failure path for signInAndSignUpWithMagicLink
    ///
    /// - Given: An auth plugin with mocked service and userpool config having empty endpoint URL
    ///
    /// - When:
    ///    - I invoke signInWithMagicLink with flow as `.signUpAndSignIn`
    /// - Then:
    ///    - I should get an error
    ///
    func testSignUpAndSignInWithMagicLinkWithEmptyEndpointURL() async {
        self.mockAuthPasswordlessProvider = MockAuthPasswordlessBehavior(mockGetAuthPasswordlessResponse: { url, payload in
            XCTAssertEqual(url.absoluteString, Defaults.passwordlessSignUpEndpoint)
            XCTAssertEqual(payload.username, self.username)
            XCTAssertEqual(payload.deliveryMedium, "EMAIL")
            XCTAssertEqual(payload.userAttributes?["somekey"], "somevalue")
            XCTAssertEqual(payload.userPoolId, Defaults.userPoolId)
            XCTAssertEqual(payload.region, Defaults.regionString)
        })
        setUpWith(
            authPasswordlessEnvironment:
                        BasicPasswordlessEnvironment(authPasswordlessFactory: makeAuthPasswordlessClient),
            authConfiguration: .userPoolsAndIdentityPools(
                Defaults.makeDefaultUserPoolConfigDataWithEmptySignUpEndpoint(),
                Defaults.makeIdentityConfigData()))
        
        let clientMetadata = [
            "somekey": "somevalue"
        ]
        let userAttributes = [
            "somekey": "somevalue"
        ]
        self.mockIdentityProvider = MockIdentityProvider(mockInitiateAuthResponse: { input in
            XCTAssertEqual(input.clientMetadata?["somekey"], "somevalue")
            return InitiateAuthOutput(
                authenticationResult: .none,
                challengeName: .customChallenge,
                challengeParameters: [
                    "nextStep": "PROVIDE_AUTH_PARAMETERS"
                ],
                session: "someSession")
        }, mockRespondToAuthChallengeResponse: { input in
            XCTAssertEqual(input.clientMetadata?["Amplify.Passwordless.signInMethod"], "MAGIC_LINK")
            XCTAssertEqual(input.clientMetadata?["Amplify.Passwordless.action"], "REQUEST")
            XCTAssertEqual(input.clientMetadata?["Amplify.Passwordless.deliveryMedium"], "EMAIL")
            XCTAssertEqual(input.clientMetadata?["Amplify.Passwordless.redirectUri"], self.redirectURL)
            XCTAssertEqual(input.clientMetadata?["somekey"], "somevalue")

            return RespondToAuthChallengeOutput(
                authenticationResult: .none,
                challengeName: .customChallenge,
                challengeParameters: [
                    "nextStep": "PROVIDE_CHALLENGE_RESPONSE",
                    "attributeName": "email",
                    "deliveryMedium": "EMAIL",
                    "destination": "S***@g***"
                ],
                session: "session")
        })

        let pluginOptions = AWSAuthSignUpAndSignInPasswordlessOptions(userAttributes: userAttributes,
                                                                      clientMetadata: clientMetadata)
        let options = AuthSignInWithMagicLinkRequest.Options(pluginOptions: pluginOptions)
        do {
            let _ = try await plugin.signInWithMagicLink(
                username: username,
                flow: .signUpAndSignIn,
                redirectURL: redirectURL,
                options: options)
            
            XCTFail("Should fail due to missing endpoint URL in configuration")
        } catch {
            guard let authError = error as? AuthError else {
                XCTFail("Error should be of type AuthError")
                return
            }
            
            guard case let .configuration(errorDescription, recoverySuggestion, _) = authError else {
                XCTFail("Error should be of type .configuration")
                return
            }
            
            XCTAssertEqual(errorDescription, "API Gateway URL is not valid")
            XCTAssertEqual(recoverySuggestion, AuthPluginErrorConstants.configurationError)
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
        setUpWith(authPasswordlessEnvironment:
                    BasicPasswordlessEnvironment(authPasswordlessFactory: makeAuthPasswordlessClient))
        self.mockIdentityProvider = MockIdentityProvider(mockInitiateAuthResponse: { _ in
            throw AWSCognitoIdentityProvider.InternalErrorException()
        })

        let options = AuthSignInWithMagicLinkRequest.Options()
        do {
            let result = try await plugin.signInWithMagicLink(
                username: username,
                flow: .signIn,
                redirectURL: redirectURL,
                options: options)
            XCTFail("Should not produce result - \(result)")
        } catch {
            guard case AuthError.unknown = error else {
                XCTFail("Should produce unknown error")
                return
            }
        }
    }

    /// Test a signIn with `InvalidLambdaResponseException` from service
    ///
    /// - Given: Given an auth plugin with mocked service. Mocked service should mock a
    ///   InvalidLambdaResponseException response for signIn
    ///
    /// - When:
    ///    - I invoke signIn
    /// - Then:
    ///    - I should get a .service error with .lambda error
    ///
    func testSignInWithInvalidLambdaResponseException() async {
        setUpWith(authPasswordlessEnvironment:
                    BasicPasswordlessEnvironment(authPasswordlessFactory: makeAuthPasswordlessClient))
        self.mockIdentityProvider = MockIdentityProvider(mockInitiateAuthResponse: { _ in
            throw AWSCognitoIdentityProvider.InvalidLambdaResponseException()
        })

        let options = AuthSignInWithMagicLinkRequest.Options()
        do {
            let result = try await plugin.signInWithMagicLink(
                username: username,
                flow: .signIn,
                redirectURL: redirectURL,
                options: options)
            XCTFail("Should not produce result - \(result)")
        } catch {
            guard case AuthError.service(_, _, let underlyingError) = error,
                  case .lambda = (underlyingError as? AWSCognitoAuthError) else {
                XCTFail("Should produce lambda error but instead produced \(error)")
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
        setUpWith(authPasswordlessEnvironment:
                    BasicPasswordlessEnvironment(authPasswordlessFactory: makeAuthPasswordlessClient))
        self.mockIdentityProvider = MockIdentityProvider(mockInitiateAuthResponse: { _ in
            throw AWSCognitoIdentityProvider.InvalidParameterException()
        })

        let options = AuthSignInWithMagicLinkRequest.Options()
        do {
            let result = try await plugin.signInWithMagicLink(
                username: username,
                flow: .signIn,
                redirectURL: redirectURL,
                options: options)
            XCTFail("Should not produce result - \(result)")
        } catch {
            guard case AuthError.service(_, _, let underlyingError) = error,
                  case .invalidParameter = (underlyingError as? AWSCognitoAuthError) else {
                XCTFail("Should produce invalidParameter error but instead produced \(error)")
                return
            }
        }
    }

    /// Test a signIn with `InvalidUserPoolConfigurationException` from service
    ///
    /// - Given: Given an auth plugin with mocked service. Mocked service should mock a
    ///   InvalidUserPoolConfigurationException response for signIn
    ///
    /// - When:
    ///    - I invoke signIn
    /// - Then:
    ///    - I should get a .configuration error
    ///
    func testSignInWithInvalidUserPoolConfigurationException() async {
        setUpWith(authPasswordlessEnvironment:
                    BasicPasswordlessEnvironment(authPasswordlessFactory: makeAuthPasswordlessClient))
        self.mockIdentityProvider = MockIdentityProvider(mockInitiateAuthResponse: { _ in
            throw AWSCognitoIdentityProvider.InvalidUserPoolConfigurationException()
        })

        let options = AuthSignInWithMagicLinkRequest.Options()
        do {
            let result = try await plugin.signInWithMagicLink(
                username: username,
                flow: .signIn,
                redirectURL: redirectURL,
                options: options)
            XCTFail("Should not produce result - \(result)")
        } catch {
            guard case AuthError.configuration = error else {
                XCTFail("Should produce configuration intead produced \(error)")
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
        setUpWith(authPasswordlessEnvironment:
                    BasicPasswordlessEnvironment(authPasswordlessFactory: makeAuthPasswordlessClient))
        self.mockIdentityProvider = MockIdentityProvider(mockInitiateAuthResponse: { _ in
            throw AWSCognitoIdentityProvider.NotAuthorizedException()
        })

        let options = AuthSignInWithMagicLinkRequest.Options()
        do {
            let result = try await plugin.signInWithMagicLink(
                username: username,
                flow: .signIn,
                redirectURL: redirectURL,
                options: options)
            XCTFail("Should not produce result - \(result)")
        } catch {
            guard case AuthError.notAuthorized = error else {
                XCTFail("Should produce notAuthorized error but instead produced \(error)")
                return
            }
        }
    }

    /// Test a signIn with `PasswordResetRequiredException` from service
    ///
    /// - Given: Given an auth plugin with mocked service. Mocked service should mock a
    ///   PasswordResetRequiredException response for signIn
    ///
    /// - When:
    ///    - I invoke signIn
    /// - Then:
    ///    - I should get a .resetPassword as next step
    ///
    func testSignInWithPasswordResetRequiredException() async {
        setUpWith(authPasswordlessEnvironment:
                    BasicPasswordlessEnvironment(authPasswordlessFactory: makeAuthPasswordlessClient))
        self.mockIdentityProvider = MockIdentityProvider(mockInitiateAuthResponse: { _ in
            throw AWSCognitoIdentityProvider.PasswordResetRequiredException()
        })

        let options = AuthSignInWithMagicLinkRequest.Options()
        do {
            let result = try await plugin.signInWithMagicLink(
                username: username,
                flow: .signIn,
                redirectURL: redirectURL,
                options: options)
            XCTFail("`signInWithOTP` Should not succeed")
        }
        catch {
            guard case AuthError.service(_, _, _) = error else {
                XCTFail("Should produce userNotFound error but instead produced \(error)")
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
        setUpWith(authPasswordlessEnvironment:
                    BasicPasswordlessEnvironment(authPasswordlessFactory: makeAuthPasswordlessClient))
        self.mockIdentityProvider = MockIdentityProvider(mockInitiateAuthResponse: { _ in
            throw AWSCognitoIdentityProvider.ResourceNotFoundException()
        })

        let options = AuthSignInWithMagicLinkRequest.Options()
        do {
            let result = try await plugin.signInWithMagicLink(
                username: username,
                flow: .signIn,
                redirectURL: redirectURL,
                options: options)
            XCTFail("Should not produce result - \(result)")
        } catch {
            guard case AuthError.service(_, _, let underlyingError) = error,
                  case .resourceNotFound = (underlyingError as? AWSCognitoAuthError) else {
                XCTFail("Should produce resourceNotFound error but instead produced \(error)")
                return
            }
        }
    }

    /// Test a signIn with `TooManyRequestsException` from service
    ///
    /// - Given: Given an auth plugin with mocked service. Mocked service should mock a
    ///   TooManyRequestsException response for signIn
    ///
    /// - When:
    ///    - I invoke signIn
    /// - Then:
    ///    - I should get a .service error with .requestLimitExceeded error
    ///
    func testSignInWithTooManyRequestsException() async {
        setUpWith(authPasswordlessEnvironment:
                    BasicPasswordlessEnvironment(authPasswordlessFactory: makeAuthPasswordlessClient))
        self.mockIdentityProvider = MockIdentityProvider(mockInitiateAuthResponse: { _ in
            throw AWSCognitoIdentityProvider.TooManyRequestsException()
        })

        let options = AuthSignInWithMagicLinkRequest.Options()
        do {
            let result = try await plugin.signInWithMagicLink(
                username: username,
                flow: .signIn,
                redirectURL: redirectURL,
                options: options)
            XCTFail("Should not produce result - \(result)")
        } catch {
            guard case AuthError.service(_, _, let underlyingError) = error,
                  case .requestLimitExceeded = (underlyingError as? AWSCognitoAuthError) else {
                XCTFail("Should produce requestLimitExceeded error but instead produced \(error)")
                return
            }
        }
    }

    /// Test a signIn with `UnexpectedLambdaException` from service
    ///
    /// - Given: Given an auth plugin with mocked service. Mocked service should mock a
    ///   UnexpectedLambdaException response for signIn
    ///
    /// - When:
    ///    - I invoke signIn
    /// - Then:
    ///    - I should get a .service error with .lambda error
    ///
    func testSignInWithUnexpectedLambdaException() async {
        setUpWith(authPasswordlessEnvironment:
                    BasicPasswordlessEnvironment(authPasswordlessFactory: makeAuthPasswordlessClient))
        self.mockIdentityProvider = MockIdentityProvider(mockInitiateAuthResponse: { _ in
            throw AWSCognitoIdentityProvider.UnexpectedLambdaException()
        })

        let options = AuthSignInWithMagicLinkRequest.Options()
        do {
            let result = try await plugin.signInWithMagicLink(
                username: username,
                flow: .signIn,
                redirectURL: redirectURL,
                options: options)
            XCTFail("Should not produce result - \(result)")
        } catch {
            guard case AuthError.service(_, _, let underlyingError) = error,
                  case .lambda = (underlyingError as? AWSCognitoAuthError) else {
                XCTFail("Should produce lambda error but instead produced \(error)")
                return
            }
        }
    }

    /// Test a signIn with `UserLambdaValidationException` from service
    ///
    /// - Given: Given an auth plugin with mocked service. Mocked service should mock a
    ///   UserLambdaValidationException response for signIn
    ///
    /// - When:
    ///    - I invoke signIn
    /// - Then:
    ///    - I should get a .service error with .lambda error
    ///
    func testSignInWithUserLambdaValidationException() async {
        setUpWith(authPasswordlessEnvironment:
                    BasicPasswordlessEnvironment(authPasswordlessFactory: makeAuthPasswordlessClient))
        self.mockIdentityProvider = MockIdentityProvider(mockInitiateAuthResponse: { _ in
            throw AWSCognitoIdentityProvider.UserLambdaValidationException()
        })

        let options = AuthSignInWithMagicLinkRequest.Options()
        do {
            let result = try await plugin.signInWithMagicLink(
                username: username,
                flow: .signIn,
                redirectURL: redirectURL,
                options: options)
            XCTFail("Should not produce result - \(result)")
        } catch {
            guard case AuthError.service(_, _, let underlyingError) = error,
                  case .lambda = (underlyingError as? AWSCognitoAuthError) else {
                XCTFail("Should produce lambda error but instead produced \(error)")
                return
            }
        }
    }

    /// Test a signIn with `UserNotFoundException` from service
    ///
    /// - Given: Given an auth plugin with mocked service. Mocked service should mock a
    ///   UserNotFoundException response for signIn
    ///
    /// - When:
    ///    - I invoke signIn
    /// - Then:
    ///    - I should get a .service error with .userNotFound error
    ///
    func testSignInWithUserNotFoundException() async {
        setUpWith(authPasswordlessEnvironment:
                    BasicPasswordlessEnvironment(authPasswordlessFactory: makeAuthPasswordlessClient))
        self.mockIdentityProvider = MockIdentityProvider(mockInitiateAuthResponse: { _ in
            throw AWSCognitoIdentityProvider.UserNotFoundException()
        })

        let options = AuthSignInWithMagicLinkRequest.Options()
        do {
            let result = try await plugin.signInWithMagicLink(
                username: username,
                flow: .signIn,
                redirectURL: redirectURL,
                options: options)
            XCTFail("Should not produce result - \(result)")
        } catch {
            guard case AuthError.service(_, _, let underlyingError) = error,
                  case .userNotFound = (underlyingError as? AWSCognitoAuthError) else {
                XCTFail("Should produce userNotFound error but instead produced \(error)")
                return
            }
        }
    }

    // MARK: - Service error for RespondToAuthChallenge

    /// Test a signIn with `AliasExistsException` from service
    ///
    /// - Given: Given an auth plugin with mocked service. Mocked service should mock a
    ///   AliasExistsException response for signIn
    ///
    /// - When:
    ///    - I invoke signIn
    /// - Then:
    ///    - I should get a .service error with .aliasExists error
    ///
    func testSignInWithAliasExistsException() async {
        setUpWith(authPasswordlessEnvironment:
                    BasicPasswordlessEnvironment(authPasswordlessFactory: makeAuthPasswordlessClient))
        self.mockIdentityProvider = MockIdentityProvider(mockInitiateAuthResponse: { _ in
            return InitiateAuthOutput(
                authenticationResult: .none,
                challengeName: .customChallenge,
                challengeParameters: [
                    "nextStep": "PROVIDE_AUTH_PARAMETERS"
                ],
                session: "someSession")
        }, mockRespondToAuthChallengeResponse: { _ in
            throw AWSCognitoIdentityProvider.AliasExistsException()
        })

        let options = AuthSignInWithMagicLinkRequest.Options()
        do {
            let result = try await plugin.signInWithMagicLink(
                username: username,
                flow: .signIn,
                redirectURL: redirectURL,
                options: options)
            XCTFail("Should not produce result - \(result)")
        } catch {
            guard case AuthError.service(_, _, let underlyingError) = error,
                  case .aliasExists = (underlyingError as? AWSCognitoAuthError) else {
                XCTFail("Should produce aliasExists error but instead produced \(error)")
                return
            }
        }
    }

    /// Test a signIn restart while another sign in is in progress
    ///
    /// - Given: Given an auth plugin with mocked service and a in progress signIn waiting for SMS verification
    ///
    /// - When:
    ///    - I invoke another signIn with valid values
    /// - Then:
    ///    - I should get a .done response
    ///
    func testRestartSignIn() async {
        setUpWith(authPasswordlessEnvironment:
                    BasicPasswordlessEnvironment(authPasswordlessFactory: makeAuthPasswordlessClient))
        self.mockIdentityProvider = MockIdentityProvider(mockInitiateAuthResponse: { _ in
            return InitiateAuthOutput(
                authenticationResult: .none,
                challengeName: .customChallenge,
                challengeParameters: [
                    "nextStep": "PROVIDE_AUTH_PARAMETERS"
                ],
                session: "someSession")
        }, mockRespondToAuthChallengeResponse: { _ in
            return RespondToAuthChallengeOutput(
                authenticationResult: .none,
                challengeName: .customChallenge,
                challengeParameters: [
                    "nextStep": "PROVIDE_CHALLENGE_RESPONSE",
                    "attributeName": "email",
                    "deliveryMedium": "EMAIL",
                    "destination": "S***@g***"
                ],
                session: "session")
        })

        let options = AuthSignInWithMagicLinkRequest.Options()
        do {
            let result = try await plugin.signInWithMagicLink(
                username: username,
                flow: .signIn,
                redirectURL: redirectURL,
                options: options)
            guard case .confirmSignInWithMagicLink =  result.nextStep else {
                XCTFail("Result should be .confirmSignInWithMagicLink for next step instead got. \(result.nextStep)")
                return
            }
            XCTAssertFalse(result.isSignedIn)
            self.mockIdentityProvider = MockIdentityProvider(mockInitiateAuthResponse: { _ in
                InitiateAuthOutput(
                    authenticationResult: .none,
                    challengeName: .customChallenge,
                    challengeParameters: [
                        "nextStep": "PROVIDE_AUTH_PARAMETERS"
                    ],
                    session: "someSession")
            }, mockRespondToAuthChallengeResponse: { _ in
                RespondToAuthChallengeOutput(
                    authenticationResult: .init(
                        accessToken: Defaults.validAccessToken,
                        expiresIn: 300,
                        idToken: "idToken",
                        newDeviceMetadata: nil,
                        refreshToken: "refreshToken",
                        tokenType: ""),
                    challengeName: .none,
                    challengeParameters: [:],
                    session: "session")
            })
            let result2 = try await plugin.signInWithMagicLink(
                username: username,
                flow: .signIn,
                redirectURL: redirectURL,
                options: options)
            guard case .done =  result2.nextStep else {
                XCTFail("Result should be .done for next step")
                return
            }
            XCTAssertTrue(result2.isSignedIn)
        } catch {
            XCTFail("Received failure with error \(error)")
        }
    }


}
