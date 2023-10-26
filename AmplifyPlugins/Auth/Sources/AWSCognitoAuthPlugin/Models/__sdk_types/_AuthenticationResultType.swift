//
//  File.swift
//  
//
//  Created by Saultz, Ian on 10/26/23.
//

import Foundation

extension CognitoIdentityProviderClientTypes {
    /// The authentication result.
    struct AuthenticationResultType: Equatable {
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

        init(
            accessToken: String? = nil,
            expiresIn: Int = 0,
            idToken: String? = nil,
            newDeviceMetadata: CognitoIdentityProviderClientTypes.NewDeviceMetadataType? = nil,
            refreshToken: String? = nil,
            tokenType: String? = nil
        )
        {
            self.accessToken = accessToken
            self.expiresIn = expiresIn
            self.idToken = idToken
            self.newDeviceMetadata = newDeviceMetadata
            self.refreshToken = refreshToken
            self.tokenType = tokenType
        }
    }

}
