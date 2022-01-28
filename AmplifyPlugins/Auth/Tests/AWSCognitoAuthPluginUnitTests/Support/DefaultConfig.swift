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

    static func makeDefaultAuthEnvironment() -> AuthEnvironment {
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
            userPoolConfigData: userPoolConfigData,
            identityPoolConfigData: identityPoolConfigData,
            authenticationEnvironment: authenticationEnvironment,
            authorizationEnvironment: authorizationEnvironment,
            credentialStoreEnvironment: nil
        )
        return authEnv
    }

}
