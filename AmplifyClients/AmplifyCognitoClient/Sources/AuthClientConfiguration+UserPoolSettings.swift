//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

// The user-pool settings `amplify_outputs.json` expresses beyond the pool identifiers. Each mirrors one
// `auth` key of the Gen2 schema, so a value read from the file keeps everything the file says. What the
// engine is given is derived from these by `EngineUserPoolSettings`, the way the plugin's
// `ConfigurationHelper` derives it.

@_spi(AmplifyExperimental)
public extension AuthClientConfiguration {

    /// The hosted UI (OAuth) settings: `auth.oauth`.
    struct OAuth: Sendable, Equatable {
        /// The Cognito domain, without a scheme.
        public let domain: String
        /// The OAuth scopes the hosted UI asks for, such as `openid` and `email`, in file order.
        public let scopes: [String]
        /// Every sign-in redirect URI, in file order. The hosted UI uses the first.
        public let redirectSignInURIs: [String]
        /// Every sign-out redirect URI, in file order. The hosted UI uses the first.
        public let redirectSignOutURIs: [String]
        /// The identity providers the app client allows, as the file names them (for example `GOOGLE`).
        public let identityProviders: [String]
        /// The OAuth response type, as the file names it (`code` or `token`).
        public let responseType: String

        /// Builds hosted UI settings from their parts, for a configuration not read from `amplify_outputs`.
        public init(
            domain: String,
            scopes: [String],
            redirectSignInURIs: [String],
            redirectSignOutURIs: [String],
            identityProviders: [String] = [],
            responseType: String = "code"
        ) {
            self.domain = domain
            self.scopes = scopes
            self.redirectSignInURIs = redirectSignInURIs
            self.redirectSignOutURIs = redirectSignOutURIs
            self.identityProviders = identityProviders
            self.responseType = responseType
        }
    }

    /// The user pool's password policy: `auth.password_policy`.
    struct PasswordPolicy: Sendable, Equatable {
        /// The minimum password length.
        public let minLength: UInt
        /// Whether a password needs a lowercase letter.
        public let requiresLowercase: Bool
        /// Whether a password needs an uppercase letter.
        public let requiresUppercase: Bool
        /// Whether a password needs a digit.
        public let requiresNumbers: Bool
        /// Whether a password needs a symbol.
        public let requiresSymbols: Bool

        /// Builds a password policy from its parts, for a configuration not read from `amplify_outputs`.
        public init(
            minLength: UInt,
            requiresLowercase: Bool = false,
            requiresUppercase: Bool = false,
            requiresNumbers: Bool = false,
            requiresSymbols: Bool = false
        ) {
            self.minLength = minLength
            self.requiresLowercase = requiresLowercase
            self.requiresUppercase = requiresUppercase
            self.requiresNumbers = requiresNumbers
            self.requiresSymbols = requiresSymbols
        }
    }

    /// An attribute a user can sign in with instead of a username: `auth.username_attributes`.
    ///
    /// May gain cases in a minor release: include `@unknown default` when you switch over it.
    enum UsernameAttribute: String, Sendable, Equatable, CaseIterable {
        /// The user's email address: `email`.
        case email
        /// The user's phone number: `phone_number`.
        case phoneNumber = "phone_number"
    }

    /// How the user pool verifies a new user: `auth.user_verification_types`.
    enum VerificationMechanism: String, Sendable, Equatable, CaseIterable {
        /// A code sent to the user's email address: `email`.
        case email
        /// A code sent to the user's phone number: `phone_number`.
        case phoneNumber = "phone_number"
    }

    /// Whether the user pool requires MFA: `auth.mfa_configuration`. A value this client does not know is
    /// read as `nil`, as an unknown `auth.mfa_methods` entry is dropped.
    ///
    /// May gain cases in a minor release: include `@unknown default` when you switch over it.
    enum MFAEnforcement: String, Sendable, Equatable, CaseIterable {
        /// `NONE`
        case off = "NONE"
        /// `OPTIONAL`
        case optional = "OPTIONAL"
        /// `REQUIRED`
        case required = "REQUIRED"
    }
}

extension AuthClientConfiguration {

    /// The standard attributes `auth.standard_required_attributes` can name, keyed by their file spelling.
    /// These are Cognito's standard attributes; the verification flags, custom and unknown keys are not.
    static let standardAttributes: [String: AuthClientUserAttributeKey] = [
        "address": .address,
        "birthdate": .birthDate,
        "email": .email,
        "family_name": .familyName,
        "gender": .gender,
        "given_name": .givenName,
        "locale": .locale,
        "middle_name": .middleName,
        "name": .name,
        "nickname": .nickname,
        "phone_number": .phoneNumber,
        "picture": .picture,
        "preferred_username": .preferredUsername,
        "profile": .profile,
        "sub": .sub,
        "updated_at": .updatedAt,
        "website": .website,
        "zoneinfo": .zoneInfo
    ]

    /// The `auth.mfa_methods` spellings.
    static let mfaMethods: [String: AuthClientMFAType] = [
        "SMS": .sms,
        "TOTP": .totp,
        "EMAIL": .email
    ]
}
