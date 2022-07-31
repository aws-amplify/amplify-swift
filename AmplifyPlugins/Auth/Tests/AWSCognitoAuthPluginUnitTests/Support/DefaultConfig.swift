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

    static let validAccessToken = "eyJraWQiOiJRbWZIcnYyS1F2ZEtyRm5WYUNxbzd4MWM1ZjA3TFhFaFhZQ1VSSXU2eitvPSIsImFsZyI6IlJTMjU2In0.eyJzdWIiOiI0MjEzZGY1ZS1mNzBiLTQ0MDUtYjhiNC05NjMzMjRhNmUwYjgiLCJkZXZpY2Vfa2V5IjoidXMtZWFzdC0xXzUyMDYxOTFjLTY5N2QtNGEzNC1iYTZmLWVmMDcwOGFkMzk3OSIsImlzcyI6Imh0dHBzOlwvXC9jb2duaXRvLWlkcC51cy1lYXN0LTEuYW1hem9uYXdzLmNvbVwvdXMtZWFzdC0xX2w2bksxOUFMUSIsImNsaWVudF9pZCI6IjY5OW91OHRhcXZhaDVvYzA3M29zZmo4bzgyIiwib3JpZ2luX2p0aSI6ImViMDRiOTcwLTY5NDEtNDVlZS05NTQ1LTY4ODk1ZTNlMDAwZiIsImV2ZW50X2lkIjoiODYyM2JlZDctMTBhYi00YzM1LTk0MzctMzdlMWY2YTkxZDg1IiwidG9rZW5fdXNlIjoiYWNjZXNzIiwic2NvcGUiOiJhd3MuY29nbml0by5zaWduaW4udXNlci5hZG1pbiIsImF1dGhfdGltZSI6MTY1OTA2OTMwNywiZXhwIjoxNjU5MDcyOTA3LCJpYXQiOjE2NTkwNjkzMDcsImp0aSI6ImE2ZWQ2MWE1LTFiMGUtNDgyZC04YmY1LTI1M2JiYWRhNjFhYyIsInVzZXJuYW1lIjoiaW50ZWd0ZXN0OWRlMmVlNDctY2I4MS00YjdhLWI4OTAtOGMyYzczZjRkN2RmIn0.Mjl-G9QGXF8KwZbQrxd3uNaOf4EChzltfklRp7inuxLTFLuKQqena8VctiSUQp4jDnBEBXw2Hu3D5ZvVyGoL0FQamxMvtPRIVl050XEir_RKk6M_d9Qp4pdDNH1HwJ-id9CgpvA3xpgpIH09n2voTMbgGGLO-ivuCsJCa0IbsRUJwrua-wkr5g3-3mmFFqrNrqyFhvuQRWQ6DoVo_bjwp3WVYmNq69PaxxYYXw7b-86DGGOC4kqAvQD9WiZtu8ad63kc5zJ-MjtbKfJLK8L4cyW6ga-kZn-6MjDIn8UoToWOtLncfFM1sJiucFCcPdZoM2jBJA5WDT_0QDwAOBQjMg"

    static let validIdToken = "eyJraWQiOiJ1Z05CbHphK0tuQ2ZoT2l6a0ZSXC9SWldcL2lCZVwveEd2N1ZIZjR3eUxxSFhFPSIsImFsZyI6IlJTMjU2In0.eyJzdWIiOiI0MjEzZGY1ZS1mNzBiLTQ0MDUtYjhiNC05NjMzMjRhNmUwYjgiLCJlbWFpbF92ZXJpZmllZCI6ZmFsc2UsImlzcyI6Imh0dHBzOlwvXC9jb2duaXRvLWlkcC51cy1lYXN0LTEuYW1hem9uYXdzLmNvbVwvdXMtZWFzdC0xX2w2bksxOUFMUSIsImNvZ25pdG86dXNlcm5hbWUiOiJpbnRlZ3Rlc3Q5ZGUyZWU0Ny1jYjgxLTRiN2EtYjg5MC04YzJjNzNmNGQ3ZGYiLCJvcmlnaW5fanRpIjoiZWIwNGI5NzAtNjk0MS00NWVlLTk1NDUtNjg4OTVlM2UwMDBmIiwiYXVkIjoiNjk5b3U4dGFxdmFoNW9jMDczb3NmajhvODIiLCJldmVudF9pZCI6Ijg2MjNiZWQ3LTEwYWItNGMzNS05NDM3LTM3ZTFmNmE5MWQ4NSIsInRva2VuX3VzZSI6ImlkIiwiYXV0aF90aW1lIjoxNjU5MDY5MzA3LCJleHAiOjE2NTkwNzI5MDcsImlhdCI6MTY1OTA2OTMwNywianRpIjoiN2M3Y2ZlMzEtZjQ0NC00MjE4LWFmOGMtOGRlNjk1YmQ5Yzk5IiwiZW1haWwiOiJyb3lqaStwZW50ZXN0MUBhbWF6b24uY29tIn0.ZMtZEFv7K8tbCvsM6QcD1czC2KmCm-LGjrE_ew5a4cTk9kgGhy1JlArWA691YDapA9Humyk3EX2PBVSGam6-DJTqV13JhwzPKLsZFhm5u1QiddD8bqZRxJ_Wc2MFZnntox2iKUpE2fsmrxpSKsJtVLnUxjpy2s-4A-v6T-6MzSCWPmcC1lzi69ETd8cfqCVx2QH5BuE5aKQtUNB1LL-cOfg_LhMACJovwRvP3kGNyAjSmJp88GXQyayN4JO4zZU3vJ_Xx1P8tvsohvOMRiB69gA46uApSOhC1SWK5WBRKO8oYK969nxT9yvX2hv9yTQq1HyhYXtShdwzaGru3LY3Nw"

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

    static func makeDefaultASF() -> CognitoUserPoolASFBehavior {
        return MockASF()
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
                                                           cognitoUserPoolFactory: userPoolFactory,
                                                           cognitoUserPoolASFFactory: makeDefaultASF)
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

struct MockASF: CognitoUserPoolASFBehavior {
    func userContextData(deviceInfo: ASFDeviceBehavior,
                         appInfo: ASFAppInfoBehavior,
                         configuration: UserPoolConfigurationData) -> String {
        return ""
    }


}
