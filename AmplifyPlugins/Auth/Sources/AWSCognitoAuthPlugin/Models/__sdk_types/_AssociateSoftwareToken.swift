//
//  File.swift
//  
//
//  Created by Saultz, Ian on 10/26/23.
//

import Foundation

struct AssociateSoftwareTokenInput: Equatable, Encodable {
    /// A valid access token that Amazon Cognito issued to the user whose software token you want to generate.
    var accessToken: String?
    /// The session that should be passed both ways in challenge-response calls to the service. This allows authentication of the user as part of the MFA setup process.
    var session: String?

    enum CodingKeys: String, CodingKey {
        case accessToken = "AccessToken"
        case session = "Session"
    }
}

struct AssociateSoftwareTokenOutputResponse: Equatable, Decodable {
    /// A unique generated shared secret code that is used in the TOTP algorithm to generate a one-time code.
    var secretCode: String?
    /// The session that should be passed both ways in challenge-response calls to the service. This allows authentication of the user as part of the MFA setup process.
    var session: String?

    enum CodingKeys: String, CodingKey {
        case secretCode = "SecretCode"
        case session = "Session"
    }
}
