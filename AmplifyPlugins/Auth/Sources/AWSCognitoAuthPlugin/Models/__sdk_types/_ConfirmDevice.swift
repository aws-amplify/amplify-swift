//
//  File.swift
//  
//
//  Created by Saultz, Ian on 10/26/23.
//

import Foundation

/// Confirms the device request.
struct ConfirmDeviceInput: Equatable, Encodable {
    /// A valid access token that Amazon Cognito issued to the user whose device you want to confirm.
    /// This member is required.
    var accessToken: String?
    /// The device key.
    /// This member is required.
    var deviceKey: String?
    /// The device name.
    var deviceName: String?
    /// The configuration of the device secret verifier.
    var deviceSecretVerifierConfig: CognitoIdentityProviderClientTypes.DeviceSecretVerifierConfigType?

    enum CodingKeys: String, CodingKey {
        case accessToken = "AccessToken"
        case deviceKey = "DeviceKey"
        case deviceName = "DeviceName"
        case deviceSecretVerifierConfig = "DeviceSecretVerifierConfig"
    }
}

/// Confirms the device response.
struct ConfirmDeviceOutputResponse: Equatable, Decodable {
    /// Indicates whether the user confirmation must confirm the device response.
    var userConfirmationNecessary: Bool

    enum CodingKeys: String, CodingKey {
        case userConfirmationNecessary = "UserConfirmationNecessary"
    }
}
