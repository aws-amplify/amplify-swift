//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import InternalAWSCognitoAuth

/// The Cognito resources an `AmplifyCognitoClient` talks to.
///
/// Loading from `amplify_outputs.json` happens here, in the configuration's initializer, and never
/// in the client's — so constructing a client does no file I/O.
///
/// The pools, with the keychain access group, also decide which saved sessions a client sees: see
/// "Changing the configuration" on `AmplifyCognitoClient`.
@_spi(AmplifyExperimental)
public struct AuthClientConfiguration: Sendable, Equatable {

    /// A Cognito user pool and the app client the client signs in through: `auth.user_pool_id`,
    /// `auth.user_pool_client_id` and the settings beside them in `amplify_outputs`.
    public struct UserPool: Sendable, Equatable {
        /// The user pool ID, such as `us-east-1_AbCdEf123`. Part of which saved sessions a client reads.
        public let poolId: String
        /// The app client ID the client signs in through.
        public let appClientId: String
        /// The AWS Region the user pool is in, such as `us-east-1`.
        public let region: String
        /// Sent with user-pool API calls. The hosted UI's token exchange does not receive it, as for the
        /// plugin configured from `amplify_outputs`.
        public let appClientSecret: String?
        /// The hosted UI settings, or `nil` if the pool has no OAuth domain configured. The hosted UI does
        /// not use `appClientSecret`.
        public let oauth: OAuth?
        /// The pool's password policy, or `nil` if not stated. Cognito enforces it.
        public let passwordPolicy: PasswordPolicy?
        /// The attributes a user can sign in with instead of a username.
        public let usernameAttributes: [UsernameAttribute]
        /// The standard attributes a sign-up must provide.
        public let standardRequiredAttributes: [AuthClientUserAttributeKey]
        /// How the pool verifies a new user's contact details.
        public let verificationMechanisms: [VerificationMechanism]
        /// Whether the pool requires MFA, or `nil` if not stated or not a value this client knows.
        public let mfaEnforcement: MFAEnforcement?
        /// The MFA methods the pool offers.
        public let mfaMethods: [AuthClientMFAType]

        /// Builds a user pool from its parts, for a configuration not read from `amplify_outputs`.
        ///
        /// - Parameter standardRequiredAttributes: Cognito standard attributes only: not `.emailVerified`,
        ///   `.phoneNumberVerified`, `.custom` or `.unknown`. `AuthClientConfiguration.init` rejects them.
        public init(
            poolId: String,
            appClientId: String,
            region: String,
            appClientSecret: String? = nil,
            oauth: OAuth? = nil,
            passwordPolicy: PasswordPolicy? = nil,
            usernameAttributes: [UsernameAttribute] = [],
            standardRequiredAttributes: [AuthClientUserAttributeKey] = [],
            verificationMechanisms: [VerificationMechanism] = [],
            mfaEnforcement: MFAEnforcement? = nil,
            mfaMethods: [AuthClientMFAType] = []
        ) {
            self.poolId = poolId
            self.appClientId = appClientId
            self.region = region
            self.appClientSecret = appClientSecret
            self.oauth = oauth
            self.passwordPolicy = passwordPolicy
            self.usernameAttributes = usernameAttributes
            self.standardRequiredAttributes = standardRequiredAttributes
            self.verificationMechanisms = verificationMechanisms
            self.mfaEnforcement = mfaEnforcement
            self.mfaMethods = mfaMethods
        }
    }

    /// A Cognito identity pool, which issues AWS credentials: `auth.identity_pool_id` in `amplify_outputs`.
    public struct IdentityPool: Sendable, Equatable {
        /// The identity pool ID, such as `us-east-1:…`. Part of which saved sessions a client reads.
        public let poolId: String
        /// The AWS Region the identity pool is in.
        public let region: String
        /// Whether the identity pool allows guest (unauthenticated) identities, or `nil` if not stated.
        public let unauthenticatedIdentitiesEnabled: Bool?

        /// Builds an identity pool from its parts, for a configuration not read from `amplify_outputs`.
        public init(poolId: String, region: String, unauthenticatedIdentitiesEnabled: Bool? = nil) {
            self.poolId = poolId
            self.region = region
            self.unauthenticatedIdentitiesEnabled = unauthenticatedIdentitiesEnabled
        }
    }

    /// The user pool, or `nil` for an identity-pool-only configuration (guest and federated sessions only).
    public let userPool: UserPool?
    /// The identity pool, or `nil` for a user-pool-only configuration, which has no AWS credentials.
    public let identityPool: IdentityPool?

    /// Builds a configuration from its pools, for one not read from `amplify_outputs`.
    ///
    /// - Throws: `AuthClientError.configuration` if neither pool is given, or if
    ///   `userPool.standardRequiredAttributes` names something that is not a Cognito standard attribute.
    public init(userPool: UserPool? = nil, identityPool: IdentityPool? = nil) throws {
        guard userPool != nil || identityPool != nil else {
            throw AuthClientError.configuration(
                "A configuration needs a user pool, an identity pool, or both.",
                "Pass at least one pool."
            )
        }
        let standard = Set(Self.standardAttributes.values)
        if let invalid = userPool?.standardRequiredAttributes.first(where: { !standard.contains($0) }) {
            throw AuthClientError.configuration(
                "\(invalid) is not a Cognito standard attribute, so it cannot be a standard required attribute.",
                "Pass standard attributes only, such as .email or .givenName."
            )
        }
        self.userPool = userPool
        self.identityPool = identityPool
    }

    /// Loads the `auth` section of a Gen2 `amplify_outputs` JSON resource.
    ///
    /// Gen2 `amplify_outputs` only: a Gen1 `amplifyconfiguration.json` is not supported, and is refused with
    /// an error that says so.
    ///
    /// - Parameters:
    ///   - resource: The file name **without** an extension; `.json` is implied.
    ///   - bundle: The bundle containing it.
    /// - Throws: `AuthClientError.configuration` naming the specific problem: a name with an extension, a
    ///   missing or unreadable file, a document that is not a JSON object, a Gen1 configuration, a missing
    ///   `auth` section or required key, or a value outside the schema.
    public init(from resource: String = "amplify_outputs", bundle: Bundle = .main) throws {
        // A name carrying an extension would silently look for "amplify_outputs.json.json".
        let resourceURL = URL(fileURLWithPath: resource)
        guard resourceURL.pathExtension.isEmpty else {
            throw AuthClientError.configuration(
                "Resource name \"\(resource)\" must not include a file extension.",
                "Pass the file name without an extension, e.g. \"\(resourceURL.deletingPathExtension().lastPathComponent)\"."
            )
        }
        guard let url = bundle.url(forResource: resource, withExtension: "json") else {
            throw AuthClientError.configuration(
                "\(resource).json was not found in the bundle.",
                "Add \(resource).json to your app target."
            )
        }
        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            throw AuthClientError.configuration(
                "\(resource).json could not be read.",
                "Ensure the file is present and readable.",
                error
            )
        }
        try self.init(outputsData: data, resourceName: resource)
    }

    /// The pool identifiers stored records are scoped to — exactly what `AWSCognitoAuthPlugin` puts
    /// in its keys, so records written by either are found by the other.
    var poolNamespace: PoolNamespace {
        switch (userPool, identityPool) {
        case let (userPool?, identityPool?):
            return .userPoolAndIdentityPool(userPoolId: userPool.poolId, identityPoolId: identityPool.poolId)
        case let (userPool?, nil):
            return .userPool(userPool.poolId)
        case let (nil, identityPool?):
            return .identityPool(identityPool.poolId)
        case (nil, nil):
            // Unreachable: every initializer requires at least one pool.
            preconditionFailure("AuthClientConfiguration must contain at least one pool")
        }
    }
}

extension AuthClientConfiguration.UserPool: CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable {

    /// Every setting, with the app client secret redacted and the pool ID, app client ID and region masked as the
    /// engine's `UserPoolConfigurationData` masks them, so none of them reaches a log through string
    /// interpolation, `print`, `debugPrint` or `dump`, nor through the configuration that holds the pool.
    public var description: String {
        let fields = printedFields.map { "\($0.key): \($0.value)" }
        return "UserPool(\(fields.joined(separator: ", ")))"
    }

    public var debugDescription: String {
        description
    }

    /// For `dump` and debuggers: the same fields as `description`.
    public var customMirror: Mirror {
        Mirror(self, children: printedFields, displayStyle: .struct)
    }

    /// Every stored property, in declaration order, as the printed forms show it. A test fails when a stored
    /// property is missing here.
    private var printedFields: KeyValuePairs<String, Any> {
        [
            "poolId": poolId.maskedForLog(interiorCount: 4, retainingCount: 4),
            "appClientId": appClientId.maskedForLog(interiorCount: 4, retainingCount: 4),
            "region": region.redactedForLog(),
            "appClientSecret": appClientSecret == nil ? "nil" : "<redacted>",
            "oauth": oauth as Any,
            "passwordPolicy": passwordPolicy as Any,
            "usernameAttributes": usernameAttributes,
            "standardRequiredAttributes": standardRequiredAttributes,
            "verificationMechanisms": verificationMechanisms,
            "mfaEnforcement": mfaEnforcement as Any,
            "mfaMethods": mfaMethods
        ]
    }
}

extension AuthClientConfiguration.IdentityPool: CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable {

    /// Every setting, with the pool ID masked and the region redacted as the engine's
    /// `IdentityPoolConfigurationData` masks them, so neither reaches a log through string interpolation,
    /// `print`, `debugPrint` or `dump`, nor through the configuration that holds the pool.
    public var description: String {
        let fields = printedFields.map { "\($0.key): \($0.value)" }
        return "IdentityPool(\(fields.joined(separator: ", ")))"
    }

    public var debugDescription: String {
        description
    }

    /// For `dump` and debuggers: the same fields as `description`.
    public var customMirror: Mirror {
        Mirror(self, children: printedFields, displayStyle: .struct)
    }

    /// Every stored property, in declaration order, as the printed forms show it.
    private var printedFields: KeyValuePairs<String, Any> {
        [
            "poolId": poolId.maskedForLog(interiorCount: 4, retainingCount: 4),
            "region": region.redactedForLog(),
            "unauthenticatedIdentitiesEnabled": unauthenticatedIdentitiesEnabled.map { "\($0)" } ?? "nil"
        ]
    }
}

extension AuthClientConfiguration.OAuth: CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable {

    /// Every setting, with the domain and each redirect URI masked as the engine's `OAuthConfigurationData`
    /// masks them, so none of them reaches a log through string interpolation, `print`, `debugPrint` or `dump`,
    /// nor through the user pool that holds them. The scopes, identity providers and response type are not
    /// identifiers, and print as they are.
    public var description: String {
        let fields = printedFields.map { "\($0.key): \($0.value)" }
        return "OAuth(\(fields.joined(separator: ", ")))"
    }

    public var debugDescription: String {
        description
    }

    /// For `dump` and debuggers: the same fields as `description`.
    public var customMirror: Mirror {
        Mirror(self, children: printedFields, displayStyle: .struct)
    }

    /// Every stored property, in declaration order, as the printed forms show it.
    private var printedFields: KeyValuePairs<String, Any> {
        [
            "domain": domain.maskedForLog(interiorCount: 4, retainingCount: 4),
            "scopes": scopes,
            "redirectSignInURIs": redirectSignInURIs.map { $0.maskedForLog(interiorCount: 4, retainingCount: 4) },
            "redirectSignOutURIs": redirectSignOutURIs.map { $0.maskedForLog(interiorCount: 4, retainingCount: 4) },
            "identityProviders": identityProviders,
            "responseType": responseType
        ]
    }
}

/// What decides which stored record a session reads: the pools, plus the keychain access group.
/// Two clients for one session ID must agree on this, or the registry refuses the second.
struct SessionStorageNamespace: Hashable, Sendable {
    let pools: PoolNamespace
    let accessGroup: String?
}
