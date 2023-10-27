//
//  File.swift
//  
//
//  Created by Saultz, Ian on 10/26/23.
//

import Foundation

struct VerifyUserAttributeInput: Equatable, Encodable {
    /// A valid access token that Amazon Cognito issued to the user whose user attributes you want to verify.
    /// This member is required.
    var accessToken: String?
    /// The attribute name in the request to verify user attributes.
    /// This member is required.
    var attributeName: String?
    /// The verification code in the request to verify user attributes.
    /// This member is required.
    var code: String?

    enum CodingKeys: String, CodingKey {
        case accessToken = "AccessToken"
        case attributeName = "AttributeName"
        case code = "Code"
    }
}

/// A container representing the response from the server from the request to verify user attributes.
struct VerifyUserAttributeOutputResponse: Equatable, Decodable {}
