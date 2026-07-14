//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// Request body for the `identifyUser` API.
struct IdentifyUserRequest: Encodable {
    let userId: String
    let userProfile: UserProfile
    let options: IdentifyUserOptions?
}

/// User profile attributes for the Connect Customer Profile.
///
/// Maps to standard profile fields (FirstName, LastName, EmailAddress)
/// plus custom attributes in the Attributes map.
public struct UserProfile: Sendable, Codable {
    public let email: String?
    public let name: String?
    public let plan: String?
    public let location: UserProfileLocation?
    public let customProperties: [String: [String]]?

    public init(
        email: String? = nil,
        name: String? = nil,
        plan: String? = nil,
        location: UserProfileLocation? = nil,
        customProperties: [String: [String]]? = nil
    ) {
        self.email = email
        self.name = name
        self.plan = plan
        self.location = location
        self.customProperties = customProperties
    }
}

/// Additional options for the `identifyUser` call.
public struct IdentifyUserOptions: Sendable, Codable {
    /// Custom user attributes to attach to the profile.
    public let userAttributes: [String: [String]]?

    /// Device push token address.
    public let address: String?

    /// Push notification channel type (e.g., "APNS", "APNS_SANDBOX", "GCM").
    public let channelType: String?

    /// Opt-out preference (e.g., "ALL", "NONE").
    public let optOut: String?

    /// Device identifier.
    public let deviceId: String?

    /// Platform name (e.g., "iOS", "Android").
    public let platform: String?

    /// Application version string.
    public let appVersion: String?

    /// Identity ID from a previous guest session.
    /// Passing this on an authenticated call triggers merge-on-sign-in,
    /// folding the prior guest profile (and its devices) into the
    /// authenticated profile.
    public let guestIdentityId: String?

    public init(
        userAttributes: [String: [String]]? = nil,
        address: String? = nil,
        channelType: String? = nil,
        optOut: String? = nil,
        deviceId: String? = nil,
        platform: String? = nil,
        appVersion: String? = nil,
        guestIdentityId: String? = nil
    ) {
        self.userAttributes = userAttributes
        self.address = address
        self.channelType = channelType
        self.optOut = optOut
        self.deviceId = deviceId
        self.platform = platform
        self.appVersion = appVersion
        self.guestIdentityId = guestIdentityId
    }
}

/// Location attributes for a user profile.
public struct UserProfileLocation: Sendable, Codable {
    public let city: String?
    public let region: String?
    public let country: String?
    public let postalCode: String?
    public let latitude: Double?
    public let longitude: Double?

    public init(
        city: String? = nil,
        region: String? = nil,
        country: String? = nil,
        postalCode: String? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil
    ) {
        self.city = city
        self.region = region
        self.country = country
        self.postalCode = postalCode
        self.latitude = latitude
        self.longitude = longitude
    }
}
