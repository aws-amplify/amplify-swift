//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
@testable import AWSCognitoAuthPlugin
import AWSCognitoIdentityProvider
import ClientRuntime
import hierarchical_state_machine_swift

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

    static func makeDefaultUserPoolConfigData() -> UserPoolConfigurationData {
        UserPoolConfigurationData(poolId: userPoolId,
                                  clientId: appClientId,
                                  region: regionString,
                                  clientSecret: appClientSecret,
                                  pinpointAppId: "")
    }

    static func makeDefaultAuthConfigData() -> AuthConfiguration {
        let userPoolConfigData = makeDefaultUserPoolConfigData()
        return .userPools(userPoolConfigData)
    }

    static func makeDefaultAuthEnvironment() -> AuthEnvironment {
        let userPoolConfigData = makeDefaultUserPoolConfigData()
        let srpAuthEnvironment = BasicSRPAuthEnvironment(
            userPoolConfiguration: userPoolConfigData,
            cognitoUserPoolFactory: makeDefaultUserPool
        )
        let srpSignInEnvironment = BasicSRPSignInEnvironment(srpAuthEnvironment: srpAuthEnvironment)
        let authenticationEnvironment = BasicAuthenticationEnvironment(srpSignInEnvironment: srpSignInEnvironment)
        let authEnv = AuthEnvironment(
            userPoolConfigData: userPoolConfigData,
            identityPoolConfigData: nil,
            authenticationEnvironment: authenticationEnvironment
        )
        return authEnv
    }

}
