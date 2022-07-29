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
import AWSPluginsCore

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

    static func makeCredentialStoreOperationBehaviour() -> CredentialStoreStateBehaviour {
        return MockCredentialStoreOperationClient()
    }

    static func makeDefaultUserPool() throws -> CognitoUserPoolBehavior {
        return try CognitoIdentityProviderClient(region: regionString)
    }

    static func makeIdentity() throws -> CognitoIdentityBehavior {
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
        return MockIdentity(mockGetIdResponse: getId, mockGetCredentialsResponse: getCredentials)
    }

    static func makeDefaultUserPoolConfigData(withHostedUI: HostedUIConfigurationData? = nil)
    -> UserPoolConfigurationData {
        UserPoolConfigurationData(poolId: userPoolId,
                                  clientId: appClientId,
                                  region: regionString,
                                  clientSecret: appClientSecret,
                                  pinpointAppId: "",
                                  hostedUIConfig: withHostedUI)
    }

    static func makeIdentityConfigData() -> IdentityPoolConfigurationData {
        IdentityPoolConfigurationData(poolId: identityPoolId,
                                      region: regionString)
    }

    static func makeDefaultAuthConfigData(withHostedUI: HostedUIConfigurationData? = nil) -> AuthConfiguration {
        let userPoolConfigData = makeDefaultUserPoolConfigData(withHostedUI: withHostedUI)
        let identityConfigDate = makeIdentityConfigData()
        return .userPoolsAndIdentityPools(userPoolConfigData, identityConfigDate)
    }

    static func makeAmplifyStore() -> AmplifyAuthCredentialStoreBehavior {
        return MockAmplifyStore()
    }

    static func makeLegacyStore(service: String) -> KeychainStoreBehavior {
        return MockLegacyStore()
    }

    static func makeDefaultCredentialStoreEnvironment(
        amplifyStoreFactory: @escaping () -> AmplifyAuthCredentialStoreBehavior = makeAmplifyStore,
        legacyStoreFactory: @escaping (String) -> KeychainStoreBehavior = makeLegacyStore(service: )
    ) -> CredentialEnvironment {
        CredentialEnvironment(
            authConfiguration: makeDefaultAuthConfigData(),
            credentialStoreEnvironment: BasicCredentialStoreEnvironment(
                amplifyCredentialStoreFactory: amplifyStoreFactory,
                legacyKeychainStoreFactory: legacyStoreFactory
            )
        )
    }

    static func makeDefaultAuthEnvironment(
        authZEnvironment: BasicAuthorizationEnvironment? = nil,
        identityPoolFactory: @escaping () throws -> CognitoIdentityBehavior = makeIdentity,
        userPoolFactory: @escaping () throws -> CognitoUserPoolBehavior = makeDefaultUserPool,
        hostedUIEnvironment: HostedUIEnvironment? = nil
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
                                                                       userPoolEnvironment: userPoolEnvironment,
                                                                       hostedUIEnvironment: hostedUIEnvironment)
        let authorizationEnvironment = BasicAuthorizationEnvironment(
            identityPoolConfiguration: identityPoolConfigData,
            cognitoIdentityFactory: identityPoolFactory)
        let authEnv = AuthEnvironment(
            configuration: Defaults.makeDefaultAuthConfigData(),
            userPoolConfigData: userPoolConfigData,
            identityPoolConfigData: identityPoolConfigData,
            authenticationEnvironment: authenticationEnvironment,
            authorizationEnvironment: authZEnvironment ?? authorizationEnvironment,
            credentialStoreClientFactory: makeCredentialStoreOperationBehaviour,
            logger: Amplify.Logging.logger(forCategory: "awsCognitoAuthPluginTest")
        )
        Amplify.Logging.logLevel = .verbose
        return authEnv
    }

    static func makeDefaultAuthStateMachine(
        initialState: AuthState? = nil,
        identityPoolFactory: @escaping () throws -> CognitoIdentityBehavior = makeIdentity,
        userPoolFactory: @escaping () throws -> CognitoUserPoolBehavior = makeDefaultUserPool,
        hostedUIEnvironment: HostedUIEnvironment? = nil) ->
    AuthStateMachine {

        let environment = makeDefaultAuthEnvironment(identityPoolFactory: identityPoolFactory,
                                                     userPoolFactory: userPoolFactory,
                                                     hostedUIEnvironment: hostedUIEnvironment)
        return AuthStateMachine(resolver: AuthState.Resolver(),
                                environment: environment,
                                initialState: initialState)
    }

    static func makeDefaultCredentialStateMachine() -> CredentialStoreStateMachine {
        return CredentialStoreStateMachine(resolver: CredentialStoreState.Resolver(),
                                           environment: makeDefaultCredentialStoreEnvironment(),
                                           initialState: .idle)
    }

    static func authStateMachineWith(environment: AuthEnvironment = makeDefaultAuthEnvironment(),
                                     initialState: AuthState? = nil)
    -> AuthStateMachine {
            return AuthStateMachine(resolver: AuthState.Resolver(),
                                    environment: environment,
                                    initialState: initialState)
    }

    static func makeAuthState(userId: String,
                              userName: String,
                              signedInDate: Date = Date(),
                              signInMethod: SignInMethod = .unknown) -> AuthState {
        let tokens = makeCognitoUserPoolTokens()

        let signedInData = SignedInData(userId: userId,
                                        userName: userName,
                                        signedInDate: signedInDate,
                                        signInMethod: signInMethod,
                                        cognitoUserPoolTokens: tokens)

        let authNState: AuthenticationState = .signedIn(signedInData)
        let authZState: AuthorizationState = .configured
        let authState: AuthState = .configured(authNState, authZState)

        return authState
    }

    static func makeAuthConfiguration() -> AuthConfiguration {
        AuthConfiguration.userPoolsAndIdentityPools(
            Defaults.makeDefaultUserPoolConfigData(),
            Defaults.makeIdentityConfigData()
        )
    }

    static func makeCognitoUserPoolTokens(idToken: String = "XX",
                                             accessToken: String = "",
                                             refreshToken: String = "XX",
                                             expiresIn: Int = 300) -> AWSCognitoUserPoolTokens {
        AWSCognitoUserPoolTokens(idToken: idToken, accessToken: accessToken, refreshToken: refreshToken, expiresIn: expiresIn)
    }

}

struct MockCredentialStoreOperationClient: CredentialStoreStateBehaviour {

    func fetchData(type: CredentialStoreDataType) async throws -> CredentialStoreData {
        .amplifyCredentials(.testData)
    }

    func storeData(data: CredentialStoreData) async throws {

    }

    func deleteData(type: CredentialStoreDataType) async throws {

    }
}

struct MockAmplifyStore: AmplifyAuthCredentialStoreBehavior {
    func saveCredential(_ credential: Codable) throws {

    }

    func retrieveCredential() throws -> Codable {
        return AmplifyCredentials.noCredentials
    }

    func deleteCredential() throws {

    }

    func getKeychainStore() -> KeychainStoreBehavior {
        return MockLegacyStore()
    }

    func saveDevice(_ deviceMetadata: Codable, for username: String) throws {

    }

    func retrieveDevice(for username: String) throws -> Codable {
        return DeviceMetadata.noData
    }

    func removeDevice(for username: String) throws {

    }
}

struct MockLegacyStore: KeychainStoreBehavior {
    func _getString(_ key: String) throws -> String {
        return ""
    }

    func _getData(_ key: String) throws -> Data {
        return Data()
    }

    func _set(_ value: String, key: String) throws {

    }

    func _set(_ value: Data, key: String) throws {

    }

    func _remove(_ key: String) throws {

    }

    func _removeAll() throws {

    }

}
