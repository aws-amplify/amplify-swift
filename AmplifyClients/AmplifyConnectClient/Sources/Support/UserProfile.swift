//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// Request body for the `identify-user` route.
struct IdentifyUserRequest: Encodable {
    let userProfile: UserProfile
}

/// Request body for the `register-device` route.
struct RegisterDeviceRequest: Encodable {
    let device: Device
}

/// Device payload for the `register-device` route.
struct Device: Encodable {
    let token: String
    let deviceId: String
    let platform: String?
    let appVersion: String?
    let channelType: ChannelType
}

/// Request body for the `remove-device` route.
struct RemoveDeviceRequest: Encodable {
    let deviceId: String
}

/// User profile attributes for the Connect Customer Profile.
///
/// Maps to standard profile fields (email, name, phone, location)
/// plus free-form string attributes in `customAttributes`.
public struct UserProfile: Sendable, Codable {
    public let email: String?
    public let name: String?
    public let phone: String?
    public let customAttributes: [String: String]?
    public let location: UserProfileLocation?

    public init(
        email: String? = nil,
        name: String? = nil,
        phone: String? = nil,
        customAttributes: [String: String]? = nil,
        location: UserProfileLocation? = nil
    ) {
        self.email = email
        self.name = name
        self.phone = phone
        self.customAttributes = customAttributes
        self.location = location
    }
}

/// Push notification channel type.
public enum ChannelType: String, Sendable, Codable {
    case apns = "APNS"
    case apnsSandbox = "APNS_SANDBOX"
    case gcm = "GCM"
}

/// Location attributes for a user profile.
public struct UserProfileLocation: Sendable, Codable {
    public let city: String?
    public let country: String?
    public let postalCode: String?
    public let region: String?

    public init(
        city: String? = nil,
        country: String? = nil,
        postalCode: String? = nil,
        region: String? = nil
    ) {
        self.city = city
        self.country = country
        self.postalCode = postalCode
        self.region = region
    }
}
