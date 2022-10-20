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
@testable import Amplify
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

    static func makeCredentialStoreOperationBehavior() -> CredentialStoreStateBehavior {
        return MockCredentialStoreOperationClient()
    }

    static func makeDefaultUserPool() throws -> CognitoUserPoolBehavior {
        return try CognitoIdentityProviderClient(region: regionString)
    }

    static func makeDefaultASF() -> AdvancedSecurityBehavior {
        return MockASF()
    }

    static func makeUserPoolAnalytics() -> UserPoolAnalyticsBehavior {
        MockAnalyticsHandler()
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
            ),
            logger: Amplify.Logging.logger(forCategory: "awsCognitoAuthPluginTest")
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
        let userPoolEnvironment = BasicUserPoolEnvironment(
            userPoolConfiguration: userPoolConfigData,
            cognitoUserPoolFactory: userPoolFactory,
            cognitoUserPoolASFFactory: makeDefaultASF,
            cognitoUserPoolAnalyticsHandlerFactory: makeUserPoolAnalytics)
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
            credentialsClient: makeCredentialStoreOperationBehavior(),
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

    static func makeAuthState(tokens: AWSCognitoUserPoolTokens,
                              signedInDate: Date = Date(),
                              signInMethod: SignInMethod = .apiBased(.userSRP)) -> AuthState {

        let signedInData = SignedInData(signedInDate: signedInDate,
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

struct MockCredentialStoreOperationClient: CredentialStoreStateBehavior {

    let mockAmplifyStore = MockAmplifyStore()

    func fetchData(type: CredentialStoreDataType) async throws -> CredentialStoreData {

        do {
            switch type {
            case .amplifyCredentials:
                let amplifyCredentials = try mockAmplifyStore.retrieveCredential()
                return .amplifyCredentials(amplifyCredentials)
            case .deviceMetadata(username: let username):
                let deviceMetadata = try mockAmplifyStore.retrieveDevice(for: username)
                return .deviceMetadata(deviceMetadata, username)
            case .asfDeviceId(username: let username):
                let device = try mockAmplifyStore.retrieveASFDevice(for: username)
                return .asfDeviceId(device, username)
            }
        }
        catch KeychainStoreError.itemNotFound {
            switch type {
            case .amplifyCredentials:
                return .amplifyCredentials(.testData)
            case .deviceMetadata(username: let username):
                return .deviceMetadata(.metadata(.init(
                    deviceKey: "key",
                    deviceGroupKey: "key",
                    deviceSecret: "secret")), username)
            case .asfDeviceId(username: let username):
                return .asfDeviceId("id", username)
            }
        }
        catch {
            fatalError()
        }
    }

    func storeData(data: CredentialStoreData) async throws {
        switch data {
        case .amplifyCredentials(let amplifyCredentials):
            try mockAmplifyStore.saveCredential(amplifyCredentials)
        case .deviceMetadata(let deviceMetadata, let username):
            try mockAmplifyStore.saveDevice(deviceMetadata, for: username)
        case .asfDeviceId(let string, let username):
            try mockAmplifyStore.saveASFDevice(string, for: username)
        }
    }

    func deleteData(type: CredentialStoreDataType) async throws {

    }
}

class MockAmplifyStore: AmplifyAuthCredentialStoreBehavior {
    let credentialsKey = "amplifyCredentials"
    static var dict = AtomicDictionary<String, Data>()

    func saveCredential(_ credential: AmplifyCredentials) throws {
        let value = (try? JSONEncoder().encode(credential)) ?? Data()
        Self.dict.set(value: value, forKey: credentialsKey)
    }

    func retrieveCredential() throws -> AmplifyCredentials {
        guard let data = Self.dict.getValue(forKey: credentialsKey),
              let cred = (try? JSONDecoder().decode(AmplifyCredentials.self, from: data)) else {
            throw KeychainStoreError.itemNotFound
        }
        return cred
    }

    func deleteCredential() throws {
        Self.dict.removeValue(forKey: credentialsKey)
    }

    func getKeychainStore() -> KeychainStoreBehavior {
        return MockLegacyStore()
    }

    func saveDevice(_ deviceMetadata: DeviceMetadata, for username: String) throws {
        let value = (try? JSONEncoder().encode(deviceMetadata)) ?? Data()
        Self.dict.set(value: value, forKey: username)
    }

    func retrieveDevice(for username: String) throws -> DeviceMetadata {
        guard let data = Self.dict.getValue(forKey: username),
              let device = (try? JSONDecoder().decode(DeviceMetadata.self, from: data)) else {
            throw KeychainStoreError.itemNotFound
        }
        return device
    }

    func removeDevice(for username: String) throws {
        Self.dict.removeValue(forKey: username)
    }

    func saveASFDevice(_ deviceId: String, for username: String) throws {
        let value = (try? JSONEncoder().encode(deviceId)) ?? Data()
        Self.dict.set(value: value, forKey: username)

    }

    func retrieveASFDevice(for username: String) throws -> String {
        guard let data = Self.dict.getValue(forKey: username),
              let device = (try? JSONDecoder().decode(String.self, from: data)) else {
            throw KeychainStoreError.itemNotFound
        }
        return device
    }

    func removeASFDevice(for username: String) throws {
        Self.dict.removeValue(forKey: username)
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

struct MockASF: AdvancedSecurityBehavior {
    func userContextData(for username: String,
                         deviceInfo: ASFDeviceBehavior,
                         appInfo: ASFAppInfoBehavior,
                         configuration: UserPoolConfigurationData) throws -> String {
        return ""
    }

}

extension AmplifyConfiguration {

    static func testData() -> AmplifyConfiguration {
        return try! AmplifyConfiguration.decodeAmplifyConfiguration(from: json.data(using: .utf8)!)
    }

    static let json: String = """
    {
    "UserAgent": "aws-amplify-cli/2.0",
    "Version": "1.0",
    "auth": {
        "plugins": {
            "awsCognitoAuthPlugin": {
                "UserAgent": "aws-amplify/cli",
                "Version": "0.1.0",
                "IdentityManager": {
                    "Default": {}
                },
                "CredentialsProvider": {
                    "CognitoIdentity": {
                        "Default": {
                            "PoolId": "us-east-1:XXX",
                            "Region": "us-east-1"
                        }
                    }
                },
                "CognitoUserPool": {
                    "Default": {
                        "PoolId": "us-east-1_XXX",
                        "AppClientId": "XXX",
                        "Region": "us-east-1"
                    }
                },
                "Auth": {
                    "Default": {
                        "OAuth": {
                            "WebDomain": "XXX-dev.auth.us-east-1.amazoncognito.com",
                            "AppClientId": "XXX",
                            "SignInRedirectURI": "myapp://",
                            "SignOutRedirectURI": "myapp://",
                            "Scopes": [
                                "phone",
                                "email",
                                "openid",
                                "profile",
                                "aws.cognito.signin.user.admin"
                            ]
                        },
                        "authenticationFlowType": "USER_SRP_AUTH",
                        "socialProviders": [
                            "GOOGLE"
                        ],
                        "usernameAttributes": [],
                        "signupAttributes": [
                            "EMAIL"
                        ],
                        "passwordProtectionSettings": {
                            "passwordPolicyMinLength": 8,
                            "passwordPolicyCharacters": []
                        },
                        "mfaConfiguration": "OFF",
                        "mfaTypes": [
                            "SMS"
                        ],
                        "verificationMechanisms": [
                            "EMAIL"
                        ]
                    }
                },
                "PinpointAnalytics": {
                    "Default": {
                        "AppId": "XXX",
                        "Region": "us-east-1"
                    }
                },
                "PinpointTargeting": {
                    "Default": {
                        "Region": "us-east-1"
                    }
                }
            }
        }
    }
    }
    """
}
