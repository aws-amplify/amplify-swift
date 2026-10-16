//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

// Decoding of a Gen2 `amplify_outputs.json`. Gen1 `amplifyconfiguration.json` is not accepted.
//
// The optional sections are decoded as the plugin decodes them (`AmplifyOutputsData.Auth`, snake-case keys),
// so the file shapes one accepts the other accepts too: a present `password_policy` or `oauth` needs every
// key, and an attribute outside the schema's list is an error. The MFA keys are free strings for the plugin;
// the client keeps the values it knows and ignores the rest, so it rejects no file the plugin accepts.

extension AuthClientConfiguration {

    /// Parses an `amplify_outputs` document. Separate from `init(from:bundle:)` so it can be tested
    /// without a bundle. Each required level is unwrapped on its own so the error names the missing key.
    init(outputsData data: Data, resourceName: String) throws {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw AuthClientError.configuration(
                "\(resourceName).json is not a valid JSON object.",
                "Regenerate \(resourceName).json from your Amplify backend."
            )
        }
        guard let auth = json["auth"] as? [String: Any] else {
            throw AuthClientError.configuration(
                "\(resourceName).json has no \"auth\" section.",
                "Add auth to your backend and regenerate \(resourceName).json."
            )
        }
        // A Gen1 `amplifyconfiguration.json` nests its settings under `auth.plugins`, and has none of the Gen2
        // keys. Say so, rather than naming the first Gen2 key it lacks. A Gen2 file that merely carries an extra
        // `plugins` key is read as Gen2.
        if auth["plugins"] is [String: Any], auth["aws_region"] == nil, auth["user_pool_id"] == nil {
            throw Self.gen1ConfigurationUnsupported(resourceName)
        }
        func required(_ key: String) throws -> String {
            guard let value = auth[key] as? String, !value.isEmpty else {
                throw AuthClientError.configuration(
                    "\(resourceName).json is missing \"auth.\(key)\".",
                    "Regenerate \(resourceName).json from your Amplify backend."
                )
            }
            return value
        }

        let region = try required("aws_region")
        let poolId = try required("user_pool_id")
        let appClientId = try required("user_pool_client_id")
        let settings = try OutputsAuthSettings.decode(auth, resourceName: resourceName)

        func invalid(_ key: String, _ value: String) -> AuthClientError {
            .configuration(
                "\(resourceName).json has an unsupported value \"\(value)\" in \"auth.\(key)\".",
                "Regenerate \(resourceName).json from your Amplify backend."
            )
        }
        func map<Value>(_ key: String, _ values: [String]?, _ transform: (String) -> Value?) throws -> [Value] {
            try (values ?? []).map { value in
                guard let mapped = transform(value) else { throw invalid(key, value) }
                return mapped
            }
        }

        // Unknown MFA values are ignored, not rejected: the plugin reads these keys as free strings, and a newer
        // `amplify_outputs` schema may add values. Only their type is checked.
        let mfaEnforcement = settings.mfaConfiguration.flatMap(MFAEnforcement.init(rawValue:))
        let mfaMethods = (settings.mfaMethods ?? []).compactMap { Self.mfaMethods[$0] }
        let userPool = try UserPool(
            poolId: poolId,
            appClientId: appClientId,
            region: region,
            oauth: settings.oauth.map {
                OAuth(
                    domain: $0.domain,
                    scopes: $0.scopes,
                    redirectSignInURIs: $0.redirectSignInUri,
                    redirectSignOutURIs: $0.redirectSignOutUri,
                    identityProviders: $0.identityProviders,
                    responseType: $0.responseType
                )
            },
            passwordPolicy: settings.passwordPolicy.map {
                PasswordPolicy(
                    minLength: $0.minLength,
                    requiresLowercase: $0.requireLowercase,
                    requiresUppercase: $0.requireUppercase,
                    requiresNumbers: $0.requireNumbers,
                    requiresSymbols: $0.requireSymbols
                )
            },
            usernameAttributes: map("username_attributes", settings.usernameAttributes, UsernameAttribute.init(rawValue:)),
            standardRequiredAttributes: map("standard_required_attributes", settings.standardRequiredAttributes) {
                Self.standardAttributes[$0]
            },
            verificationMechanisms: map(
                "user_verification_types",
                settings.userVerificationTypes,
                VerificationMechanism.init(rawValue:)
            ),
            mfaEnforcement: mfaEnforcement,
            mfaMethods: mfaMethods
        )
        // Type-checked by the decode, as the plugin does; an empty ID still means no identity pool.
        let identityPool = settings.identityPoolId.flatMap { poolId in
            poolId.isEmpty ? nil : IdentityPool(
                poolId: poolId,
                region: region,
                unauthenticatedIdentitiesEnabled: settings.unauthenticatedIdentitiesEnabled
            )
        }
        try self.init(userPool: userPool, identityPool: identityPool)
    }

    /// The refusal of a Gen1 `amplifyconfiguration.json`, which the client does not read.
    static func gen1ConfigurationUnsupported(_ resourceName: String) -> AuthClientError {
        let file = resourceName == "amplifyconfiguration"
            ? "amplifyconfiguration.json"
            : "\(resourceName).json (an amplifyconfiguration.json)"
        return .configuration(
            "\(file) is a Gen1 configuration, which AmplifyCognitoClient does not support.",
            "Use the Gen2 amplify_outputs.json from your Amplify backend, or build an AuthClientConfiguration in code."
        )
    }
}

/// The optional `auth` keys, with the plugin's `AmplifyOutputsData.Auth` shapes. Enumerations are read as
/// strings and mapped afterwards, so an error names the offending value.
private struct OutputsAuthSettings: Decodable {

    struct PasswordPolicy: Decodable {
        let minLength: UInt
        let requireNumbers: Bool
        let requireLowercase: Bool
        let requireUppercase: Bool
        let requireSymbols: Bool
    }

    struct OAuth: Decodable {
        let identityProviders: [String]
        let domain: String
        let scopes: [String]
        let redirectSignInUri: [String]
        let redirectSignOutUri: [String]
        let responseType: String
    }

    let identityPoolId: String?
    let passwordPolicy: PasswordPolicy?
    let oauth: OAuth?
    let standardRequiredAttributes: [String]?
    let usernameAttributes: [String]?
    let userVerificationTypes: [String]?
    let unauthenticatedIdentitiesEnabled: Bool?
    let mfaConfiguration: String?
    let mfaMethods: [String]?

    static func decode(_ auth: [String: Any], resourceName: String) throws -> OutputsAuthSettings {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        do {
            let data = try JSONSerialization.data(withJSONObject: auth)
            return try decoder.decode(OutputsAuthSettings.self, from: data)
        } catch let error as DecodingError {
            throw AuthClientError.configuration(
                "\(resourceName).json has an invalid \"\(keyPath(of: error))\".",
                "Regenerate \(resourceName).json from your Amplify backend.",
                error
            )
        } catch {
            throw AuthClientError.configuration(
                "\(resourceName).json has an invalid \"auth\" section.",
                "Regenerate \(resourceName).json from your Amplify backend.",
                error
            )
        }
    }

    /// The failing key in the file's spelling, for example `auth.password_policy.min_length`.
    private static func keyPath(of error: DecodingError) -> String {
        var path: [CodingKey]
        switch error {
        case .keyNotFound(let key, let context):
            path = context.codingPath + [key]
        case .typeMismatch(_, let context), .valueNotFound(_, let context), .dataCorrupted(let context):
            path = context.codingPath
        @unknown default:
            path = []
        }
        let components = path.map { key in
            key.intValue.map(String.init) ?? snakeCase(key.stringValue)
        }
        return (["auth"] + components).joined(separator: ".")
    }

    private static func snakeCase(_ key: String) -> String {
        key.reduce(into: "") { result, character in
            if character.isUppercase {
                result += "_" + character.lowercased()
            } else {
                result.append(character)
            }
        }
    }
}
