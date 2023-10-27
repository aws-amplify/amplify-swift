//
//  File.swift
//  
//
//  Created by Saultz, Ian on 10/26/23.
//

import Foundation

/// Represents the request to forget the device.
struct ForgetDeviceInput: Equatable, Encodable {
    /// A valid access token that Amazon Cognito issued to the user whose registered device you want to forget.
    var accessToken: String?
    /// The device key.
    /// This member is required.
    var deviceKey: String?

    enum CodingKeys: String, CodingKey {
        case accessToken = "AccessToken"
        case deviceKey = "DeviceKey"
    }
}


struct ForgetDeviceOutputResponse: Equatable, Decodable {}
