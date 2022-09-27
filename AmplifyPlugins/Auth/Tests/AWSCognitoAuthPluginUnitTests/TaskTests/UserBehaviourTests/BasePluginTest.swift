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

class BasePluginTest: XCTestCase {

    let apiTimeout = 2.0
    var mockIdentityProvider: CognitoUserPoolBehavior!
    var plugin: AWSCognitoAuthPlugin!

    var initialState: AuthState {
        AuthState.configured(
            AuthenticationState.signedIn(
                SignedInData(signedInDate: Date(),
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
            hubEventHandler: MockAuthHubEventBehavior())
    }

    func configureCustomPluginWith(
        authConfiguration: AuthConfiguration = Defaults.makeDefaultAuthConfigData(),
        userPool: @escaping () throws -> CognitoUserPoolBehavior = Defaults.makeDefaultUserPool,
        identityPool: @escaping () throws -> CognitoIdentityBehavior = Defaults.makeIdentity,
        initialState: AuthState) -> AWSCognitoAuthPlugin {
            let plugin = AWSCognitoAuthPlugin()
            let environment = Defaults.makeDefaultAuthEnvironment(
                identityPoolFactory: identityPool,
                userPoolFactory: userPool)
            let statemachine = AuthStateMachine(resolver: AuthState.Resolver(),
                                                environment: environment,
                                                initialState: initialState)
            plugin.configure(
                authConfiguration: Defaults.makeDefaultAuthConfigData(),
                authEnvironment: environment,
                authStateMachine: statemachine,
                credentialStoreStateMachine: Defaults.makeDefaultCredentialStateMachine(),
                hubEventHandler: MockAuthHubEventBehavior())
            return plugin
    }


    override func tearDown() async throws {
        plugin = nil
        await Amplify.reset()
    }
}
