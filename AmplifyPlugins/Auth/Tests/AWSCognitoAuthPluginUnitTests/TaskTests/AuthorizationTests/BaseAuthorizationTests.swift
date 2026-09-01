//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

import XCTest
@testable import AWSCognitoAuthPlugin

// `@unchecked Sendable`: `XCTestCase` is not `Sendable`, but the test body is captured by the
// `@Sendable` closures the API now takes. XCTest runs one test at a time.
class BaseAuthorizationTests: XCTestCase, @unchecked Sendable {

    let apiTimeout = 2.0

    func configurePluginWith(
        authConfiguration: AuthConfiguration = Defaults.makeDefaultAuthConfigData(),
        userPool: @escaping () throws -> CognitoUserPoolBehavior = Defaults.makeDefaultUserPool,
        identityPool: @escaping () throws -> CognitoIdentityBehavior = Defaults.makeIdentity,
        initialState: AuthState
    ) -> AWSCognitoAuthPlugin {
        let plugin = AWSCognitoAuthPlugin()
        let environment = Defaults.makeDefaultAuthEnvironment(
            identityPoolFactory: identityPool,
            userPoolFactory: userPool
        )
        let statemachine = AuthStateMachine(
            resolver: AuthState.Resolver(),
            environment: environment,
            initialState: initialState
        )
        plugin.configure(
            authConfiguration: Defaults.makeDefaultAuthConfigData(),
            authEnvironment: environment,
            authStateMachine: statemachine,
            credentialStoreStateMachine: Defaults.makeDefaultCredentialStateMachine(),
            hubEventHandler: MockAuthHubEventBehavior(),
            analyticsHandler: MockAnalyticsHandler()
        )
        return plugin

    }
}
