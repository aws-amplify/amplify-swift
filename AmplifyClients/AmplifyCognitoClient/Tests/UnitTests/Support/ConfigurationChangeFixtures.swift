//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import InternalAWSCognitoAuth
@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient

/// The configurations of the configuration-change tests (`DefaultSessionConfigurationChangeTests`, the rollback
/// matrix): user pool A with app client 1 or 2, user pool B, identity pools 1 and 2.
enum ChangeConfigs {

    static let identityPool2 = AuthClientConfiguration.IdentityPool(
        poolId: "us-east-1:00000000-0000-0000-0000-000000000002",
        region: "us-east-1"
    )
    static let userPoolClient2 = AuthClientConfiguration.UserPool(
        poolId: StorageFixtures.userPoolId,
        appClientId: "app-client-2",
        region: "us-east-1"
    )
    static let userPoolB = AuthClientConfiguration.UserPool(poolId: "us-east-1_OtherPool9", appClientId: "app-client-b", region: "us-east-1")

    static let both = ClientFixtures.configuration
    static let userPoolOnly = ClientFixtures.userPoolOnlyConfiguration
    static let identityPoolOnly = ClientFixtures.identityPoolOnlyConfiguration
    static let otherIdentityPoolOnly = ClientFixtures.make(userPool: nil, identityPool: identityPool2)
    static let bothOtherIdentityPool = ClientFixtures.make(userPool: ClientFixtures.userPool, identityPool: identityPool2)
    static let otherUserPool = ClientFixtures.make(userPool: userPoolB, identityPool: ClientFixtures.identityPool)
    /// App client 2, with an identity pool: from `userPoolOnly`, the key changes and the app client too.
    static let otherClientBoth = ClientFixtures.make(userPool: userPoolClient2, identityPool: ClientFixtures.identityPool)
    /// App client 2 with the same pools as `both`: the key stays.
    static let otherClientBothSamePools = otherClientBoth
    static let otherClientUserPoolOnly = ClientFixtures.make(userPool: userPoolClient2, identityPool: nil)

    /// `configuration` as a Gen1 plugin configuration records it: a custom endpoint and a Pinpoint app ID, which
    /// `amplify_outputs` cannot hold.
    static func gen1(of configuration: AuthClientConfiguration) -> AuthConfiguration {
        guard case .userPoolsAndIdentityPools(let userPool, let identityPool) = AuthConfiguration(client: configuration) else {
            preconditionFailure("a configuration with both pools")
        }
        return .userPoolsAndIdentityPools(
            UserPoolConfigurationData(
                poolId: userPool.poolId,
                clientId: userPool.clientId,
                region: userPool.region,
                endpoint: .init(validatedHost: "auth.example.com"),
                pinpointAppId: "pinpoint-app"
            ),
            identityPool
        )
    }

    /// A run of changes through every branch: the user pool added, the identity pool changed, removed and added
    /// back, the app client alone, the app client with the key, another user pool, and back.
    static let run: [AuthClientConfiguration] = [
        identityPoolOnly, both, bothOtherIdentityPool, userPoolOnly, both, otherClientBothSamePools,
        otherClientUserPoolOnly, otherClientBoth, userPoolOnly, otherUserPool, both, identityPoolOnly, otherIdentityPoolOnly
    ]

    struct Pair {
        let name: String
        let previous: AuthConfiguration?
        let current: AuthConfiguration
    }

    static let pairs: [Pair] = {
        func engine(_ configuration: AuthClientConfiguration) -> AuthConfiguration {
            AuthConfiguration(client: configuration)
        }
        return [
            Pair(name: "first run", previous: nil, current: engine(both)),
            Pair(name: "same", previous: engine(both), current: engine(both)),
            Pair(name: "same, identity pool only", previous: engine(identityPoolOnly), current: engine(identityPoolOnly)),
            Pair(name: "user pool added", previous: engine(identityPoolOnly), current: engine(both)),
            Pair(name: "identity pool added", previous: engine(userPoolOnly), current: engine(both)),
            Pair(name: "identity pool changed", previous: engine(both), current: engine(bothOtherIdentityPool)),
            Pair(name: "identity pool removed", previous: engine(both), current: engine(userPoolOnly)),
            Pair(name: "Gen1 then Gen2", previous: gen1(of: both), current: engine(both)),
            Pair(name: "user pool changed", previous: engine(both), current: engine(otherUserPool)),
            Pair(name: "app client alone", previous: engine(both), current: engine(otherClientBothSamePools)),
            Pair(name: "app client and an identity pool added", previous: engine(userPoolOnly), current: engine(otherClientBoth)),
            Pair(name: "identity pool changed, no user pool", previous: engine(identityPoolOnly), current: engine(otherIdentityPoolOnly)),
            Pair(name: "user pool removed", previous: engine(both), current: engine(identityPoolOnly)),
            Pair(name: "user pool added, another identity pool", previous: engine(identityPoolOnly), current: engine(bothOtherIdentityPool))
        ]
    }()
}

/// Payloads the plugin stores, for the configuration-change tests.
enum ChangePayloads {
    static func guest() throws -> Data {
        try JSONEncoder().encode(AmplifyCredentials.identityPoolOnly(
            identityID: "us-east-1:guest-identity",
            credentials: EngineAWSCredentials(
                accessKeyId: "AKID-guest",
                secretAccessKey: "secret-guest",
                sessionToken: "session-guest",
                expiration: Date(timeIntervalSince1970: 4_000_000_000)
            )
        ))
    }
}
