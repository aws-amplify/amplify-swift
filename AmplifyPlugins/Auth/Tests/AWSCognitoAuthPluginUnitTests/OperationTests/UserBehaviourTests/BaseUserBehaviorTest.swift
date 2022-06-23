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

class BaseUserBehaviorTest: XCTestCase {

    let apiTimeout = 2.0
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

    override func tearDown() {
        plugin = nil
        Amplify.reset()
    }
}
