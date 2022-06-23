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
import AWSCognitoIdentityProvider

class AWSCognitoAuthClientBehaviorTests: XCTestCase {
    
    var mockIdentityProvider: CognitoUserPoolBehavior!
    var plugin: AWSCognitoAuthPlugin!
    var initialState: AuthState {
        AuthState.configured(
            AuthenticationState.signedIn(
                SignedInData(userId: "test", userName: "test", signedInDate: Date(), signInMethod: .srp,
                             cognitoUserPoolTokens: AWSCognitoUserPoolTokens.testData)),
            AuthorizationState.sessionEstablished(AmplifyCredentials.testData))
    }
    
    override func setUp() {
        mockIdentityProvider = MockIdentityProvider(
            mockResendConfirmationCodeOutputResponse: { _ in
                ResendConfirmationCodeOutputResponse(codeDeliveryDetails: .init())
            }
        )
        
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
        
        _ = statemachine.listen { state in
            switch state {
            case .configured(_, let authorizationState):
                
                if case .waitingToStore(let credentials) = authorizationState {
                    let authEvent = AuthEvent.init(
                        eventType: .receivedCachedCredentials(credentials))
                    statemachine.send(authEvent)
                }
            default: break
            }
        } onSubscribe: {}
        
        plugin?.configure(
            authConfiguration: Defaults.makeDefaultAuthConfigData(),
            authEnvironment: environment,
            authStateMachine: statemachine,
            credentialStoreStateMachine: Defaults.makeDefaultCredentialStateMachine(),
            hubEventHandler: MockAuthHubEventBehavior())
    }
    
    /// Test resendSignUpCode operation can be invoked
    ///
    /// - Given: Given a configured auth plugin
    /// - When:
    ///    - I call resendSignUpCode operation
    /// - Then:
    ///    - I should get a valid operation object
    ///
    func testResendSignupCodeRequest() {
        let pluginOptions = ["somekey": "somevalue"]
        let options = AuthResendSignUpCodeRequest.Options(pluginOptions: pluginOptions)
        let operation = plugin.resendSignUpCode(for: "username", options: options)
        XCTAssertNotNil(operation)
    }
    
    /// Test resendSignUpCode operation can be invoked without options
    ///
    /// - Given: Given a configured auth plugin
    /// - When:
    ///    - I call resendSignUpCode operation
    /// - Then:
    ///    - I should get a valid operation object
    ///
    func testResendSignupCodeRequestWithoutOptions() {
        let operation = plugin.resendSignUpCode(for: "username")
        XCTAssertNotNil(operation)
    }
    
    override func tearDown() {
        plugin = nil
        Amplify.reset()
    }
}
