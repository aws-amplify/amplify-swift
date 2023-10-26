//
//  File.swift
//  
//
//  Created by Saultz, Ian on 10/26/23.
//

import Foundation

extension CognitoIdentityProviderClientTypes {
    /// The device type.
    public struct DeviceType: Equatable {
        /// The device attributes.
        public var deviceAttributes: [CognitoIdentityProviderClientTypes.AttributeType]?
        /// The creation date of the device.
        public var deviceCreateDate: Date?
        /// The device key.
        public var deviceKey: String?
        /// The date when the device was last authenticated.
        public var deviceLastAuthenticatedDate: Date?
        /// The date and time, in [ISO 8601](https://www.iso.org/iso-8601-date-and-time-format.html) format, when the item was modified.
        public var deviceLastModifiedDate: Date?

        enum CodingKeys: String, CodingKey {
            case deviceAttributes = "DeviceAttributes"
            case deviceCreateDate = "DeviceCreateDate"
            case deviceKey = "DeviceKey"
            case deviceLastAuthenticatedDate = "DeviceLastAuthenticatedDate"
            case deviceLastModifiedDate = "DeviceLastModifiedDate"
        }
    }

}
