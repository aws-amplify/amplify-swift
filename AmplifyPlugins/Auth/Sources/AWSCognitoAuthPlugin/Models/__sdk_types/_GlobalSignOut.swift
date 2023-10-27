//
//  File.swift
//  
//
//  Created by Saultz, Ian on 10/26/23.
//

import Foundation

/// Represents the request to sign out all devices.
struct GlobalSignOutInput: Equatable, Encodable {
    /// A valid access token that Amazon Cognito issued to the user who you want to sign out.
    /// This member is required.
    var accessToken: String?

    enum CodingKeys: String, CodingKey {
        case accessToken = "AccessToken"
    }
}

/// The response to the request to sign out all devices.
struct GlobalSignOutOutputResponse: Equatable, Decodable {}
