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

/// The plugin's credential store reads and writes only its own session record, as on `main`.
///
/// Development builds of the Cognito client left a record of its default session under
/// `amplify.1.<pool namespace>.$default.session`, in the plugin's own keychain service. The plugin never
/// reads that record, never writes over its own record because of it, and never deletes it: retrieving with
/// only the leftover present is "no item", and ending a session is a plain delete of the plugin's own key.
final class AWSCognitoAuthCredentialStoreLeftoverRecordTests: XCTestCase {

    private let authConfiguration = Defaults.makeDefaultAuthConfigData()
    private let pools = PoolNamespace.userPoolAndIdentityPool(userPoolId: Defaults.userPoolId, identityPoolId: Defaults.identityPoolId)
    private var pluginAccount: String { SessionRecordKey.pluginSessionAccount(in: pools) }
    private var leftoverAccount: String { SessionRecordKey.account(for: .default, in: pools, kind: .session) }

    private var keychain: InMemoryKeychain!
    private var pluginKeychain: InMemoryPluginKeychainStore!

    override func setUp() {
        super.setUp()
        keychain = InMemoryKeychain()
        pluginKeychain = InMemoryPluginKeychainStore(keychain: keychain)
    }

    override func tearDown() {
        keychain = nil
        pluginKeychain = nil
        super.tearDown()
    }

    /// Test that a leftover client record is never read, so it cannot sign its user in
    ///
    /// - Given: A leftover `$default.session` record holding a signed-in envelope, as a development build of the
    ///   client's record store wrote it, and no plugin record
    /// - When:
    ///    - The plugin's credential store retrieves its credentials
    /// - Then:
    ///    - It throws `itemNotFound`
    ///    - No account under `amplify.1.` is ever read, and the leftover is byte-identical
    ///
    func testRetrieve_withOnlyALeftoverClientRecord_throwsItemNotFoundAndNeverReadsIt() throws {
        let leftover = try RollbackMatrixBytes.writeLeftoverDefaultRecord(
            RollbackMatrixBytes.pluginPayload("userPoolAndIdentityPool"),
            in: keychain,
            pools: pools
        )
        XCTAssertEqual(leftoverAccount, "amplify.1.\(Defaults.userPoolId).\(Defaults.identityPoolId).$default.session")
        let store = makeStore(authConfiguration)

        XCTAssertThrowsError(try store.retrieveCredential()) { error in
            XCTAssertEqual(error as? EngineCredentialStoreError, .itemNotFound)
        }
        XCTAssertEqual(pluginKeychain.readAccounts.filter { $0.hasPrefix("amplify.1.") }, [])
        XCTAssertEqual(keychain.value(service: pluginKeychainService, account: leftoverAccount), leftover)
    }

    /// Test that ending a session beside a leftover client record deletes the plugin's record, as on `main`
    ///
    /// - Given: The plugin's signed-in record and a leftover client `$default.session` record
    /// - When:
    ///    - The plugin's credential store deletes its credentials
    /// - Then:
    ///    - The only change is one `remove` of `amplify.<ns>.session`: no `set`, so no signed-out marker
    ///    - The leftover is byte-identical and was never read
    ///
    func testDelete_besideALeftoverClientRecord_removesTheRecordAsOnMain() throws {
        let payload = try RollbackMatrixBytes.pluginPayload("userPoolAndIdentityPool")
        let leftover = try RollbackMatrixBytes.writeLeftoverDefaultRecord(payload, in: keychain, pools: pools)
        try RollbackMatrixBytes.put(payload, pluginAccount, in: keychain)
        let store = makeStore(authConfiguration)

        try store.deleteCredential()

        XCTAssertEqual(keychain.mutations, [.remove(service: pluginKeychainService, account: pluginAccount)])
        XCTAssertNil(keychain.value(service: pluginKeychainService, account: pluginAccount))
        XCTAssertEqual(keychain.value(service: pluginKeychainService, account: leftoverAccount), leftover)
        XCTAssertFalse(pluginKeychain.readAccounts.contains(leftoverAccount))
    }

    /// Test that a configuration change the plugin does not carry removes the old record beside a leftover
    ///
    /// - Given: Configuration A with a signed-in plugin record, and a leftover client `$default.session`
    ///   record in A's namespace
    /// - When:
    ///    - The plugin is configured with configuration B, which has another user pool
    /// - Then:
    ///    - The old record is removed, with no `noCredentials` written in its place
    ///    - The only client accounts touched are A's default-session sidecar and interrupted sign-in, removed with
    ///      the record
    ///    - The leftover is byte-identical, and was never read or written
    ///
    func testUnsupportedConfigurationChange_besideALeftover_removesTheOldRecord() throws {
        let payload = try RollbackMatrixBytes.pluginPayload("userPoolAndIdentityPool")
        _ = makeStore(authConfiguration)
        let leftover = try RollbackMatrixBytes.writeLeftoverDefaultRecord(payload, in: keychain, pools: pools)
        try RollbackMatrixBytes.put(payload, pluginAccount, in: keychain)
        let other = AuthConfiguration.userPools(
            UserPoolConfigurationData(poolId: "us-east-1_OtherPool", clientId: "other-client-id", region: "us-east-1")
        )

        _ = AWSCognitoAuthCredentialStore(authConfiguration: other, keychain: pluginKeychain, logger: AmplifyEngineLogRouter())

        let oldAccountMutations = keychain.mutations.filter { mutation in
            switch mutation {
            case .write(_, let account, _), .remove(_, let account), .move(_, let account, _):
                return account == pluginAccount
            case .removeAll:
                return true
            }
        }
        XCTAssertEqual(oldAccountMutations, [.remove(service: pluginKeychainService, account: pluginAccount)])
        XCTAssertNil(keychain.value(service: pluginKeychainService, account: pluginAccount))
        XCTAssertEqual(keychain.mutatedClientAccounts, [
            SessionRecordKey.metaAccount(in: pools),
            SessionRecordKey.account(for: .default, in: pools, kind: .challenge)
        ])
        XCTAssertEqual(keychain.value(service: pluginKeychainService, account: leftoverAccount), leftover)
        XCTAssertFalse(pluginKeychain.readAccounts.contains(leftoverAccount))
    }

    // MARK: - Helpers

    /// The plugin's credential store over the shared keychain. Construction records the configuration, so the
    /// mutation log is cleared afterwards: only what the test does next is of interest.
    private func makeStore(_ authConfiguration: AuthConfiguration) -> AWSCognitoAuthCredentialStore {
        let store = AWSCognitoAuthCredentialStore(
            authConfiguration: authConfiguration,
            keychain: pluginKeychain,
            logger: AmplifyEngineLogRouter()
        )
        keychain.resetMutations()
        return store
    }
}
