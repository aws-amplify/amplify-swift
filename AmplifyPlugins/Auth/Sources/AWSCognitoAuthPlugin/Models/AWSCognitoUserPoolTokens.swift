//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public protocol AuthCognitoTokens {

    var idToken: String {get}

    var accessToken: String {get}

    var refreshToken: String {get}
}

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

}

extension AWSCognitoUserPoolTokens: Equatable { }

extension AWSCognitoUserPoolTokens: Codable { }

