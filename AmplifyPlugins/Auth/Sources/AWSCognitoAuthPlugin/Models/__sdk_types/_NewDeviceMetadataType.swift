//
//  File.swift
//  
//
//  Created by Saultz, Ian on 10/26/23.
//

import Foundation

extension CognitoIdentityProviderClientTypes {
    /// The new device metadata type.
    struct NewDeviceMetadataType: Equatable {
        /// The device group key.
        var deviceGroupKey: String?
        /// The device key.
        var deviceKey: String?

        enum CodingKeys: String, CodingKey {
            case deviceGroupKey = "DeviceGroupKey"
            case deviceKey = "DeviceKey"
        }
    }
}
