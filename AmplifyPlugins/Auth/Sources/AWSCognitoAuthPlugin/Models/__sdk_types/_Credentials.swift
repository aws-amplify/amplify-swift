//
//  File.swift
//  
//
//  Created by Saultz, Ian on 10/26/23.
//

import Foundation

extension CognitoIdentityClientTypes {
    /// Credentials for the provided identity ID.
    struct Credentials: Equatable {
        /// The Access Key portion of the credentials.
        var accessKeyId: String?
        /// The date at which these credentials will expire.
        var expiration: Date?
        /// The Secret Access Key portion of the credentials
        var secretKey: String?
        /// The Session Token portion of the credentials
        var sessionToken: String?

        enum CodingKeys: String, CodingKey {
            case accessKeyId = "AccessKeyId"
            case expiration = "Expiration"
            case secretKey = "SecretKey"
            case sessionToken = "SessionToken"
        }
    }
}
