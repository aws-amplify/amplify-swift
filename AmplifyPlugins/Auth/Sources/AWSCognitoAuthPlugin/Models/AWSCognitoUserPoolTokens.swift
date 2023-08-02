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

    @available(*, deprecated, message: "Use of `expiration` is deprecated, use `exp` claim in the `idToken` or `accessToken` for expiries")
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

            var expirationDoubleValue: Double? = nil
            if let idTokenExpiration = try? AWSAuthService().getTokenClaims(tokenString: idToken).get()["exp"]?.doubleValue {
                expirationDoubleValue = idTokenExpiration
            }
            if let accessTokenExpiration = try? AWSAuthService().getTokenClaims(tokenString: accessToken).get()["exp"]?.doubleValue {
                if let unwrappedExpirationDoubleValue = expirationDoubleValue {
                    expirationDoubleValue = min(unwrappedExpirationDoubleValue, accessTokenExpiration)
                } else {
                    expirationDoubleValue = accessTokenExpiration
                }
            }

            self.init(idToken: idToken,
                      accessToken: accessToken,
                      refreshToken: refreshToken,
                      // If for some reason, failed to extract "exp" value, use the value as zero and don't block the user
                      expiresIn: Int((expirationDoubleValue ?? 0).rounded(.down)))
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
