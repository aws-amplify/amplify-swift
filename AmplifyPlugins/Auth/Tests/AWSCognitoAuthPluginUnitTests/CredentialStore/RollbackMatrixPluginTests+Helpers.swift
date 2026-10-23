//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AmplifyKeychainTestCommon
import AWSCognitoIdentity
import AWSCognitoIdentityProvider
import Foundation
import InternalAmplifyKeychain
import XCTest
@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient
@testable import AWSCognitoAuthPlugin
@testable import InternalAWSCognitoAuth

/// The rollback matrix's helpers, for the rows in `RollbackMatrixPluginTests.swift` and `+Rollback.swift`.
extension RollbackMatrixPluginTests {

    /// The plugin's credential store with `configuration` over the shared keychain: it runs its own rule.
    func pluginStore(_ configuration: AuthConfiguration) -> AWSCognitoAuthCredentialStore {
        AWSCognitoAuthCredentialStore(authConfiguration: configuration, keychain: pluginKeychain, logger: AmplifyEngineLogRouter())
    }

    /// The client's record store for `configuration`'s pools over the shared keychain.
    func clientStore(for configuration: AuthConfiguration) -> SessionRecordStore {
        RollbackMatrixBytes.clientStore(in: keychain, pools: PoolNamespace(configuration))
    }

    func decoded(_ payload: Data) throws -> AmplifyCredentials {
        try JSONDecoder().decode(AmplifyCredentials.self, from: payload)
    }

    /// The plugin build of `ClientOverKeychain`'s app: its configuration, as the plugin stores it.
    var clientPluginConfiguration: AuthConfiguration {
        AuthConfiguration(client: ClientOverKeychain.configuration)
    }

    /// The plugin's record, and `.default`'s, for `ClientOverKeychain`'s app.
    var clientPluginAccount: String {
        AWSCognitoAuthCredentialStore.sessionAccount(for: clientPluginConfiguration)
    }

    /// The refresh token of `ClientOverKeychain`'s app's shared record, as stored.
    func storedRefreshToken() throws -> String? {
        try decoded(XCTUnwrap(keychain.value(service: pluginKeychainService, account: clientPluginAccount))).refreshToken
    }

    /// A fresh keychain, for a row that runs each binary from the same start.
    func resetKeychain() {
        keychain = InMemoryKeychain()
        pluginKeychain = InMemoryPluginKeychainStore(keychain: keychain)
    }

    /// `binary`'s credential store with `configuration` over the shared keychain: it runs its own rule.
    func pluginStore(_ binary: RollbackPluginBinary, _ configuration: AuthConfiguration) -> AWSCognitoAuthCredentialStore {
        AWSCognitoAuthCredentialStore(
            authConfiguration: configuration,
            keychain: binary.keychainStore(over: pluginKeychain),
            logger: AmplifyEngineLogRouter()
        )
    }

    /// Signs alice in through `client` with `USER_PASSWORD_AUTH`, as `ClientOverKeychain.userPool(signingIn:)` scripts.
    func signInThroughTheClient(_ client: AmplifyCognitoClient) async throws {
        let result = try await client.signIn(username: "alice", password: "password", options: .init(authFlowType: .userPassword))
        XCTAssertEqual(result.nextStep, .done)
    }

    /// `binary`'s access-group transition without migration, from no access group to one, over the unshared service:
    /// for `.released`, the service-wide `_removeAll()` that 2.62.0 still calls, emulated on its view; for `.current`,
    /// the plugin's own transition, through its credential store's keychain seam.
    func accessGroupTransitionWithoutMigration(_ binary: RollbackPluginBinary) throws {
        switch binary {
        case .released:
            try binary.keychainStore(over: pluginKeychain).removeAll()
        case .current:
            let suite = "RollbackMatrixPluginTests.\(UUID().uuidString)"
            let userDefaults = try XCTUnwrap(UserDefaults(suiteName: suite))
            defer { userDefaults.removePersistentDomain(forName: suite) }
            let keychain = keychain!
            let pluginKeychain = pluginKeychain!
            _ = AWSCognitoAuthCredentialStore(
                authConfiguration: authConfiguration,
                accessGroup: "group.acme",
                migrateKeychainItemsOfUserSession: false,
                userDefaults: userDefaults,
                makeKeychainStore: { service, accessGroup -> any KeychainItemStoreBehavior in
                    accessGroup == nil ? pluginKeychain : keychain.store(service: service, accessGroup: accessGroup)
                },
                logger: AmplifyEngineLogRouter()
            )
        }
    }
}
