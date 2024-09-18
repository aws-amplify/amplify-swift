//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSPinpoint
import Foundation

extension PinpointClientTypes.EndpointLocation: Codable, Equatable {
    private enum CodingKeys: CodingKey {
        case city
        case country
        case latitude
        case longitude
        case postalCode
        case region
    }

    public static func == (
        lhs: PinpointClientTypes.EndpointLocation,
        rhs: PinpointClientTypes.EndpointLocation
    ) -> Bool {
        return lhs.city == rhs.city
            && lhs.country == rhs.country
            && lhs.latitude == rhs.latitude
            && lhs.longitude == rhs.longitude
            && lhs.postalCode == rhs.postalCode
            && lhs.region == rhs.region
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(
            city: container.decodeIfPresent(String.self, forKey: .city),
            country: container.decodeIfPresent(String.self, forKey: .country),
            latitude: container.decodeIfPresent(Double.self, forKey: .latitude),
            longitude: container.decodeIfPresent(Double.self, forKey: .longitude),
            postalCode: container.decodeIfPresent(String.self, forKey: .postalCode),
            region: container.decodeIfPresent(String.self, forKey: .region)
        )
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(city, forKey: .city)
        try container.encodeIfPresent(country, forKey: .country)
        try container.encodeIfPresent(latitude, forKey: .latitude)
        try container.encodeIfPresent(longitude, forKey: .longitude)
        try container.encodeIfPresent(postalCode, forKey: .postalCode)
        try container.encodeIfPresent(region, forKey: .region)
    }
}

extension PinpointClientTypes.EndpointDemographic: Codable, Equatable {
    private enum CodingKeys: CodingKey {
        case appVersion
        case locale
        case make
        case model
        case modelVersion
        case platform
        case platformVersion
        case timezone
    }

    public static func == (
        lhs: PinpointClientTypes.EndpointDemographic,
        rhs: PinpointClientTypes.EndpointDemographic
    ) -> Bool {
        return lhs.appVersion == rhs.appVersion
            && lhs.locale == rhs.locale
            && lhs.make == rhs.make
            && lhs.model == rhs.model
            && lhs.modelVersion == rhs.modelVersion
            && lhs.platform == rhs.platform
            && lhs.platformVersion == rhs.platformVersion
            && lhs.timezone == rhs.timezone
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(
            appVersion: container.decodeIfPresent(String.self, forKey: .appVersion),
            locale: container.decodeIfPresent(String.self, forKey: .locale),
            make: container.decodeIfPresent(String.self, forKey: .make),
            model: container.decodeIfPresent(String.self, forKey: .model),
            modelVersion: container.decodeIfPresent(String.self, forKey: .modelVersion),
            platform: container.decodeIfPresent(String.self, forKey: .platform),
            platformVersion: container.decodeIfPresent(String.self, forKey: .platformVersion),
            timezone: container.decodeIfPresent(String.self, forKey: .timezone)
        )
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(appVersion, forKey: .appVersion)
        try container.encodeIfPresent(locale, forKey: .locale)
        try container.encodeIfPresent(make, forKey: .make)
        try container.encodeIfPresent(model, forKey: .model)
        try container.encodeIfPresent(modelVersion, forKey: .modelVersion)
        try container.encodeIfPresent(platform, forKey: .platform)
        try container.encodeIfPresent(platformVersion, forKey: .platformVersion)
        try container.encodeIfPresent(timezone, forKey: .timezone)
    }
}

extension PinpointClientTypes.EndpointUser: Codable, Equatable {
    private enum CodingKeys: CodingKey {
        case userAttributes
        case userId
    }

    public static func == (
        lhs: PinpointClientTypes.EndpointUser, 
        rhs: PinpointClientTypes.EndpointUser
    ) -> Bool {
        return lhs.userAttributes == rhs.userAttributes
            && lhs.userId == rhs.userId
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(
            userAttributes: container.decodeIfPresent([String: [String]].self, forKey: .userAttributes),
            userId: container.decodeIfPresent(String.self, forKey: .userId)
        )
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(userAttributes, forKey: .userAttributes)
        try container.encodeIfPresent(userId, forKey: .userId)
    }
}
