//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSPluginsCore

public struct AWSCognitoUserPoolTokens: AuthCognitoTokens {

    public let idToken: String

    public let accessToken: String

    public let refreshToken: String

    public let expiration: Date

    public init(idToken: String,
                accessToken: String,
                refreshToken: String,
                expiresIn: Int) {
        self.idToken = idToken
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expiration = Date().addingTimeInterval(TimeInterval(expiresIn))
    }

    public init(idToken: String,
                accessToken: String,
                refreshToken: String,
                expiration: Date) {
        self.idToken = idToken
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expiration = expiration
    }

}

extension AWSCognitoUserPoolTokens: Equatable { }

extension AWSCognitoUserPoolTokens: Codable { }

extension AWSCognitoUserPoolTokens: CustomDebugDictionaryConvertible {
    var debugDictionary: [String: Any] {
        [
            "idToken": idToken.masked(interiorCount: 5),
            "accessToken": accessToken.masked(interiorCount: 5),
            "refreshToken": refreshToken.masked(interiorCount: 5),
            "expiry": expiration
        ]
    }
}

extension AWSCognitoUserPoolTokens: CustomDebugStringConvertible {
    public var debugDescription: String {
        debugDictionary.debugDescription
    }
}
