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
//        return try CognitoIdentityProviderClient(region: regionString)
        return try getCognitoIdentityProviderClient(region: regionString)
    }
    
    static private func getCognitoIdentityProviderClient(region: String) throws -> CognitoIdentityProviderClient {
        let group = DispatchGroup()
        group.enter()

        var result: Result<CognitoIdentityProviderClient, Error>!
        let setResult: (Result<CognitoIdentityProviderClient, Error>) -> Void = {
            result = $0
            group.leave()
        }

        group.enter()
        Task {
            do {
                let value = try await CognitoIdentityProviderClient(region: region)
                setResult(.success(value))
            } catch {
                setResult(.failure(error))
            }
        }
        group.wait()

        return try result.get()
    }

    static func makeIdentity() throws -> CognitoIdentityBehavior {
//        return try CognitoIdentityClient(region: regionString)
        return try getCognitoIdentityClient(region: regionString)
    }
    
    static private func getCognitoIdentityClient(region: String) throws -> CognitoIdentityClient {
        let group = DispatchGroup()
        group.enter()

        var result: Result<CognitoIdentityClient, Error>!
        let setResult: (Result<CognitoIdentityClient, Error>) -> Void = {
            result = $0
            group.leave()
        }

        group.enter()
        Task {
            do {
                let value = try await CognitoIdentityClient(region: region)
                setResult(.success(value))
            } catch {
                setResult(.failure(error))
            }
        }
        group.wait()

        return try result.get()
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

    static func makeDefaultAuthEnvironment(
        authZEnvironment: BasicAuthorizationEnvironment? = nil
    ) -> AuthEnvironment {
        let userPoolConfigData = makeDefaultUserPoolConfigData()
        let identityPoolConfigData = makeIdentityConfigData()
        let srpAuthEnvironment = BasicSRPAuthEnvironment(
            userPoolConfiguration: userPoolConfigData,
            cognitoUserPoolFactory: makeDefaultUserPool
        )
        let srpSignInEnvironment = BasicSRPSignInEnvironment(srpAuthEnvironment: srpAuthEnvironment)
        let userPoolEnvironment = BasicUserPoolEnvironment(userPoolConfiguration: userPoolConfigData,
                                                           cognitoUserPoolFactory: makeDefaultUserPool)
        let authenticationEnvironment = BasicAuthenticationEnvironment(srpSignInEnvironment: srpSignInEnvironment,
                                                                       userPoolEnvironment: userPoolEnvironment)
        let authorizationEnvironment = BasicAuthorizationEnvironment(
            identityPoolConfiguration: identityPoolConfigData,
            cognitoIdentityFactory: makeIdentity)
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

}
