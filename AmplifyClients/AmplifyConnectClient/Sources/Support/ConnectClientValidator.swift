//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Client-side input validation mirroring the backend's limits.
///
/// The backend rejects attribute values longer than 255 characters;
/// validating locally fails fast before any network call is made.
enum ConnectClientValidator {
    /// Maximum length for any attribute value, matching the backend's
    /// `MAX_ATTRIBUTE_LENGTH`.
    static let maxAttributeLength = 255

    /// Validates all user profile fields against the backend length limits.
    static func validate(_ profile: UserProfile) throws {
        try validate(profile.email, field: "userProfile.email")
        try validate(profile.name, field: "userProfile.name")
        try validate(profile.phone, field: "userProfile.phone")
        if let location = profile.location {
            try validate(location.city, field: "userProfile.location.city")
            try validate(location.country, field: "userProfile.location.country")
            try validate(location.postalCode, field: "userProfile.location.postalCode")
            try validate(location.region, field: "userProfile.location.region")
        }
        if let customAttributes = profile.customAttributes {
            for (key, value) in customAttributes {
                try validate(key, field: "userProfile.customAttributes key")
                try validate(value, field: "userProfile.customAttributes[\"\(key)\"]")
            }
        }
    }

    /// Validates a device token against the backend length limit.
    static func validateToken(_ token: String) throws {
        try validate(token, field: "token")
    }

    private static func validate(_ value: String?, field: String) throws {
        guard let value, value.count > maxAttributeLength else { return }
        throw ConnectError.validation(
            "\(field) exceeds the maximum length of \(maxAttributeLength) characters",
            "Shorten the value to at most \(maxAttributeLength) characters."
        )
    }
}
