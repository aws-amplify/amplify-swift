//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import hierarchical_state_machine_swift

public struct SignedInData {
    public let userId: String
    public let userName: String
    public let signedInDate: Date
    public let signInMethod: SignInMethod
    public let cognitoUserPoolTokens: AWSCognitoUserPoolTokens
    
    public init(
        userId: String,
        userName: String,
        signedInDate: Date,
        signInMethod: SignInMethod,
        cognitoUserPollTokens: AWSCognitoUserPoolTokens
    ) {
        self.userId = userId
        self.userName = userName
        self.signedInDate = signedInDate
        self.signInMethod = signInMethod
        self.cognitoUserPoolTokens = cognitoUserPollTokens
    }
}

extension SignedInData: Codable { }

extension SignedInData: Equatable { }

extension SignedInData: CustomDebugDictionaryConvertible {
    public var debugDictionary: [String: Any] {
        [
            "userId": userId.masked(),
            "userName": userName.masked(),
            "signedInDate": signedInDate,
            "signInMethod": signInMethod
        ]
    }
}

extension SignedInData: CustomDebugStringConvertible {
    public var debugDescription: String {
        debugDictionary.debugDescription
    }
}
