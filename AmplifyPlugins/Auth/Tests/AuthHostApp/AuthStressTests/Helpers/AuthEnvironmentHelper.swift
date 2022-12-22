//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
@testable import AWSCognitoAuthPlugin

enum Defaults {

    static let regionString = "us-east-1"
    static let identityPoolId = "XXX"
    static let userPoolId = "XXX_XX"
    static let appClientId = "XXX"
    static let appClientSecret = "XXX"

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

}

extension AuthAWSCognitoCredentials {

    static var testData: AuthAWSCognitoCredentials {
        return AuthAWSCognitoCredentials(
            accessKeyId: "xx",
            secretAccessKey: "xx",
            sessionToken: "xx",
            expiration: Date())
    }
}

extension AWSCognitoUserPoolTokens {

    static var testData: AWSCognitoUserPoolTokens {
        return AWSCognitoUserPoolTokens(idToken: "xx", accessToken: "xx", refreshToken: "xx", expiresIn: 300)
    }
}

extension SignedInData {

    static var testData: SignedInData {
        let tokens = AWSCognitoUserPoolTokens.testData
        return SignedInData(signedInDate: Date(),
                            signInMethod: .apiBased(.userSRP),
                            cognitoUserPoolTokens: tokens)
    }

}
