//
//  File.swift
//  
//
//  Created by Saultz, Ian on 10/26/23.
//

import Foundation

extension CognitoIdentityProviderClientTypes {
    /// The authentication result.
    struct AuthenticationResultType: Equatable, Codable {
        /// A valid access token that Amazon Cognito issued to the user who you want to authenticate.
        var accessToken: String?
        /// The expiration period of the authentication result in seconds.
        var expiresIn: Int
        /// The ID token.
        var idToken: String?
        /// The new device metadata from an authentication result.
        var newDeviceMetadata: CognitoIdentityProviderClientTypes.NewDeviceMetadataType?
        /// The refresh token.
        var refreshToken: String?
        /// The token type.
        var tokenType: String?

        enum CodingKeys: String, CodingKey {
            case accessToken = "AccessToken"
            case expiresIn = "ExpiresIn"
            case idToken = "IdToken"
            case newDeviceMetadata = "NewDeviceMetadata"
            case refreshToken = "RefreshToken"
            case tokenType = "TokenType"
        }
    }
}
