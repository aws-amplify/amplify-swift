//
//  File.swift
//  
//
//  Created by Saultz, Ian on 10/26/23.
//

import Foundation

/// Represents the request to list the devices.
struct ListDevicesInput: Equatable {
    /// A valid access token that Amazon Cognito issued to the user whose list of devices you want to view.
    /// This member is required.
    var accessToken: String?
    /// The limit of the device request.
    var limit: Int?
    /// The pagination token for the list request.
    var paginationToken: String?

    enum CodingKeys: String, CodingKey {
        case accessToken = "AccessToken"
        case limit = "Limit"
        case paginationToken = "PaginationToken"
    }
}

/// Represents the response to list devices.
struct ListDevicesOutputResponse: Equatable {
    /// The devices returned in the list devices response.
    var devices: [CognitoIdentityProviderClientTypes.DeviceType]?
    /// The pagination token for the list device response.
    var paginationToken: String?

    enum CodingKeys: String, CodingKey {
        case devices = "Devices"
        case paginationToken = "PaginationToken"
    }
}
