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
    let cognitoUserPoolTokens: AWSCognitoUserPoolTokens

    init(
        userId: String,
        userName: String,
        signedInDate: Date,
        signInMethod: SignInMethod,
        cognitoUserPoolTokens: AWSCognitoUserPoolTokens
    ) {
        self.userId = userId
        self.userName = userName
        self.signedInDate = signedInDate
        self.signInMethod = signInMethod
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
            "signInMethod": signInMethod
        ]
    }
}

extension SignedInData: CustomDebugStringConvertible {
    var debugDescription: String {
        debugDictionary.debugDescription
    }
}
