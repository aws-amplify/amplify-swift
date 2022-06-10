//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
@testable import AWSCognitoAuthPlugin
import AWSCognitoIdentityProvider
import AWSCognitoIdentity
import ClientRuntime
import Amplify

enum Defaults {

    static let regionString = "us-east-1"
    static let identityPoolId = "XXX"
    static let userPoolId = "XXX_XX"
    static let appClientId = "XXX"
    static let appClientSecret = "XXX"

    static func authConfig() -> [String: Any] {
        let authConfig = [
            "UserAgent": "aws-amplify/cli",
            "Version": "0.1.0",
            "IdentityManager": [
                "Default": []
            ],
            "CredentialsProvider": [
                "CognitoIdentity": [
                    "Default": [
                        "PoolId": identityPoolId,
                        "Region": regionString
                    ]
                ]
            ],
            "CognitoIdentityProvider": [
                "Default": [
                    "PoolId": userPoolId,
                    "AppClientId": appClientId,
                    "AppClientSecret": appClientSecret,
                    "Region": regionString
                ]
            ],
            "Auth": [
                "Default": [
                    "authenticationFlowType": "USER_SRP_AUTH"
                ]
            ]
        ] as [String: Any]
        return authConfig
    }

    static func makeDefaultUserPool() throws -> CognitoUserPoolBehavior {
        return try CognitoIdentityProviderClient(region: regionString)
    }

    static func makeIdentity() throws -> CognitoIdentityBehavior {
        return try CognitoIdentityClient(region: regionString)
    }

    static func makeDefaultUserPoolConfigData() -> UserPoolConfigurationData {
        UserPoolConfigurationData(poolId: userPoolId,
                                  clientId: appClientId,
                                  region: regionString,
                                  clientSecret: appClientSecret,
                                  pinpointAppId: "")
    }

    static func makeIdentityConfigData() -> IdentityPoolConfigurationData {
        IdentityPoolConfigurationData(poolId: identityPoolId,
                                      region: regionString)
    }

    static func makeDefaultAuthConfigData() -> AuthConfiguration {
        let userPoolConfigData = makeDefaultUserPoolConfigData()
        let identityConfigDate = makeIdentityConfigData()
        return .userPoolsAndIdentityPools(userPoolConfigData, identityConfigDate)
    }

    static func makeAmplifyStore() -> AmplifyAuthCredentialStoreBehavior &
    AmplifyAuthCredentialStoreProvider {
        return MockAmplifyStore()
    }

    static func makeLegacyStore(service: String) -> CredentialStoreBehavior {
        return MockLegacyStore()
    }

    static func makeDefaultCredentialStoreEnvironment(
        amplifyStoreFactory: @escaping () -> AmplifyAuthCredentialStoreBehavior &
        AmplifyAuthCredentialStoreProvider = makeAmplifyStore,
        legacyStoreFactory: @escaping (String) -> CredentialStoreBehavior = makeLegacyStore(service: )
    ) -> CredentialEnvironment {
        CredentialEnvironment(
            authConfiguration: makeDefaultAuthConfigData(),
            credentialStoreEnvironment: BasicCredentialStoreEnvironment(
                amplifyCredentialStoreFactory: amplifyStoreFactory,
                legacyCredentialStoreFactory: legacyStoreFactory
            )
        )
    }

    static func makeDefaultAuthEnvironment(
        authZEnvironment: BasicAuthorizationEnvironment? = nil,
        identityPoolFactory: @escaping () throws -> CognitoIdentityBehavior = makeIdentity,
        userPoolFactory: @escaping () throws -> CognitoUserPoolBehavior = makeDefaultUserPool
    ) -> AuthEnvironment {
        let userPoolConfigData = makeDefaultUserPoolConfigData()
        let identityPoolConfigData = makeIdentityConfigData()
        let srpAuthEnvironment = BasicSRPAuthEnvironment(
            userPoolConfiguration: userPoolConfigData,
            cognitoUserPoolFactory: userPoolFactory
        )
        let srpSignInEnvironment = BasicSRPSignInEnvironment(srpAuthEnvironment: srpAuthEnvironment)
        let userPoolEnvironment = BasicUserPoolEnvironment(userPoolConfiguration: userPoolConfigData,
                                                           cognitoUserPoolFactory: userPoolFactory)
        let authenticationEnvironment = BasicAuthenticationEnvironment(srpSignInEnvironment: srpSignInEnvironment,
                                                                       userPoolEnvironment: userPoolEnvironment)
        let authorizationEnvironment = BasicAuthorizationEnvironment(
            identityPoolConfiguration: identityPoolConfigData,
            cognitoIdentityFactory: identityPoolFactory)
        let authEnv = AuthEnvironment(
            configuration: Defaults.makeDefaultAuthConfigData(),
            userPoolConfigData: userPoolConfigData,
            identityPoolConfigData: identityPoolConfigData,
            authenticationEnvironment: authenticationEnvironment,
            authorizationEnvironment: authZEnvironment ?? authorizationEnvironment,
            logger: Amplify.Logging.logger(forCategory: "awsCognitoAuthPluginTest")
        )
        Amplify.Logging.logLevel = .verbose
        return authEnv
    }

    static func makeDefaultAuthStateMachine(
        initialState: AuthState? = nil,
        identityPoolFactory: @escaping () throws -> CognitoIdentityBehavior = makeIdentity,
        userPoolFactory: @escaping () throws -> CognitoUserPoolBehavior = makeDefaultUserPool) ->
    AuthStateMachine {

        let environment = makeDefaultAuthEnvironment(identityPoolFactory: identityPoolFactory,
                                                     userPoolFactory: userPoolFactory)
        return AuthStateMachine(resolver: AuthState.Resolver(),
                                environment: environment,
                                initialState: initialState)
    }

    static func makeDefaultCredentialStateMachine() -> CredentialStoreStateMachine {
        return CredentialStoreStateMachine(resolver: CredentialStoreState.Resolver(),
                                           environment: makeDefaultCredentialStoreEnvironment(),
                                           initialState: .idle)
    }

}

struct MockAmplifyStore: AmplifyAuthCredentialStoreBehavior, AmplifyAuthCredentialStoreProvider {
    func saveCredential(_ credential: AmplifyCredentials) throws {

    }

    func retrieveCredential() throws -> AmplifyCredentials {
        return AmplifyCredentials(userPoolTokens: nil, identityId: nil, awsCredential: nil)
    }

    func deleteCredential() throws {

    }

    func getCredentialStore() -> CredentialStoreBehavior {
        return MockLegacyStore()
    }
}

struct MockLegacyStore: CredentialStoreBehavior {
    func getString(_ key: String) throws -> String {
        return ""
    }

    func getData(_ key: String) throws -> Data {
        return Data()
    }

    func set(_ value: String, key: String) throws {

    }

    func set(_ value: Data, key: String) throws {

    }

    func remove(_ key: String) throws {

    }

    func removeAll() throws {

    }

}
