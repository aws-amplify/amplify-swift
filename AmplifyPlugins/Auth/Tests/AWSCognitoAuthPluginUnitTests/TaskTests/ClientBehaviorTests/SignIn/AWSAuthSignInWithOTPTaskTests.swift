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
import ClientRuntime

class AWSAuthSignInWithOTPTaskTests: BasePluginTest {

    override var initialState: AuthState {
        AuthState.configured(.signedOut(.init(lastKnownUserName: nil)), .configured)
    }

    override func setUp() {
        plugin = AWSCognitoAuthPlugin()
    }
    
    /// Test happy path for signInWithOTP
    ///
    /// - Given: An auth plugin with mocked service.
    ///
    /// - When:
    ///    - I invoke signInWithOTP
    /// - Then:
    ///    - I should get `confirmSignInWithOTP` as the next step. 
    ///
    func testSignInWithOTP() async {
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
            XCTAssertEqual(input.clientMetadata?["Amplify.Passwordless.signInMethod"], "OTP")
            XCTAssertEqual(input.clientMetadata?["Amplify.Passwordless.action"], "REQUEST")
            XCTAssertEqual(input.clientMetadata?["Amplify.Passwordless.deliveryMedium"], "EMAIL")
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
        let options = AuthSignInWithOTPRequest.Options(pluginOptions: pluginOptions)
        do {
            let result = try await plugin.signInWithOTP(
                username: "username",
                flow: .signIn,
                destination: .email,
                options: options)
            
            guard case .confirmSignInWithOTP(let codeDeliveryDetails, _) = result.nextStep else {
                XCTFail("Result should be .confirmSignInWithOTP for next step")
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

    /// Test happy path for signUpAndSignInWithOTP
    ///
    /// - Given: An auth plugin with mocked service.
    ///
    /// - When:
    ///    - I invoke signInWithOTP with flow as `.signUpAndSignIn`
    /// - Then:
    ///    - I should get `confirmSignInWithOTP` as the next step.
    ///
    func testSignUpAndSignInWithOTP() async {
        let username = "username"
        self.mockAuthPasswordlessProvider = MockAuthPasswordlessBehavior(mockGetAuthPasswordlessResponse: { url, payload in
            XCTAssertEqual(url.absoluteString, Defaults.passwordlessSignUpEndpoint)
            XCTAssertEqual(payload.username, username)
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
            XCTAssertEqual(input.clientMetadata?["Amplify.Passwordless.signInMethod"], "OTP")
            XCTAssertEqual(input.clientMetadata?["Amplify.Passwordless.action"], "REQUEST")
            XCTAssertEqual(input.clientMetadata?["Amplify.Passwordless.deliveryMedium"], "EMAIL")
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

        let pluginOptions = AWSAuthSignUpAndSignInPasswordlessOptions(
            userAttributes: userAttributes,
            clientMetadata: clientMetadata
        )
        let options = AuthSignInWithOTPRequest.Options(pluginOptions: pluginOptions)
        do {
            let result = try await plugin.signInWithOTP(
                username: username,
                flow: .signUpAndSignIn,
                destination: .email,
                options: options)
            
            guard case .confirmSignInWithOTP(let codeDeliveryDetails, _) = result.nextStep else {
                XCTFail("Result should be .confirmSignInWithOTP for next step")
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
    
    /// Test failure path for signInAndSignUpWithOTP
    ///
    /// - Given: An auth plugin with mocked service and userpool config missing the passwordless endpoint URL
    ///
    /// - When:
    ///    - I invoke signInWithOTP with flow as `.signUpAndSignIn`
    /// - Then:
    ///    - I should get an error
    ///
    func testSignUpAndSignInWithOTPWithMissingEndpointURL() async {
        let username = "username"
        self.mockAuthPasswordlessProvider = MockAuthPasswordlessBehavior(mockGetAuthPasswordlessResponse: { url, payload in
            XCTAssertEqual(url.absoluteString, Defaults.passwordlessSignUpEndpoint)
            XCTAssertEqual(payload.username, username)
            XCTAssertEqual(payload.deliveryMedium, "EMAIL")
            XCTAssertEqual(payload.userAttributes?["somekey"], "somevalue")
            XCTAssertEqual(payload.userPoolId, Defaults.userPoolId)
            XCTAssertEqual(payload.region, Defaults.regionString)
        })
        setUpWith(
            authPasswordlessEnvironment:BasicPasswordlessEnvironment(authPasswordlessFactory: makeAuthPasswordlessClient),
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
            XCTAssertEqual(input.clientMetadata?["Amplify.Passwordless.signInMethod"], "OTP")
            XCTAssertEqual(input.clientMetadata?["Amplify.Passwordless.action"], "REQUEST")
            XCTAssertEqual(input.clientMetadata?["Amplify.Passwordless.deliveryMedium"], "EMAIL")
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

        let pluginOptions = AWSAuthSignUpAndSignInPasswordlessOptions(
            userAttributes: userAttributes,
            clientMetadata: clientMetadata
        )
        let options = AuthSignInWithOTPRequest.Options(pluginOptions: pluginOptions)
        do {
            let _ = try await plugin.signInWithOTP(
                username: username,
                flow: .signUpAndSignIn,
                destination: .email,
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

            
            XCTAssertEqual(errorDescription, "API Gateway endpoint not found in configuration")
            XCTAssertEqual(recoverySuggestion, AuthPluginErrorConstants.configurationError)
        }
    }
    
    /// Test failure path for signInAndSignUpWithOTP
    ///
    /// - Given: An auth plugin with mocked service and `nil` passwordless environment
    ///
    /// - When:
    ///    - I invoke signInWithOTP with flow as `.signUpAndSignIn`
    /// - Then:
    ///    - I should get an error
    ///
    func testSignUpAndSignInWithOTPWithNilPasswordlessClient() async {
        let username = "username"
        self.mockAuthPasswordlessProvider = MockAuthPasswordlessBehavior(mockGetAuthPasswordlessResponse: { url, payload in
            XCTAssertEqual(url.absoluteString, Defaults.passwordlessSignUpEndpoint)
            XCTAssertEqual(payload.username, username)
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
            XCTAssertEqual(input.clientMetadata?["Amplify.Passwordless.signInMethod"], "OTP")
            XCTAssertEqual(input.clientMetadata?["Amplify.Passwordless.action"], "REQUEST")
            XCTAssertEqual(input.clientMetadata?["Amplify.Passwordless.deliveryMedium"], "EMAIL")
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

        let pluginOptions = AWSAuthSignUpAndSignInPasswordlessOptions(
            userAttributes: userAttributes,
            clientMetadata: clientMetadata
        )
        let options = AuthSignInWithOTPRequest.Options(pluginOptions: pluginOptions)
        do {
            let _ = try await plugin.signInWithOTP(
                username: username,
                flow: .signUpAndSignIn,
                destination: .email,
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
    
    /// Test failure path for signInAndSignUpWithOTP
    ///
    /// - Given: An auth plugin with mocked service and missing userpool config
    ///
    /// - When:
    ///    - I invoke signInWithOTP with flow as `.signUpAndSignIn`
    /// - Then:
    ///    - I should get an error
    ///
    func testSignUpAndSignInWithOTPWithMissingUserPoolConfig() async {
        let username = "username"
        self.mockAuthPasswordlessProvider = MockAuthPasswordlessBehavior(mockGetAuthPasswordlessResponse: { url, payload in
            XCTAssertEqual(url.absoluteString, Defaults.passwordlessSignUpEndpoint)
            XCTAssertEqual(payload.username, username)
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
            XCTAssertEqual(input.clientMetadata?["Amplify.Passwordless.signInMethod"], "OTP")
            XCTAssertEqual(input.clientMetadata?["Amplify.Passwordless.action"], "REQUEST")
            XCTAssertEqual(input.clientMetadata?["Amplify.Passwordless.deliveryMedium"], "EMAIL")
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

        let pluginOptions = AWSAuthSignUpAndSignInPasswordlessOptions(
            userAttributes: userAttributes,
            clientMetadata: clientMetadata
        )
        let options = AuthSignInWithOTPRequest.Options(pluginOptions: pluginOptions)
        do {
            let _ = try await plugin.signInWithOTP(
                username: username,
                flow: .signUpAndSignIn,
                destination: .email,
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
    
    /// Test failure path for signInWithOTP
    ///
    /// - Given: An auth plugin with mocked service and userpool config having empty endpoint URL
    ///
    /// - When:
    ///    - I invoke signInWithOTP with flow as `.signUpAndSignIn`
    /// - Then:
    ///    - I should get an error
    ///
    func testSignUpAndSignInWithOTPWithEmptyEndpointURL() async {
        let username = "username"
        self.mockAuthPasswordlessProvider = MockAuthPasswordlessBehavior(mockGetAuthPasswordlessResponse: { url, payload in
            XCTAssertEqual(url.absoluteString, Defaults.passwordlessSignUpEndpoint)
            XCTAssertEqual(payload.username, username)
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
            XCTAssertEqual(input.clientMetadata?["Amplify.Passwordless.signInMethod"], "OTP")
            XCTAssertEqual(input.clientMetadata?["Amplify.Passwordless.action"], "REQUEST")
            XCTAssertEqual(input.clientMetadata?["Amplify.Passwordless.deliveryMedium"], "EMAIL")
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

        let pluginOptions = AWSAuthSignUpAndSignInPasswordlessOptions(
            userAttributes: userAttributes,
            clientMetadata: clientMetadata
        )
        let options = AuthSignInWithOTPRequest.Options(pluginOptions: pluginOptions)
        do {
            let _ = try await plugin.signInWithOTP(
                username: "username",
                flow: .signUpAndSignIn,
                destination: .email,
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
            
            XCTAssertEqual(errorDescription, "API Gateway URL is not valid")
            XCTAssertEqual(recoverySuggestion, AuthPluginErrorConstants.configurationError)
        }
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
}
