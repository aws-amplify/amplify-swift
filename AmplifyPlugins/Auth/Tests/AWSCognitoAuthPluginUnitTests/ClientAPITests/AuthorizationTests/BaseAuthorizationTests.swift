//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

import XCTest
@testable import AWSCognitoAuthPlugin

class BaseAuthorizationTests: XCTestCase {

    let apiTimeout = 2.0

    func configurePluginWith(authConfiguration: AuthConfiguration = Defaults.makeDefaultAuthConfigData(),
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
            hubEventHandler: MockAuthHubEventBehavior(),
            analyticsHandler: MockAnalyticsHandler())
        return plugin

    }
}
