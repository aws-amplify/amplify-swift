//
//  File.swift
//  
//
//  Created by Saultz, Ian on 10/26/23.
//

import Foundation

/// Represents the request to update the device status.
struct UpdateDeviceStatusInput: Equatable {
    /// A valid access token that Amazon Cognito issued to the user whose device status you want to update.
    /// This member is required.
    var accessToken: String?
    /// The device key.
    /// This member is required.
    var deviceKey: String?
    /// The status of whether a device is remembered.
    var deviceRememberedStatus: CognitoIdentityProviderClientTypes.DeviceRememberedStatusType?

    enum CodingKeys: String, CodingKey {
        case accessToken = "AccessToken"
        case deviceKey = "DeviceKey"
        case deviceRememberedStatus = "DeviceRememberedStatus"
    }
}

/// The response to the request to update the device status.
struct UpdateDeviceStatusOutputResponse: Equatable {}
