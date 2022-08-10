//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

struct SignedInData {
    let userId: String
    let userName: String
    let signedInDate: Date
    let signInMethod: SignInMethod
    let deviceMetadata: DeviceMetadata
    let cognitoUserPoolTokens: AWSCognitoUserPoolTokens

    init(signedInDate: Date,
         signInMethod: SignInMethod,
         deviceMetadata: DeviceMetadata = .noData,
         cognitoUserPoolTokens: AWSCognitoUserPoolTokens
    ) {
        let user = try? TokenParserHelper.getAuthUser(accessToken: cognitoUserPoolTokens.accessToken)
        self.userId = user?.userId ?? "unknown"
        self.userName = user?.username ?? "unknown"
        self.signedInDate = signedInDate
        self.signInMethod = signInMethod
        self.deviceMetadata = deviceMetadata
        self.cognitoUserPoolTokens = cognitoUserPoolTokens
    }
}

extension SignedInData: Codable { }

extension SignedInData: Equatable { }

extension SignedInData: CustomDebugDictionaryConvertible {
    var debugDictionary: [String: Any] {
        [
            "userId": userId.masked(),
            "userName": userName.masked(),
            "signedInDate": signedInDate,
            "signInMethod": signInMethod,
            "deviceMetadata": deviceMetadata,
            "tokens": cognitoUserPoolTokens
        ]
    }
}

extension SignedInData: CustomDebugStringConvertible {
    var debugDescription: String {
        debugDictionary.debugDescription
    }
}
