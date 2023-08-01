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

    public init(idToken: String,
                accessToken: String,
                refreshToken: String,
                expiresIn: Int? = nil) {

        if let expiresIn =  expiresIn {
            self.init(idToken: idToken,
                      accessToken: accessToken,
                      refreshToken: refreshToken,
                      expiresIn: expiresIn)
        } else {
            // If for some reason, failed to extract "exp" value, use the value as zero and don't block the user
            var expirationDoubleValue: Double = 0
            if let idTokenClaims = try? AWSAuthService().getTokenClaims(tokenString: idToken).get(),
               let accessTokenClaims = try? AWSAuthService().getTokenClaims(tokenString: accessToken).get(),
               let idTokenExpiration = idTokenClaims["exp"]?.doubleValue,
               let accessTokenExpiration = accessTokenClaims["exp"]?.doubleValue {
                expirationDoubleValue = min(idTokenExpiration, accessTokenExpiration)
            }
            self.init(idToken: idToken,
                      accessToken: accessToken,
                      refreshToken: refreshToken,
                      expiresIn: Int(expirationDoubleValue.rounded(.down)))
        }
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
