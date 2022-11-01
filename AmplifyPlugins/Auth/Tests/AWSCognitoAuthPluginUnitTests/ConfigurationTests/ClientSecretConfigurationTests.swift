//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

import XCTest
import AWSCognitoIdentity
@testable import Amplify
@testable import AWSCognitoAuthPlugin
@testable import AWSPluginsTestCommon
import AWSCognitoIdentityProvider

class ClientSecretConfigurationTests: XCTestCase {

    let networkTimeout = TimeInterval(2)
    var mockIdentityProvider: CognitoUserPoolBehavior!
    var plugin: AWSCognitoAuthPlugin!
    
    var initialState: AuthState {
        AuthState.configured(
            AuthenticationState.signedIn(
                SignedInData(
                    signedInDate: Date(),
                    signInMethod: .apiBased(.userSRP),
                    cognitoUserPoolTokens: AWSCognitoUserPoolTokens.testData)),
            AuthorizationState.sessionEstablished(AmplifyCredentials.testData))
    }

    override func setUp() {
        plugin = AWSCognitoAuthPlugin()

        let getId: MockIdentity.MockGetIdResponse = { _ in
            return .init(identityId: "mockIdentityId")
        }

        let getCredentials: MockIdentity.MockGetCredentialsResponse = { _ in
            let credentials = CognitoIdentityClientTypes.Credentials(accessKeyId: "accessKey",
                                                                     expiration: Date(),
                                                                     secretKey: "secret",
                                                                     sessionToken: "session")
            return .init(credentials: credentials, identityId: "responseIdentityID")
        }

        let mockIdentity = MockIdentity(
            mockGetIdResponse: getId,
            mockGetCredentialsResponse: getCredentials)

        let environment = Defaults.makeDefaultAuthEnvironment(
            identityPoolFactory: { mockIdentity },
            userPoolFactory: { self.mockIdentityProvider })

        let statemachine = Defaults.makeDefaultAuthStateMachine(
            initialState: initialState,
            identityPoolFactory: { mockIdentity },
            userPoolFactory: { self.mockIdentityProvider })

        plugin?.configure(
            authConfiguration: Defaults.makeDefaultAuthConfigData(),
            authEnvironment: environment,
            authStateMachine: statemachine,
            credentialStoreStateMachine: Defaults.makeDefaultCredentialStateMachine(),
            hubEventHandler: MockAuthHubEventBehavior(),
            analyticsHandler: MockAnalyticsHandler())
    }



    /// Test if client secret is used for reset password api
    ///
    /// - Given: Given auth plugin with client secret present in the configuration
    /// - When:
    ///    - Invoke reset password api
    /// - Then:
    ///    - Plugin should pass the secret hash created with client secret
    ///
    func testClientSecretWithResetPassword() async throws {
        let codeDeliveryDetails = CognitoIdentityProviderClientTypes.CodeDeliveryDetailsType(
            attributeName: "attribute",
            deliveryMedium: .email,
            destination: "Amplify@amazon.com"
        )
        mockIdentityProvider = MockIdentityProvider(
            mockForgotPasswordOutputResponse: { request in
                XCTAssertNotNil(request.secretHash)
                return ForgotPasswordOutputResponse(codeDeliveryDetails: codeDeliveryDetails)
            }
        )
        _ = try await plugin.resetPassword(for: "user", options: nil)
    }

    /// Test if client secret is used for confirmResetPassword api
    ///
    /// - Given: Given auth plugin with client secret present in the configuration
    /// - When:
    ///    - Invoke confirmResetPassword api
    /// - Then:
    ///    - Plugin should pass the secret hash created with client secret
    ///
    func testClientSecretWithConfirmResetPassword() async throws {
        mockIdentityProvider = MockIdentityProvider(
            mockConfirmForgotPasswordOutputResponse: { request in
                XCTAssertNotNil(request.secretHash)
                return try ConfirmForgotPasswordOutputResponse(httpResponse: MockHttpResponse.ok)
            }
        )
        try await plugin.confirmResetPassword(
            for: "username",
            with: "newpassword",
            confirmationCode: "code",
            options: nil
        )
    }

    /// Test if client secret is used for resendSignUpCode api
    ///
    /// - Given: Given auth plugin with client secret present in the configuration
    /// - When:
    ///    - Invoke resendSignUpCode api
    /// - Then:
    ///    - Plugin should pass the secret hash created with client secret
    ///
    func testClientSecretWithResendSignupCode() async throws {

        let codeDeliveryDetails = CognitoIdentityProviderClientTypes.CodeDeliveryDetailsType(
            attributeName: nil,
            deliveryMedium: .email,
            destination: nil
        )
        mockIdentityProvider = MockIdentityProvider(
            mockResendConfirmationCodeOutputResponse: { request in
                XCTAssertNotNil(request.secretHash)
                return ResendConfirmationCodeOutputResponse(
                    codeDeliveryDetails: codeDeliveryDetails
                )
            }
        )

        let authCodeDeliveryDetails = try await plugin.resendSignUpCode(for: "username", options: nil)
        guard case .email = authCodeDeliveryDetails.destination else {
            XCTFail("Result should be .email for the destination of AuthCodeDeliveryDetails")
            return
        }
    }

    /// Test if client secret is used for signUp api
    ///
    /// - Given: Given auth plugin with client secret present in the configuration
    /// - When:
    ///    - Invoke signUp api
    /// - Then:
    ///    - Plugin should pass the secret hash created with client secret
    ///
    func testClientSecretWithSignUp() async throws {

        self.mockIdentityProvider = MockIdentityProvider(
            mockSignUpResponse: { request in
                XCTAssertNotNil(request.secretHash)
                return .init(
                    codeDeliveryDetails: .init(
                        attributeName: "some attribute",
                        deliveryMedium: .email,
                        destination: "random@random.com"),
                    userConfirmed: false,
                    userSub: "userId")
            }
        )

        let result = try await self.plugin.signUp(
            username: "jeffb",
            password: "Valid&99",
            options: nil)

        guard case .confirmUser = result.nextStep else {
            XCTFail("Result should be .confirmUser for next step")
            return
        }
    }

    /// Test if client secret is used for confirmSignUp api
    ///
    /// - Given: Given auth plugin with client secret present in the configuration
    /// - When:
    ///    - Invoke confirmSignUp api
    /// - Then:
    ///    - Plugin should pass the secret hash created with client secret
    ///
    func testClientSecretWithConfirmSignUp() async throws {

        self.mockIdentityProvider = MockIdentityProvider(
            mockConfirmSignUpResponse: { request in
                XCTAssertNotNil(request.secretHash)
                return .init()
            }
        )

        _ = try await self.plugin.confirmSignUp(
            for: "someuser",
            confirmationCode: "code",
            options: nil
        )
    }

    /// Test if client secret is used for revokeToken api
    ///
    /// - Given: Given auth plugin with client secret present in the configuration
    /// - When:
    ///    - Invoke signOut api
    /// - Then:
    ///    - Plugin should pass the secret hash created with client secret
    ///
    func testClientSecretWithRevokeToken() async {
        self.mockIdentityProvider = MockIdentityProvider(
            mockRevokeTokenResponse: { request in
                XCTAssertNotNil(request.clientSecret)
                return .testData
            }, mockGlobalSignOutResponse: { _ in
                return .testData
            })
        guard let result = await plugin.signOut() as? AWSCognitoSignOutResult,
              case .complete = result else {
            XCTFail("Did not return complete signOut")
            return
        }
    }

    /// Test if client secret is used for initiateAuth, respondToAuthChallenge api
    ///
    /// - Given: Given auth plugin with client secret present in the configuration
    /// - When:
    ///    - Invoke signOut api
    /// - Then:
    ///    - Plugin should pass the secret hash created with client secret
    ///
    func testClientSecretWithInitiateAuth() async {

        self.mockIdentityProvider = MockIdentityProvider(
            mockRevokeTokenResponse: { request in
                XCTAssertNotNil(request.clientSecret)
                return .testData
            }, mockInitiateAuthResponse: { request in
                XCTAssertNotNil(request.authParameters?["SECRET_HASH"])
                return InitiateAuthOutputResponse(
                    authenticationResult: .none,
                    challengeName: .passwordVerifier,
                    challengeParameters: InitiateAuthOutputResponse.validChalengeParams,
                    session: "someSession")

            }, mockGlobalSignOutResponse: { _ in
                return .testData

            }, mockRespondToAuthChallengeResponse: { request in
                XCTAssertNotNil(request.challengeResponses?["SECRET_HASH"])
                return RespondToAuthChallengeOutputResponse(
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

        _ = await plugin.signOut()
        
        let pluginOptions = AWSAuthSignInOptions(validationData: ["somekey": "somevalue"],
                                                 metadata: ["somekey": "somevalue"])
        let options = AuthSignInRequest.Options(pluginOptions: pluginOptions)

        do {
            let result = try await plugin.signIn(
                username: "username",
                password: "password",
                options: options)
            guard case .done = result.nextStep else {
                XCTFail("Result should be .done for next step")
                return
            }
            XCTAssertTrue(result.isSignedIn, "Signin result should be complete")
        } catch {
            XCTFail("Received failure with error \(error)")
        }
    }
}
