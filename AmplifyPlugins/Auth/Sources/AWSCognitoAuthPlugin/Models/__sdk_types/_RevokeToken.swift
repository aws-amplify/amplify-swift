//
//  File.swift
//  
//
//  Created by Saultz, Ian on 10/26/23.
//

import Foundation

struct RevokeTokenInput: Equatable {
    /// The client ID for the token that you want to revoke.
    /// This member is required.
    var clientId: String?
    /// The secret for the client ID. This is required only if the client ID has a secret.
    var clientSecret: String?
    /// The refresh token that you want to revoke.
    /// This member is required.
    var token: String?

    enum CodingKeys: String, CodingKey {
        case clientId = "ClientId"
        case clientSecret = "ClientSecret"
        case token = "Token"
    }
}


struct RevokeTokenOutputResponse: Equatable {}
