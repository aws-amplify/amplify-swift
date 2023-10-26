//
//  File.swift
//  
//
//  Created by Saultz, Ian on 10/26/23.
//

import Foundation

/// Represents the request to change a user password.
struct ChangePasswordInput: Equatable {
    /// A valid access token that Amazon Cognito issued to the user whose password you want to change.
    /// This member is required.
    var accessToken: String?
    /// The old password.
    /// This member is required.
    var previousPassword: String?
    /// The new password.
    /// This member is required.
    var proposedPassword: String?

    enum CodingKeys: String, CodingKey {
        case accessToken = "AccessToken"
        case previousPassword = "PreviousPassword"
        case proposedPassword = "ProposedPassword"
    }
}

/// The response from the server to the change password request.
struct ChangePasswordOutputResponse: Equatable {}
