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

    @available(*, deprecated, message: "Use of `init(idToken,accessToken,refreshToken:expiresIn)` is deprecated, use `exp` claim in the `idToken` or `accessToken` instead")
    public init(idToken: String,
                accessToken: String,
                refreshToken: String,
                expiresIn: Int) {
        self.idToken = idToken
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expiration = Date().addingTimeInterval(TimeInterval(expiresIn))
    }

    @available(*, deprecated, message: "Use of `init(idToken,accessToken,refreshToken:expiration)` is deprecated, use `exp` claim in the `idToken` or `accessToken` instead")
    public init(idToken: String,
                accessToken: String,
                refreshToken: String,
                expiration: Date) {
        self.idToken = idToken
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expiration = expiration
    }

    init(idToken: String,
         accessToken: String,
         refreshToken: String,
         expiresIn: Int? = nil) {

        self.idToken = idToken
        self.accessToken = accessToken
        self.refreshToken = refreshToken

        if let expiresIn =  expiresIn {
            self.expiration = Date().addingTimeInterval(TimeInterval(expiresIn))
        } else {
            let expirationDoubleValue: Double
            let idTokenExpiration = try? AWSAuthService().getTokenClaims(tokenString: idToken).get()["exp"]?.doubleValue
            let accessTokenExpiration = try? AWSAuthService().getTokenClaims(tokenString: accessToken).get()["exp"]?.doubleValue

            switch (idTokenExpiration, accessTokenExpiration) {
            case (.some(let idTokenValue), .some(let accessTokenValue)):
                expirationDoubleValue = min(idTokenValue, accessTokenValue)
            case (.none, .some(let accessTokenValue)):
                expirationDoubleValue = accessTokenValue
            case (.some(let idTokenValue), .none):
                expirationDoubleValue = idTokenValue
            case (.none, .none):
                expirationDoubleValue = 0
            }

            self.expiration = Date().addingTimeInterval(TimeInterval((expirationDoubleValue ?? 0)))
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
