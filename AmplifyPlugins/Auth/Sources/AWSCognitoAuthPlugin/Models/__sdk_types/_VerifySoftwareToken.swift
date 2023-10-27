//
//  File.swift
//  
//
//  Created by Saultz, Ian on 10/26/23.
//

import Foundation

struct VerifySoftwareTokenInput: Equatable, Encodable {
    /// A valid access token that Amazon Cognito issued to the user whose software token you want to verify.
    var accessToken: String?
    /// The friendly device name.
    var friendlyDeviceName: String?
    /// The session that should be passed both ways in challenge-response calls to the service.
    var session: String?
    /// The one- time password computed using the secret code returned by [AssociateSoftwareToken](https://docs.aws.amazon.com/cognito-user-identity-pools/latest/APIReference/API_AssociateSoftwareToken.html).
    /// This member is required.
    var userCode: String?

    enum CodingKeys: String, CodingKey {
        case accessToken = "AccessToken"
        case friendlyDeviceName = "FriendlyDeviceName"
        case session = "Session"
        case userCode = "UserCode"
    }
}

struct VerifySoftwareTokenOutputResponse: Equatable, Decodable {
    /// The session that should be passed both ways in challenge-response calls to the service.
    var session: String?
    /// The status of the verify software token.
    var status: CognitoIdentityProviderClientTypes.VerifySoftwareTokenResponseType?

    enum CodingKeys: String, CodingKey {
        case session = "Session"
        case status = "Status"
    }
}
