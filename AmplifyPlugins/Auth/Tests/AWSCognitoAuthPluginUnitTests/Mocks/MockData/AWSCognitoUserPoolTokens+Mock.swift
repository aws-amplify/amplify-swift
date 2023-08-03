//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
@testable import AWSCognitoAuthPlugin

extension AWSCognitoUserPoolTokens {

    static var testData: AWSCognitoUserPoolTokens {
        let tokenData = [
            "sub": "1234567890",
            "username": "John Doe",
            "iat": "1516239022",
            "exp": String(Date(timeIntervalSinceNow: 121).timeIntervalSince1970)
        ]
        return AWSCognitoUserPoolTokens(
            idToken: CognitoAuthTestHelper.buildToken(for: tokenData),
            accessToken: CognitoAuthTestHelper.buildToken(for: tokenData),
            refreshToken: "refreshToken",
            expiresIn: Int(Date(timeIntervalSinceNow: 121).timeIntervalSince1970))
    }

    static let expiredTestData = AWSCognitoUserPoolTokens(
        idToken: "XX", accessToken: "XX", refreshToken: "XX", expiresIn: -10000)

    static func testData(username: String, sub: String) -> AWSCognitoUserPoolTokens {
        let tokenData = [
            "sub": sub,
            "username": username,
            "iat": "1516239022",
            "exp": String(Date(timeIntervalSinceNow: 121).timeIntervalSince1970)
        ]
        return AWSCognitoUserPoolTokens(
            idToken: CognitoAuthTestHelper.buildToken(for: tokenData),
            accessToken: CognitoAuthTestHelper.buildToken(for: tokenData),
            refreshToken: "refreshToken",
            expiresIn: 121)
    }

    static var testDataWithoutExp: AWSCognitoUserPoolTokens {
        let tokenDataWithoutExp = [
            "sub": "1234567890",
            "username": "John Doe",
            "iat": "1516239022"
        ]
        return AWSCognitoUserPoolTokens(
            idToken: CognitoAuthTestHelper.buildToken(for: tokenDataWithoutExp),
            accessToken: CognitoAuthTestHelper.buildToken(for: tokenDataWithoutExp),
            refreshToken: "refreshToken",
            expiresIn: nil)
    }
}
