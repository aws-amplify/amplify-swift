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

    static func makeDefaultUserPoolConfigData() -> HostAppConfiguration.UserPool {
        HostAppConfiguration.userPool(
            poolId: userPoolId,
            clientId: appClientId,
            region: regionString,
            clientSecret: appClientSecret,
            pinpointAppId: ""
        )
    }

    static func makeIdentityConfigData() -> HostAppConfiguration.IdentityPool {
        HostAppConfiguration.identityPool(
            poolId: identityPoolId,
            region: regionString
        )
    }

}

extension AuthAWSCognitoCredentials {

    static var testData: AuthAWSCognitoCredentials {
        return AuthAWSCognitoCredentials(
            accessKeyId: "xx",
            secretAccessKey: "xx",
            sessionToken: "xx",
            expiration: Date()
        )
    }

    static var nonimmediateExpiryTestData: AuthAWSCognitoCredentials {
        return AuthAWSCognitoCredentials(
            accessKeyId: "xx",
            secretAccessKey: "xx",
            sessionToken: "xx",
            expiration: Date() + TimeInterval(200)
        )
    }
}

extension AWSCognitoUserPoolTokens {

    static var testData: AWSCognitoUserPoolTokens {
        return AWSCognitoUserPoolTokens(idToken: "xx", accessToken: "xx", refreshToken: "xx", expiresIn: 300)
    }
}

extension HostAppSignedInData {

    static var testData: HostAppSignedInData {
        let tokens = AWSCognitoUserPoolTokens.testData
        return HostAppSignedInData(
            signedInDate: Date(),
            signInMethod: .init(apiBased: .userSRP),
            cognitoUserPoolTokens: .init(tokens)
        )
    }

}
