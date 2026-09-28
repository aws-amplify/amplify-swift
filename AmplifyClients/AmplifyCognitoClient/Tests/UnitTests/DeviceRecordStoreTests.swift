//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(AmplifyExperimental) import AmplifyFoundation
import Foundation
import InternalAmplifyKeychain
import Security
import XCTest
@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient

/// Mirrors the engine's `DeviceMetadata` (`InternalAWSCognitoAuth`, `StateMachine/CodeGen/Data/DeviceMetadata.swift`):
/// the same cases, the same synthesized `Codable`. The store is exercised with this, and its encoding is pinned against the plugin's golden stored-format files.
private enum MirrorDeviceMetadata: Codable, Equatable, Sendable {
    case metadata(Data)
    case noData

    struct Data: Codable, Equatable, Sendable {
        let deviceKey: String
        let deviceGroupKey: String
        let deviceSecret: String
    }
}

final class DeviceRecordStoreTests: XCTestCase {

    private var keychain: TestKeychain!
    private var store: DeviceRecordStore!

    private let metadata = MirrorDeviceMetadata.metadata(
        .init(deviceKey: "us-east-1_device-key", deviceGroupKey: "device-group-key", deviceSecret: "device-secret")
    )

    override func setUp() {
        keychain = TestKeychain()
        store = keychain.deviceStore(for: StorageFixtures.namespace)
    }

    private func assertStorageUnavailable(
        _ reason: StorageUnavailableReason,
        file: StaticString = #filePath,
        line: UInt = #line,
        _ body: () throws -> some Any
    ) {
        XCTAssertThrowsError(try body(), file: file, line: line) { error in
            XCTAssertEqual((error as? AuthClientError)?.storageUnavailableReason, reason, "\(error)", file: file, line: line)
        }
    }

    // MARK: Key formats, byte-equal to the plugin's

    /// The pool namespaces the plugin's keychain-parity baseline records device keys under.
    private static let baselineFixturePools = PoolNamespace.userPoolAndIdentityPool(
        userPoolId: "us-east-1_FixturePool",
        identityPoolId: "us-east-1:00000000-0000-4000-8000-00000000ffff"
    )
    private static let baselineMockPools = PoolNamespace.userPoolAndIdentityPool(userPoolId: "XXX_XX", identityPoolId: "XXX")

    /// Every pinned account, as (pools, username, device metadata account, ASF device account).
    private static let pinnedAccounts: [(PoolNamespace, String, String, String)] = [
        (
            baselineMockPools, "alice",
            "amplify.XXX_XX.XXX.alice.deviceMetadata",
            "amplify.XXX_XX.XXX.alice.deviceASF"
        ),
        (
            baselineMockPools, "Alice.Example",
            "amplify.XXX_XX.XXX.alice.example.deviceMetadata",
            "amplify.XXX_XX.XXX.Alice.Example.deviceASF"
        ),
        (
            baselineFixturePools, "Alice.Example",
            "amplify.us-east-1_FixturePool.us-east-1:00000000-0000-4000-8000-00000000ffff.alice.example.deviceMetadata",
            "amplify.us-east-1_FixturePool.us-east-1:00000000-0000-4000-8000-00000000ffff.Alice.Example.deviceASF"
        ),
        (
            baselineFixturePools, "fixture-user",
            "amplify.us-east-1_FixturePool.us-east-1:00000000-0000-4000-8000-00000000ffff.fixture-user.deviceMetadata",
            "amplify.us-east-1_FixturePool.us-east-1:00000000-0000-4000-8000-00000000ffff.fixture-user.deviceASF"
        ),
        (
            .userPool("us-east-1_AbCdEf123"), "alice",
            "amplify.us-east-1_AbCdEf123.alice.deviceMetadata",
            "amplify.us-east-1_AbCdEf123.alice.deviceASF"
        ),
        (
            .userPool("us-east-1_AbCdEf123"), "Alice",
            "amplify.us-east-1_AbCdEf123.alice.deviceMetadata",
            "amplify.us-east-1_AbCdEf123.Alice.deviceASF"
        ),
        (
            .identityPool("us-east-1:0e3c1a52-7f0b-4a55-9d7a-2b6f3c1d9e88"), "Alice",
            "amplify.us-east-1:0e3c1a52-7f0b-4a55-9d7a-2b6f3c1d9e88.alice.deviceMetadata",
            "amplify.us-east-1:0e3c1a52-7f0b-4a55-9d7a-2b6f3c1d9e88.Alice.deviceASF"
        ),
        (
            .userPool("us-east-1_AbCdEf123"), "\u{00C9}LODIE@Corp.example",
            "amplify.us-east-1_AbCdEf123.\u{00E9}lodie@corp.example.deviceMetadata",
            "amplify.us-east-1_AbCdEf123.\u{00C9}LODIE@Corp.example.deviceASF"
        )
    ]

    /// The device accounts are the plugin's, byte for byte.
    ///
    /// - Given: pool namespaces of every shape, and usernames `alice`, `Alice`, one containing `.` and one
    ///   with a non-ASCII capital
    /// - When:
    ///    - the store derives the device metadata and ASF device accounts
    /// - Then:
    ///    - each equals the literal `AWSCognitoAuthCredentialStore.generateDeviceMetadataKey` /
    ///      `generateASFDeviceKey` produce, as the keychain-parity baseline records them
    ///
    func testAccountsAreThePluginsLiteralKeys() {
        for (pools, username, metadataAccount, asfAccount) in Self.pinnedAccounts {
            XCTAssertEqual(DeviceRecordStore.deviceMetadataAccount(for: username, in: pools), metadataAccount, username)
            XCTAssertEqual(DeviceRecordStore.asfDeviceAccount(for: username, in: pools), asfAccount, username)
            XCTAssertEqual(Array(DeviceRecordStore.deviceMetadataAccount(for: username, in: pools).utf8), Array(metadataAccount.utf8))
            XCTAssertEqual(Array(DeviceRecordStore.asfDeviceAccount(for: username, in: pools).utf8), Array(asfAccount.utf8))
        }
    }

    /// The pinned literals are the ones the plugin actually wrote when the keychain-parity baseline was recorded.
    ///
    /// - Given: the plugin's frozen keychain-query baseline (`GoldenKeychainQueries/queries.json`)
    /// - When:
    ///    - it is searched for each pinned account from the baseline's two namespaces
    /// - Then:
    ///    - every one appears as a query's key, so the literals above are not merely self-consistent
    ///
    func testPinnedAccountsAppearInThePluginsKeychainBaseline() throws {
        let baseline = try String(contentsOf: Self.pluginTestResource("GoldenKeychainQueries/queries.json"), encoding: .utf8)
        let baselinePools = [Self.baselineFixturePools, Self.baselineMockPools]
        let accounts = Self.pinnedAccounts.filter { baselinePools.contains($0.0) }.flatMap { [$0.2, $0.3] }
        XCTAssertEqual(accounts.count, 8)
        for account in accounts {
            XCTAssertTrue(baseline.contains("| \(account) -> "), account)
        }
    }

    /// The store uses its namespace's pools for both accounts.
    ///
    /// - Given: a store over the fixture namespace (user pool and identity pool)
    /// - When:
    ///    - it names the accounts for `Alice`
    /// - Then:
    ///    - they are `amplify.<userPoolId>.<identityPoolId>.alice.deviceMetadata` and `….Alice.deviceASF`
    ///
    func testStoreAccountsUseItsNamespace() {
        let prefix = "amplify.us-east-1_AbCdEf123.us-east-1:0e3c1a52-7f0b-4a55-9d7a-2b6f3c1d9e88."
        XCTAssertEqual(store.deviceMetadataAccount(for: "Alice"), prefix + "alice.deviceMetadata")
        XCTAssertEqual(store.asfDeviceAccount(for: "Alice"), prefix + "Alice.deviceASF")
    }

    // MARK: Casing asymmetry

    /// Device metadata is found case-insensitively; the ASF device ID is not.
    ///
    /// - Given: device metadata and an ASF device ID saved for `Alice`
    /// - When:
    ///    - both are read for `Alice`, `alice` and `ALICE`
    /// - Then:
    ///    - the metadata is found under every casing, at the one lowercased account
    ///    - the ASF device ID is found only for `Alice`, the exact casing it was saved under
    ///
    func testDeviceMetadataIgnoresUsernameCaseAndASFDoesNot() throws {
        try store.saveDeviceMetadata(metadata, for: "Alice")
        try store.saveASFDeviceId("asf-id", for: "Alice")

        for username in ["Alice", "alice", "ALICE"] {
            XCTAssertEqual(try store.deviceMetadata(MirrorDeviceMetadata.self, for: username), .value(metadata), username)
        }
        XCTAssertEqual(try store.asfDeviceId(for: "Alice"), .value("asf-id"))
        XCTAssertEqual(try store.asfDeviceId(for: "alice"), .absent)
        XCTAssertEqual(try store.asfDeviceId(for: "ALICE"), .absent)
        XCTAssertEqual(keychain.writtenAccounts, [store.deviceMetadataAccount(for: "alice"), store.asfDeviceAccount(for: "Alice")])
    }

    /// Two casings of one username share one device-metadata record but keep two ASF device IDs.
    ///
    /// - Given: ASF device IDs saved for `Alice` and `alice`, and metadata saved for `Alice`
    /// - When:
    ///    - the metadata is removed for `alice`, and the ASF device ID for `Alice`
    /// - Then:
    ///    - the metadata is gone for both casings
    ///    - `alice`'s ASF device ID is untouched
    ///
    func testRemovalFollowsTheSameAsymmetry() throws {
        try store.saveASFDeviceId("upper", for: "Alice")
        try store.saveASFDeviceId("lower", for: "alice")
        try store.saveDeviceMetadata(metadata, for: "Alice")

        try store.removeDeviceMetadata(for: "alice")
        try store.removeASFDeviceId(for: "Alice")

        XCTAssertEqual(try store.deviceMetadata(MirrorDeviceMetadata.self, for: "Alice"), .absent)
        XCTAssertEqual(try store.asfDeviceId(for: "Alice"), .absent)
        XCTAssertEqual(try store.asfDeviceId(for: "alice"), .value("lower"))
    }

    // MARK: Values, encoded as the plugin encodes them

    /// Values round-trip through the plugin's stored format.
    ///
    /// - Given: the plugin's golden stored-format files for `DeviceMetadata.metadata`, `.noData` and an ASF device ID
    /// - When:
    ///    - each is stored at the plugin's account, as the plugin would have written it, and read through the store
    ///    - the store then writes the same values itself
    /// - Then:
    ///    - the reads decode to the fixtures' values
    ///    - the ASF device ID is written byte-equal to the fixture (a top-level JSON string); the metadata is
    ///      written as the same JSON tree (a default `JSONEncoder`'s key order is not pinned)
    ///
    func testValuesUseThePluginsStoredFormat() throws {
        let metadataFixture = try Self.goldenStoredFormat("deviceMetadata-metadata.json")
        let noDataFixture = try Self.goldenStoredFormat("deviceMetadata-noData.json")
        let asfFixture = try Self.goldenStoredFormat("deviceASF.json")
        let expectedMetadata = MirrorDeviceMetadata.metadata(.init(
            deviceKey: "us-east-1_fixture-device-key",
            deviceGroupKey: "fixture-device-group-key",
            deviceSecret: "fixture-device-secret"
        ))

        keychain.put(metadataFixture, store.deviceMetadataAccount(for: "alice"))
        keychain.put(noDataFixture, store.deviceMetadataAccount(for: "bob"))
        keychain.put(asfFixture, store.asfDeviceAccount(for: "alice"))
        XCTAssertEqual(try store.deviceMetadata(MirrorDeviceMetadata.self, for: "alice"), .value(expectedMetadata))
        XCTAssertEqual(try store.deviceMetadata(MirrorDeviceMetadata.self, for: "bob"), .value(.noData))
        XCTAssertEqual(try store.asfDeviceId(for: "alice"), .value("fixture-asf-device-id"))

        try store.saveDeviceMetadata(expectedMetadata, for: "carol")
        try store.saveDeviceMetadata(MirrorDeviceMetadata.noData, for: "dave")
        try store.saveASFDeviceId("fixture-asf-device-id", for: "carol")
        XCTAssertEqual(try Self.tree(keychain.value(store.deviceMetadataAccount(for: "carol"))), try Self.tree(metadataFixture))
        XCTAssertEqual(try Self.tree(keychain.value(store.deviceMetadataAccount(for: "dave"))), try Self.tree(noDataFixture))
        XCTAssertEqual(keychain.value(store.asfDeviceAccount(for: "carol")), asfFixture)
        XCTAssertEqual(keychain.value(store.asfDeviceAccount(for: "carol")), Data(#""fixture-asf-device-id""#.utf8))
    }

    /// Bytes that are not a value are present, not absent, and are not an error of the keychain.
    ///
    /// - Given: the plugin's rejected fixtures (metadata missing its secret; an ASF device ID that is a number)
    /// - When:
    ///    - they are read through the store
    /// - Then:
    ///    - both reads are `.undecodable`, and nothing is written
    ///
    func testUndecodableValuesArePresentNotAbsent() throws {
        keychain.put(try Self.goldenStoredFormat("rejected-deviceMetadata-missing-secret.json"), store.deviceMetadataAccount(for: "alice"))
        keychain.put(try Self.goldenStoredFormat("rejected-deviceASF-number.json"), store.asfDeviceAccount(for: "alice"))

        XCTAssertEqual(try store.deviceMetadata(MirrorDeviceMetadata.self, for: "alice"), .undecodable)
        XCTAssertEqual(try store.asfDeviceId(for: "alice"), .undecodable)
        XCTAssertFalse(keychain.hasMutations)
    }

    // MARK: A keychain failure is not "absent"

    /// A failed read throws `storageUnavailable`; it is never reported as no record.
    ///
    /// - Given: reads of the device accounts fail with `errSecInteractionNotAllowed` (a locked device)
    /// - When:
    ///    - the metadata and the ASF device ID are read
    /// - Then:
    ///    - both throw `storageUnavailable(.locked)`, neither returns `.absent`, and nothing is written
    ///
    func testReadFailureIsStorageUnavailableNotAbsent() {
        keychain.failingReads(of: store.deviceMetadataAccount(for: "alice"), with: errSecInteractionNotAllowed)
        keychain.failingReads(of: store.asfDeviceAccount(for: "alice"), with: errSecInteractionNotAllowed)

        assertStorageUnavailable(.locked) { try store.deviceMetadata(MirrorDeviceMetadata.self, for: "alice") }
        assertStorageUnavailable(.locked) { try store.asfDeviceId(for: "alice") }
        XCTAssertFalse(keychain.hasMutations)
    }

    /// Failed writes and removals throw `storageUnavailable` with the classified reason.
    ///
    /// - Given: writes fail with `errSecMissingEntitlement`, and removals with `errSecIO`
    /// - When:
    ///    - each save and each removal runs
    /// - Then:
    ///    - saves throw `storageUnavailable(.denied)`, removals `storageUnavailable(.interrupted)`
    ///
    func testWriteAndRemovalFailuresAreStorageUnavailable() {
        keychain.failing(.write, with: errSecMissingEntitlement)
        keychain.failingRemovals(of: store.deviceMetadataAccount(for: "alice"), with: errSecIO)
        keychain.failingRemovals(of: store.asfDeviceAccount(for: "alice"), with: errSecIO)

        assertStorageUnavailable(.denied) { try store.saveDeviceMetadata(metadata, for: "alice") }
        assertStorageUnavailable(.denied) { try store.saveASFDeviceId("asf-id", for: "alice") }
        assertStorageUnavailable(.interrupted) { try store.removeDeviceMetadata(for: "alice") }
        assertStorageUnavailable(.interrupted) { try store.removeASFDeviceId(for: "alice") }
    }

    // MARK: Access-group scoping

    /// With an access group, records live in the shared service under that group, and nowhere else.
    ///
    /// - Given: one keychain, a store without an access group and a store for `group.shared`
    /// - When:
    ///    - each saves different records for `alice`
    /// - Then:
    ///    - the unshared records are in `com.amplify.awsCognitoAuthPlugin` with no group
    ///    - the shared ones are in `com.amplify.awsCognitoAuthPluginShared` under `group.shared`
    ///    - each store reads only its own, and a store for another group reads neither
    ///
    func testRecordsAreScopedToTheAccessGroup() throws {
        let shared = keychain.deviceStore(for: SessionStorageNamespace(pools: StorageFixtures.pools, accessGroup: "group.shared"))
        let other = keychain.deviceStore(for: SessionStorageNamespace(pools: StorageFixtures.pools, accessGroup: "group.other"))

        try store.saveASFDeviceId("unshared", for: "alice")
        try shared.saveASFDeviceId("shared", for: "alice")
        try shared.saveDeviceMetadata(metadata, for: "alice")

        let asfAccount = store.asfDeviceAccount(for: "alice")
        let metadataAccount = store.deviceMetadataAccount(for: "alice")
        XCTAssertEqual(keychain.value(service: "com.amplify.awsCognitoAuthPlugin", account: asfAccount), Data(#""unshared""#.utf8))
        XCTAssertEqual(
            keychain.value(service: "com.amplify.awsCognitoAuthPluginShared", accessGroup: "group.shared", account: asfAccount),
            Data(#""shared""#.utf8)
        )
        XCTAssertNil(keychain.value(service: "com.amplify.awsCognitoAuthPlugin", account: metadataAccount))
        XCTAssertNotNil(keychain.value(service: "com.amplify.awsCognitoAuthPluginShared", accessGroup: "group.shared", account: metadataAccount))

        XCTAssertEqual(try store.asfDeviceId(for: "alice"), .value("unshared"))
        XCTAssertEqual(try store.deviceMetadata(MirrorDeviceMetadata.self, for: "alice"), .absent)
        XCTAssertEqual(try shared.asfDeviceId(for: "alice"), .value("shared"))
        XCTAssertEqual(try other.asfDeviceId(for: "alice"), .absent)
        XCTAssertEqual(try other.deviceMetadata(MirrorDeviceMetadata.self, for: "alice"), .absent)

        try shared.removeASFDeviceId(for: "alice")
        XCTAssertEqual(try store.asfDeviceId(for: "alice"), .value("unshared"))
    }

    /// The real-keychain store is built for the session records' service and the namespace's access group.
    ///
    /// - Given: namespaces with and without an access group
    /// - When:
    ///    - a store is made over the real keychain
    /// - Then:
    ///    - its `KeychainItemStore` has the plugin's service for that case, and the group
    ///
    func testRealKeychainStoreUsesTheSessionRecordsServiceAndGroup() throws {
        for (accessGroup, service) in [(nil, "com.amplify.awsCognitoAuthPlugin"), ("group.shared", "com.amplify.awsCognitoAuthPluginShared")] {
            let store = DeviceRecordStore(namespace: SessionStorageNamespace(pools: StorageFixtures.pools, accessGroup: accessGroup))
            let keychain = try XCTUnwrap(Mirror(reflecting: store).descendant("keychain") as? KeychainItemStore)
            XCTAssertEqual(keychain.attributes.service, service)
            XCTAssertEqual(keychain.attributes.accessGroup, accessGroup)
        }
    }

    // MARK: Never a session key, never authConfiguration

    /// No device-record call names a session key or the plugin's configuration key.
    ///
    /// - Given: usernames chosen to look like other keys: `session`, `x.session`, `authConfiguration`,
    ///   `$default`, the empty string and a real one
    /// - When:
    ///    - every store operation runs for each, over a spy that records every account touched
    /// - Then:
    ///    - every account starts `amplify.<poolNamespace>.` and ends `.deviceMetadata` or `.deviceASF`
    ///    - none ends `.session`, none is `authConfiguration`, none is a client session record, and none is
    ///      the plugin's session key
    ///
    func testNoCallNamesASessionKeyOrAuthConfiguration() throws {
        let prefix = "amplify.\(StorageFixtures.pools.keyComponent)."
        for username in ["session", "x.session", "authConfiguration", "$default", "", "Alice.Example"] {
            try store.saveDeviceMetadata(metadata, for: username)
            _ = try store.deviceMetadata(MirrorDeviceMetadata.self, for: username)
            try store.removeDeviceMetadata(for: username)
            try store.saveASFDeviceId("asf-id", for: username)
            _ = try store.asfDeviceId(for: username)
            try store.removeASFDeviceId(for: username)
        }

        let touched = keychain.readAccounts + keychain.writtenAccounts + keychain.removedAccounts
        XCTAssertEqual(touched.count, 36)
        for account in touched {
            XCTAssertTrue(account.hasPrefix(prefix), account)
            XCTAssertTrue(account.hasSuffix(".deviceMetadata") || account.hasSuffix(".deviceASF"), account)
            XCTAssertFalse(account.hasSuffix(".session"), account)
            XCTAssertNotEqual(account, "authConfiguration")
            XCTAssertNil(SessionRecordKey.parse(account), account)
            XCTAssertNotEqual(account, SessionRecordKey.legacySessionAccount(in: StorageFixtures.pools))
        }
    }

    // MARK: Sessions leave device records alone

    /// Purging or signing out a session keeps the user's device records: they are per user, not per session.
    ///
    /// - Given: device metadata and an ASF device ID for `alice`, and `.default` and a named session each
    ///   signed in as `alice`, over one keychain
    /// - When:
    ///    - the named session is signed out, then purged, and `.default` is purged
    /// - Then:
    ///    - both device records are still stored, byte for byte
    ///    - no session operation read, wrote or removed a device account
    ///
    func testSignOutAndPurgeKeepDeviceRecords() throws {
        let records = keychain.recordStore(for: StorageFixtures.namespace)
        let work = try SessionID.named("work")
        try store.saveDeviceMetadata(metadata, for: "alice")
        try store.saveASFDeviceId("asf-id", for: "alice")
        XCTAssertTrue(try records.write(StorageFixtures.signedIn(), for: .default, expecting: nil).didCommit)
        XCTAssertTrue(try records.write(StorageFixtures.signedIn(), for: work, expecting: nil).didCommit)
        let metadataBytes = keychain.value(store.deviceMetadataAccount(for: "alice"))
        let asfBytes = keychain.value(store.asfDeviceAccount(for: "alice"))
        keychain.resetLogs()

        XCTAssertEqual(try records.signOut(work), .signedOut)
        try records.purge(work)
        try records.purge(.default)

        XCTAssertEqual(keychain.value(store.deviceMetadataAccount(for: "alice")), metadataBytes)
        XCTAssertEqual(keychain.value(store.asfDeviceAccount(for: "alice")), asfBytes)
        let deviceAccounts = [store.deviceMetadataAccount(for: "alice"), store.asfDeviceAccount(for: "alice")]
        let touched = keychain.readAccounts + keychain.writtenAccounts + keychain.removedAccounts
        XCTAssertTrue(Set(touched).isDisjoint(with: deviceAccounts), "\(touched)")
    }

    /// Listing sessions is not confused by device records sharing the service.
    ///
    /// - Given: device records for `alice` and a signed-in named session
    /// - When:
    ///    - the stored sessions are listed
    /// - Then:
    ///    - only the session is listed
    ///
    func testListingIgnoresDeviceRecords() throws {
        let records = keychain.recordStore(for: StorageFixtures.namespace)
        let work = try SessionID.named("work")
        try store.saveDeviceMetadata(metadata, for: "alice")
        try store.saveASFDeviceId("asf-id", for: "alice")
        XCTAssertTrue(try records.write(StorageFixtures.signedIn(), for: work, expecting: nil).didCommit)

        XCTAssertEqual(try records.storedSessions(includingSignedOut: true).map(\.sessionId), [work])
    }

    /// One user's device records are shared by every session of the namespace.
    ///
    /// - Given: two stores over one namespace, as two sessions' engines have
    /// - When:
    ///    - the first saves `alice`'s records
    /// - Then:
    ///    - the second reads the same records
    ///
    func testRecordsAreSharedAcrossSessionsOfOneNamespace() throws {
        let second = keychain.deviceStore(for: StorageFixtures.namespace)
        try store.saveDeviceMetadata(metadata, for: "alice")
        try store.saveASFDeviceId("asf-id", for: "alice")

        XCTAssertEqual(try second.deviceMetadata(MirrorDeviceMetadata.self, for: "alice"), .value(metadata))
        XCTAssertEqual(try second.asfDeviceId(for: "alice"), .value("asf-id"))
    }

    // MARK: Inert store, off-pool I/O

    /// The inert store keeps nothing and touches no keychain.
    ///
    /// - Given: the stateless revoker's inert device store
    /// - When:
    ///    - records are saved, read and removed through it
    /// - Then:
    ///    - every read is `.absent`, and nothing throws
    ///
    func testInertStoreKeepsNothing() throws {
        let inert = DeviceRecordStore.inert(namespace: StorageFixtures.namespace)
        try inert.saveDeviceMetadata(metadata, for: "alice")
        try inert.saveASFDeviceId("asf-id", for: "alice")

        XCTAssertEqual(try inert.deviceMetadata(MirrorDeviceMetadata.self, for: "alice"), .absent)
        XCTAssertEqual(try inert.asfDeviceId(for: "alice"), .absent)
        try inert.removeDeviceMetadata(for: "alice")
        try inert.removeASFDeviceId(for: "alice")
        XCTAssertTrue(Mirror(reflecting: inert).descendant("keychain") is InertLegacyKeychain)
    }

    /// The async store runs every call on its own queue, not on the caller's thread.
    ///
    /// - Given: a `DeviceRecordIO` over the store, and a keychain hook that records whether a read runs on
    ///   the I/O queue
    /// - When:
    ///    - every operation runs through it
    /// - Then:
    ///    - the results match the synchronous store's, and the reads ran on the I/O queue
    ///
    func testAsyncStoreRunsOnItsQueue() async throws {
        let queue = DispatchQueue(label: "test.device-record-io")
        let key = DispatchSpecificKey<Bool>()
        queue.setSpecific(key: key, value: true)
        let onQueue = Flag()
        let offQueue = Flag()
        keychain.afterEveryRead(of: store.asfDeviceAccount(for: "alice")) {
            DispatchQueue.getSpecific(key: key) == true ? onQueue.raise() : offQueue.raise()
        }
        let io = DeviceRecordIO(store: store, queue: queue)

        try await io.saveDeviceMetadata(metadata, for: "Alice")
        try await io.saveASFDeviceId("asf-id", for: "alice")
        let readMetadata = try await io.deviceMetadata(MirrorDeviceMetadata.self, for: "alice")
        let readASF = try await io.asfDeviceId(for: "alice")
        XCTAssertEqual(readMetadata, .value(metadata))
        XCTAssertEqual(readASF, .value("asf-id"))

        try await io.removeDeviceMetadata(for: "alice")
        try await io.removeASFDeviceId(for: "alice")
        let removedMetadata = try await io.deviceMetadata(MirrorDeviceMetadata.self, for: "alice")
        let removedASF = try await io.asfDeviceId(for: "alice")
        XCTAssertEqual(removedMetadata, .absent)
        XCTAssertEqual(removedASF, .absent)
        XCTAssertTrue(onQueue.isRaised)
        XCTAssertFalse(offQueue.isRaised)
    }

    // MARK: Fixtures

    private static func pluginTestResource(_ path: String) -> URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent() // UnitTests
            .deletingLastPathComponent() // Tests
            .deletingLastPathComponent() // AmplifyCognitoClient
            .deletingLastPathComponent() // AmplifyClients
            .deletingLastPathComponent() // repository root
            .appendingPathComponent("AmplifyPlugins/Auth/Tests/AWSCognitoAuthPluginUnitTests/TestResources")
            .appendingPathComponent(path)
    }

    /// A golden stored-format file, without the trailing newline the file ends with.
    private static func goldenStoredFormat(_ name: String) throws -> Data {
        var data = try Data(contentsOf: pluginTestResource("GoldenStoredFormat/\(name)"))
        if data.last == UInt8(ascii: "\n") {
            data.removeLast()
        }
        return data
    }

    private static func tree(_ data: Data?) throws -> NSObject {
        try XCTUnwrap(JSONSerialization.jsonObject(with: XCTUnwrap(data), options: [.fragmentsAllowed]) as? NSObject)
    }
}
