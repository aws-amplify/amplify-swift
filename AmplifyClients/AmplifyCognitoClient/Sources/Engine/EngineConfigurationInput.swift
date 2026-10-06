//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// The engine's `AuthConfiguration`, in the client's vocabulary: the same cases, and for the user pool the
/// same twelve fields as `UserPoolConfigurationData`, with the same names.
///
/// It is derived from an `AuthClientConfiguration` exactly as the plugin's `ConfigurationHelper` derives
/// `AuthConfiguration` from `amplify_outputs` (`parseUserPoolData`, `parseHostedConfiguration`,
/// `parseIdentityPoolData`). `AuthConfiguration(client:)` maps this value field by field, with no decision left to make. The parity
/// test compares it with the plugin's golden configurations.
enum EngineConfigurationInput: Sendable, Equatable {
    case userPools(EngineUserPoolSettings)
    case identityPools(EngineIdentityPoolSettings)
    case userPoolsAndIdentityPools(EngineUserPoolSettings, EngineIdentityPoolSettings)

    init(_ configuration: AuthClientConfiguration) {
        switch (configuration.userPool, configuration.identityPool) {
        case let (userPool?, identityPool?):
            self = .userPoolsAndIdentityPools(.init(userPool), .init(identityPool))
        case let (userPool?, nil):
            self = .userPools(.init(userPool))
        case let (nil, identityPool?):
            self = .identityPools(.init(identityPool))
        case (nil, nil):
            // Unreachable: every initializer requires at least one pool.
            preconditionFailure("AuthClientConfiguration must contain at least one pool")
        }
    }
}

extension AuthClientConfiguration {
    /// What the engine is configured with.
    var engineInput: EngineConfigurationInput { EngineConfigurationInput(self) }
}

/// `IdentityPoolConfigurationData`.
struct EngineIdentityPoolSettings: Sendable, Equatable {
    let poolId: String
    let region: String

    init(_ identityPool: AuthClientConfiguration.IdentityPool) {
        self.poolId = identityPool.poolId
        self.region = identityPool.region
    }
}

/// `UserPoolConfigurationData`, field for field.
struct EngineUserPoolSettings: Sendable, Equatable {

    /// The configured default of `EngineAuthFlowType`. `amplify_outputs` cannot choose a flow, so the
    /// plugin hard-codes `.userSRP` on that path, and so does the client. A sign-in overrides it per call.
    enum AuthFlowType: Sendable, Equatable {
        case userSRP
    }

    /// `HostedUIConfigurationData`.
    struct HostedUIConfig: Sendable, Equatable {
        let clientId: String
        var oauth: OAuth
        let clientSecret: String?
    }

    /// `OAuthConfigurationData`.
    struct OAuth: Sendable, Equatable {
        let domain: String
        var scopes: [String]
        let signInRedirectURI: String
        let signOutRedirectURI: String
    }

    /// `UserPoolConfigurationData.PasswordProtectionSettings`.
    struct PasswordProtectionSettings: Sendable, Equatable {
        let minLength: UInt
        let characterPolicy: [PasswordCharacterPolicy]
    }

    /// `UserPoolConfigurationData.PasswordCharacterPolicy`.
    enum PasswordCharacterPolicy: Sendable, Equatable {
        case lowercase
        case uppercase
        case numbers
        case symbols
    }

    /// The standard attributes `UserPoolConfigurationData.SignUpAttributeType` has a case for. The plugin
    /// drops the others (`locale`, `picture`, `sub`, `updated_at`, `zoneinfo`), and so does the client.
    static let signUpAttributeKeys: Set<AuthClientUserAttributeKey> = [
        .address, .birthDate, .email, .familyName, .gender, .givenName, .middleName, .name, .nickname,
        .phoneNumber, .preferredUsername, .profile, .website
    ]

    let poolId: String
    let clientId: String
    let region: String
    /// Always `nil`: `amplify_outputs` has no custom user-pool endpoint.
    let endpoint: String?
    let clientSecret: String?
    /// Always `nil`: `amplify_outputs` has no Pinpoint app for the user pool.
    let pinpointAppId: String?
    var hostedUIConfig: HostedUIConfig?
    let authFlowType: AuthFlowType
    let passwordProtectionSettings: PasswordProtectionSettings?
    let usernameAttributes: [AuthClientConfiguration.UsernameAttribute]
    let signUpAttributes: [AuthClientUserAttributeKey]
    let verificationMechanisms: [AuthClientConfiguration.VerificationMechanism]

    init(_ userPool: AuthClientConfiguration.UserPool) {
        self.poolId = userPool.poolId
        self.clientId = userPool.appClientId
        self.region = userPool.region
        self.endpoint = nil
        self.clientSecret = userPool.appClientSecret
        self.pinpointAppId = nil
        self.authFlowType = .userSRP

        // `parseHostedConfiguration(configuration: AmplifyOutputsData.Auth)`: no hosted UI unless both
        // redirect lists are non-empty, and then the first of each. No secret, even when the app client has
        // one: the plugin passes `nil` on this path, and the client matches it exactly.
        self.hostedUIConfig = userPool.oauth.flatMap { oauth in
            guard let signIn = oauth.redirectSignInURIs.first,
                  let signOut = oauth.redirectSignOutURIs.first else {
                return nil
            }
            return HostedUIConfig(
                clientId: userPool.appClientId,
                oauth: OAuth(
                    domain: oauth.domain,
                    scopes: oauth.scopes,
                    signInRedirectURI: signIn,
                    signOutRedirectURI: signOut
                ),
                clientSecret: nil
            )
        }

        // `PasswordProtectionSettings(from:)`: lowercase, uppercase, numbers, symbols, in that order.
        self.passwordProtectionSettings = userPool.passwordPolicy.map { policy in
            let requirements: [(Bool, PasswordCharacterPolicy)] = [
                (policy.requiresLowercase, .lowercase),
                (policy.requiresUppercase, .uppercase),
                (policy.requiresNumbers, .numbers),
                (policy.requiresSymbols, .symbols)
            ]
            return PasswordProtectionSettings(
                minLength: policy.minLength,
                characterPolicy: requirements.filter(\.0).map(\.1)
            )
        }

        self.usernameAttributes = userPool.usernameAttributes
        self.signUpAttributes = userPool.standardRequiredAttributes.filter(Self.signUpAttributeKeys.contains)
        self.verificationMechanisms = userPool.verificationMechanisms
    }
}
