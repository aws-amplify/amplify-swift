//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

package struct SignedInData {
    package let userId: String
    package let username: String
    package let signedInDate: Date
    package let signInMethod: SignInMethod
    package let deviceMetadata: DeviceMetadata
    package let cognitoUserPoolTokens: EngineUserPoolTokens
    package var isRefreshTokenExpired: Bool?
    package let inputUsername: String?

    package init(
        signedInDate: Date,
        signInMethod: SignInMethod,
        deviceMetadata: DeviceMetadata = .noData,
        cognitoUserPoolTokens: EngineUserPoolTokens,
        inputUsername: String? = nil
    ) {
        let user = try? TokenParserHelper.getAuthUser(accessToken: cognitoUserPoolTokens.accessToken)
        self.userId = user?.userId ?? "unknown"
        self.username = user?.username ?? "unknown"
        self.signedInDate = signedInDate
        self.signInMethod = signInMethod
        self.deviceMetadata = deviceMetadata
        self.cognitoUserPoolTokens = cognitoUserPoolTokens
        self.isRefreshTokenExpired = false
        self.inputUsername = inputUsername
    }
}

extension SignedInData: Codable { }

extension SignedInData: Equatable { }

extension SignedInData: CustomDebugDictionaryConvertible {
    package var debugDictionary: [String: Any] {
        [
            "userId": userId.maskedForLog(),
            "userName": username.maskedForLog(),
            "signedInDate": signedInDate,
            "signInMethod": signInMethod,
            "deviceMetadata": deviceMetadata,
            "tokens": cognitoUserPoolTokens,
            "refreshTokenExpired": isRefreshTokenExpired ?? false,
            "inputUsername": inputUsername.maskedForLog()
        ]
    }
}

extension SignedInData: CustomDebugStringConvertible {
    package var debugDescription: String {
        debugDictionary.debugDescription
    }
}
