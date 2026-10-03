//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AmplifyKeychainTestCommon
import Foundation
import XCTest
@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient
@testable import AWSCognitoAuthPlugin
@testable import InternalAWSCognitoAuth

/// The rollback matrix's released-types row: what the client writes for `.default` decodes with the types a released
/// plugin decodes, as G2 captures them (`M2Baselines/StoredFormatForkCrossDecoders.swift`).
extension KeychainAttributeParityTests {

    /// The bytes the client writes decode with the released plugin's types.
    ///
    /// - Given: G2's minimal configurations (both pools, the user pool alone, the identity pool alone), and the
    ///   records the client's `.default` writes under them, through `ClientOverKeychain`: a user signed in with each
    ///   configuration that has a user pool, a guest, federations through two providers, and a sign-out
    /// - When:
    ///    - each record is decoded with the released `AmplifyCredentials` shape, and `authConfiguration` with the
    ///      plugin's own decoder
    /// - Then:
    ///    - each record is each `AmplifyCredentials` shape, decodes with `BaseShapeAmplifyCredentials` to the same fields
    ///      as the plugin's type, both re-encodings decode either way, and its persisted flow types and providers
    ///      decode with the released public types (`StoredFormatForkCrossDecoders`, `ForkCrossCheck`)
    ///    - `authConfiguration` is G2's `authConfiguration-*.json` for its configuration, as a JSON tree, and its
    ///      persisted flow type decodes with the released `AuthFlowType`
    ///
    @available(*, deprecated, message: "Cross-checks against the deprecated public flow types, on purpose")
    func testMatrix_clientWrittenBytes_decodeWithTheReleasedPluginTypes() async throws {
        let userPool = AuthClientConfiguration.UserPool(poolId: "us-east-1_FixturePool", appClientId: "fixture-client-id", region: "us-east-1")
        let identityPool = AuthClientConfiguration.IdentityPool(poolId: "us-east-1:00000000-0000-4000-8000-00000000ffff", region: "us-east-1")
        let configurations: [(golden: String, configuration: AuthClientConfiguration)] = try [
            ("authConfiguration-userPoolsAndIdentityPools-minimal", AuthClientConfiguration(userPool: userPool, identityPool: identityPool)),
            ("authConfiguration-userPools-minimal", AuthClientConfiguration(userPool: userPool)),
            ("authConfiguration-identityPools", AuthClientConfiguration(identityPool: identityPool))
        ]

        var shapes: Set<String> = []
        for (golden, configuration) in configurations {
            let hasUserPool = configuration.userPool != nil
            var written = [try await clientRecord(configuration) { client in
                if hasUserPool {
                    _ = try await client.signIn(username: "alice", password: "password", options: .init(authFlowType: .userPassword))
                } else {
                    _ = try await client.fetchAuthSession()
                }
            }]
            if hasUserPool {
                written.append(try await clientRecord(configuration) { client in
                    _ = try await client.signIn(username: "alice", password: "password", options: .init(authFlowType: .userPassword))
                    _ = await client.signOut()
                })
            } else {
                for provider in [AuthClientProvider.google, .oidc("acme")] {
                    written.append(try await clientRecord(configuration) { client in
                        _ = try await client.federateToIdentityPool(withProviderToken: "provider-token", for: provider)
                    })
                }
            }

            for (record, authConfiguration) in written {
                let (decoded, _) = try StoredFormatForkCrossDecoders.crossDecode(
                    record,
                    fork: AmplifyCredentials.self,
                    publicType: BaseShapeAmplifyCredentials.self
                )
                shapes.insert(Self.shape(of: decoded))
                switch decoded {
                case .userPoolOnly, .userPoolAndIdentityPool:
                    try ForkCrossCheck.flows(in: record)
                case .identityPoolWithFederation:
                    try ForkCrossCheck.providers(in: record)
                case .identityPoolOnly, .noCredentials:
                    break
                }

                let goldenBytes = try RollbackMatrixBytes.goldenSession(golden)
                XCTAssertEqual(try CanonicalJSON.canonicalize(authConfiguration), try CanonicalJSON.canonicalize(goldenBytes), golden)
                XCTAssertEqual(
                    try AWSCognitoAuthCredentialStore.decodeAuthConfiguration(authConfiguration),
                    AuthConfiguration(client: configuration),
                    golden
                )
                if hasUserPool {
                    try ForkCrossCheck.flows(in: authConfiguration)
                }
            }
        }
        XCTAssertEqual(shapes, ["userPoolOnly", "userPoolAndIdentityPool", "identityPoolOnly", "identityPoolWithFederation", "noCredentials"])
    }

    /// What the client's `.default` leaves under `configuration` after `body`, run on a new client over a new keychain:
    /// its record and its `authConfiguration`.
    private func clientRecord(
        _ configuration: AuthClientConfiguration,
        _ body: (AmplifyCognitoClient) async throws -> Void
    ) async throws -> (record: Data, authConfiguration: Data) {
        let keychain = InMemoryKeychain()
        let clients = ClientOverKeychain(keychain: keychain)
        clients.script(userPool: ClientOverKeychain.userPool(signingIn: "alice"))
        var client: AmplifyCognitoClient? = try clients.client(configuration: configuration)
        try await body(XCTUnwrap(client))
        client = nil
        await clients.waitForBaseline()
        let authConfiguration = AuthConfiguration(client: configuration)
        let record = try XCTUnwrap(keychain.value(
            service: pluginKeychainService,
            account: AWSCognitoAuthCredentialStore.sessionAccount(for: authConfiguration)
        ))
        let stored = try XCTUnwrap(keychain.value(service: pluginKeychainService, account: AWSCognitoAuthCredentialStore.authConfigurationAccount))
        return (record, stored)
    }

    private static func shape(of credentials: AmplifyCredentials) -> String {
        switch credentials {
        case .userPoolOnly: return "userPoolOnly"
        case .userPoolAndIdentityPool: return "userPoolAndIdentityPool"
        case .identityPoolOnly: return "identityPoolOnly"
        case .identityPoolWithFederation: return "identityPoolWithFederation"
        case .noCredentials: return "noCredentials"
        }
    }
}
