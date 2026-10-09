//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// A user attribute and its value, as passed to `confirmSignIn`: for example, the required attributes of
/// a new-password challenge.
///
/// Mirrors Amplify core's `AuthUserAttribute`.
@_spi(AmplifyExperimental)
public struct AuthClientUserAttribute {

    /// The attribute.
    public let key: AuthClientUserAttributeKey

    /// Its value.
    public let value: String

    public init(_ key: AuthClientUserAttributeKey, value: String) {
        self.key = key
        self.value = value
    }
}

extension AuthClientUserAttribute: Equatable {}

extension AuthClientUserAttribute: Sendable {}

extension AuthClientUserAttributeKey {

    static let customAttributePrefix = "custom:"

    /// Every key with a fixed Cognito name, in declaration order: all but `custom` and `unknown`.
    static let standardKeys: [AuthClientUserAttributeKey] = [
        .address, .birthDate, .email, .emailVerified, .familyName, .gender, .givenName, .locale, .middleName,
        .name, .nickname, .phoneNumber, .phoneNumberVerified, .picture, .preferredUsername, .profile, .sub,
        .updatedAt, .website, .zoneInfo
    ]

    /// The key for a Cognito attribute name: the inverse of `cognitoName`, as the plugin's
    /// `AuthUserAttributeKey(rawValue:)` reads it. A standard name is its key, a `custom:` name is `.custom`
    /// with the prefix removed, and anything else is `.unknown` with the name unchanged.
    init(cognitoName name: String) {
        if let key = Self.standardKeys.first(where: { $0.cognitoName == name }) {
            self = key
        } else if name.hasPrefix(Self.customAttributePrefix) {
            self = .custom(String(name.dropFirst(Self.customAttributePrefix.count)))
        } else {
            self = .unknown(name)
        }
    }

    /// The attribute's Cognito name: what the service reads, and what the plugin's `rawValue` is.
    ///
    /// A copy of the plugin's `AuthUserAttributeKey+RawValue.swift` table, pinned by a test. Values are
    /// taken from https://docs.aws.amazon.com/cognito/latest/developerguide/user-pool-settings-attributes.html
    /// and https://openid.net/specs/openid-connect-core-1_0.html#StandardClaims.
    ///
    /// Internal, and deliberately not a `RawRepresentable` conformance: the client's model types map case
    /// to case, never through a raw value.
    var cognitoName: String {
        switch self {
        case .address: return "address"
        case .birthDate: return "birthdate"
        case .email: return "email"
        case .emailVerified: return "email_verified"
        case .familyName: return "family_name"
        case .gender: return "gender"
        case .givenName: return "given_name"
        case .locale: return "locale"
        case .middleName: return "middle_name"
        case .name: return "name"
        case .nickname: return "nickname"
        case .phoneNumber: return "phone_number"
        case .phoneNumberVerified: return "phone_number_verified"
        case .picture: return "picture"
        case .preferredUsername: return "preferred_username"
        case .profile: return "profile"
        case .sub: return "sub"
        case .updatedAt: return "updated_at"
        case .website: return "website"
        case .zoneInfo: return "zoneinfo"
        case .custom(let attribute): return Self.customAttributePrefix + attribute
        case .unknown(let name): return name
        }
    }
}
