//
//  File.swift
//  
//
//  Created by Saultz, Ian on 10/26/23.
//

import Foundation

/// Represents the request to delete a user.
struct DeleteUserInput: Equatable {
    /// A valid access token that Amazon Cognito issued to the user whose user profile you want to delete.
    /// This member is required.
    var accessToken: String?

    enum CodingKeys: String, CodingKey {
        case accessToken = "AccessToken"
    }
}

struct DeleteUserOutputResponse: Equatable {}
