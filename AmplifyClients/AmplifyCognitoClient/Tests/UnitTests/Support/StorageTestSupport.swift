//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(AmplifyExperimental) import AmplifyFoundation
import AmplifyKeychainTestCommon
import Foundation
import InternalAmplifyKeychain
import Security
import XCTest
@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient

// This is the only file in the client's tests that names the keychain module's in-memory fake, so if
// the fake moves, only this file changes.

/// A keychain for storage tests: the module's in-memory fake, plus a spy that records every read by
/// account and can fail reads of one account, and a between-read-and-write hook for simulating a
/// concurrent writer.
final class TestKeychain: @unchecked Sendable {

    /// Operations a failure can be injected into.
    enum Operation {
        case read, write, remove, list
    }

    private let keychain = InMemoryKeychain()

    // `@unchecked Sendable`: the properties below are only touched while holding `lock`.
    private let lock = NSLock()
    private var reads: [String] = []
    private var accountFailures: [String: OSStatus] = [:]
    private var removalFailures: [String: OSStatus] = [:]
    private var setFailures: [String: OSStatus] = [:]
    private var writeFailures: [String: OSStatus] = [:]
    private var removalHooks: [String: @Sendable () -> Void] = [:]
    private var duplicateListing = false

    /// A record store over this keychain. Its clock advances one second per call, so no test depends
    /// on wall-clock time.
    ///
    /// `markerScope` names the app whose namespace markers the store uses; tests of two apps sharing one
    /// keychain pass two. `rereadsAbsentSharedRecord` is off unless a test turns it on, so read counts are the same on
    /// every platform.
    func recordStore(
        for namespace: SessionStorageNamespace,
        markerScope: String = TestKeychain.markerScope,
        rereadsAbsentSharedRecord: Bool = false
    ) -> SessionRecordStore {
        let clock = TestClock()
        return SessionRecordStore(
            namespace: namespace,
            keychain: SpyItemStore(base: itemStore(accessGroup: namespace.accessGroup), spy: self),
            now: { clock.next() },
            userPoolTokensOnly: Self.userPoolTokensOnly,
            identityIdOf: Self.identityId,
            refreshTokenOf: Self.refreshToken,
            markerScope: markerScope,
            summarizeSharedRecord: Self.summarizeSharedRecord,
            rereadsAbsentSharedRecord: rereadsAbsentSharedRecord,
            sameCredentials: Self.sameCredentials
        )
    }

    /// The fake engine's comparison: two `FakePayload`s hold the same credentials when they decode equal, as
    /// `FakeSessionEngine.sameCredentials` says. Any other payload is the engine's format, compared as the live store
    /// compares it.
    @Sendable
    static func sameCredentials(_ lhs: Data, _ rhs: Data) -> Bool {
        if let lhs = FakePayload.decode(lhs), let rhs = FakePayload.decode(rhs) {
            return lhs == rhs
        }
        return CredentialSlot.sameCredentials(lhs, rhs)
    }

    /// The fake engine's view of `.default`'s shared record: the Auth plugin's stored format as the live store peeks
    /// it, else a `FakePayload`'s kind, user and identity, so core tests can keep `.default` on the fake's payloads.
    /// Anything else is unrecognised, as in the live store.
    @Sendable
    static func summarizeSharedRecord(_ payload: Data) -> PluginRecordSummary {
        let summary = PluginRecordSummary.peek(payload)
        guard !summary.isRecognised, let fake = FakePayload.decode(payload), let kind = SessionKind(storedValue: fake.kind) else {
            return summary
        }
        let hasUser = kind == .userPoolOnly || kind == .userPoolAndIdentityPool
        return PluginRecordSummary(
            kind: kind,
            username: hasUser ? fake.username : nil,
            userId: hasUser ? fake.userId : nil,
            identityId: fake.identityId,
            isRecognised: true
        )
    }

    /// The marker scope of the app under test.
    static let markerScope = "0123456789abcdef"

    /// The fake engine's `userPoolTokensOnly`, for the payloads core tests store: a `FakePayload` keeps its
    /// user and version and loses its identity and AWS credentials. Any other payload is the engine's
    /// format, reduced as the live store reduces it.
    @Sendable
    static func userPoolTokensOnly(_ payload: Data) throws -> Data? {
        guard var fake = FakePayload.decode(payload) else {
            return try CredentialSlot.userPoolTokensOnly(payload)
        }
        guard fake.kind == SessionKind.userPoolOnly.storedValue || fake.kind == SessionKind.userPoolAndIdentityPool.storedValue else {
            return nil
        }
        fake.kind = SessionKind.userPoolOnly.storedValue
        fake.aws = false
        fake.identityId = nil
        return fake.data
    }

    /// The fake engine's identity ID of a payload: a `FakePayload`'s own, else the engine's format's.
    @Sendable
    static func identityId(_ payload: Data) -> String? {
        guard let fake = FakePayload.decode(payload) else {
            return CredentialSlot.identityId(payload)
        }
        return fake.identityId
    }

    /// The fake engine's refresh token of a payload: a signed-in `FakePayload`'s own, or `refresh-<username>`; none for
    /// a guest or federated identity. Else the engine's format's.
    @Sendable
    static func refreshToken(_ payload: Data) -> String? {
        guard let fake = FakePayload.decode(payload) else {
            return CredentialSlot.refreshToken(payload)
        }
        guard fake.kind == SessionKind.userPoolOnly.storedValue || fake.kind == SessionKind.userPoolAndIdentityPool.storedValue else {
            return nil
        }
        return fake.refreshToken ?? "refresh-\(fake.username ?? "none")"
    }

    /// A device record store over this keychain, through the same spy as `recordStore(for:)`, so a test
    /// can run both over one keychain.
    func deviceStore(for namespace: SessionStorageNamespace) -> DeviceRecordStore {
        DeviceRecordStore(
            namespace: namespace,
            keychain: SpyItemStore(base: itemStore(accessGroup: namespace.accessGroup), spy: self)
        )
    }

    /// A spied store for any service, for code that keeps records outside the session records' service
    /// (the Pinpoint context).
    func itemStore(service: String, accessGroup: String? = nil) -> any KeychainItemStoreBehavior {
        SpyItemStore(base: keychain.store(service: service, accessGroup: accessGroup), spy: self)
    }

    // MARK: Direct access, bypassing the spy and recording nothing

    func value(service: String, accessGroup: String? = nil, account: String) -> Data? {
        keychain.value(service: service, accessGroup: accessGroup, account: account)
    }

    /// `put(_:_:accessGroup:)` for any service.
    func put(_ value: Data, _ account: String, service: String, accessGroup: String? = nil) {
        do {
            try keychain.store(service: service, accessGroup: accessGroup).set(value, key: account)
        } catch {
            preconditionFailure("fixture write failed: \(error)")
        }
        keychain.resetMutations()
    }

    func value(_ account: String, accessGroup: String? = nil) -> Data? {
        keychain.value(
            service: SessionRecordStore.service(forAccessGroup: accessGroup),
            accessGroup: accessGroup,
            account: account
        )
    }

    /// Stores a fixture value, then clears the mutation log so only the operation under test is in it.
    /// Set fixtures up before acting; use a record store for a write that should be logged.
    func put(_ value: Data, _ account: String, accessGroup: String? = nil) {
        do {
            try itemStore(accessGroup: accessGroup).set(value, key: account)
        } catch {
            preconditionFailure("fixture write failed: \(error)")
        }
        keychain.resetMutations()
    }

    private func itemStore(accessGroup: String?) -> InMemoryKeychainItemStore {
        keychain.store(service: SessionRecordStore.service(forAccessGroup: accessGroup), accessGroup: accessGroup)
    }

    // MARK: Inspection

    /// Accounts read through a record store, in order.
    var readAccounts: [String] {
        withLock { reads }
    }

    var writtenAccounts: [String] {
        keychain.writtenAccounts
    }

    var removedAccounts: [String] {
        keychain.mutations.compactMap { mutation in
            guard case .remove(_, let account) = mutation else { return nil }
            return account
        }
    }

    var hasMutations: Bool {
        !keychain.mutations.isEmpty
    }

    /// A write or removal of one account, in the order they happened.
    enum LoggedMutation: Equatable {
        case write(String)
        case remove(String)
    }

    /// Every write and removal since the logs were last cleared, in order, so a test can assert that one
    /// happened before another.
    var mutationOrder: [LoggedMutation] {
        keychain.mutations.compactMap { mutation in
            switch mutation {
            case .write(_, let account, _): return .write(account)
            case .remove(_, let account): return .remove(account)
            case .removeAll, .move: return nil
            }
        }
    }

    func resetLogs() {
        keychain.resetMutations()
        withLock { reads.removeAll() }
    }

    // MARK: Fault injection

    /// Makes every `operation` fail with `status` until cleared.
    func failing(_ operation: Operation, with status: OSStatus) {
        switch operation {
        case .read: keychain.failing(.read, with: status)
        case .write: keychain.failing(.write, with: status)
        case .remove: keychain.failing(.remove, with: status)
        case .list: keychain.failing(.listAccounts, with: status)
        }
    }

    /// Makes reads of one account fail with `status`, leaving every other account readable.
    func failingReads(of account: String, with status: OSStatus) {
        withLock { accountFailures[account] = status }
    }

    /// Makes removals of one account fail with `status`, leaving every other account removable.
    func failingRemovals(of account: String, with status: OSStatus) {
        withLock { removalFailures[account] = status }
    }

    /// Makes plain `set`s of one account fail with `status` (the namespace marker is written with `set`; records
    /// are written through their commit guard, which this leaves alone).
    func failingSets(of account: String, with status: OSStatus) {
        withLock { setFailures[account] = status }
    }

    /// Makes every write of one account fail with `status`: plain `set`s and the commit guard's adds and replaces.
    func failingWrites(of account: String, with status: OSStatus) {
        withLock { writeFailures[account] = status }
    }

    func clearFailures() {
        keychain.clearFailures()
        withLock {
            accountFailures.removeAll()
            removalFailures.removeAll()
            setFailures.removeAll()
            writeFailures.removeAll()
        }
    }

    /// Makes the listing return every account twice, as an unscoped listing does for an account stored
    /// in two access groups.
    func listingEveryAccountTwice() {
        withLock { duplicateListing = true }
    }

    /// Runs `body` once, after the `occurrence`th read of `account` (counting every reader), before
    /// that reader's next operation — so a concurrent writer lands between a read and a write.
    func onceAfterReading(_ account: String, occurrence: Int = 1, _ body: @escaping @Sendable () -> Void) {
        let counter = ReadCounter(firingAt: occurrence)
        keychain.afterRead { _, readAccount in
            guard readAccount == account, counter.countAndCheck() else { return }
            body()
        }
    }

    /// Runs `body` after every read of `account`, or stops doing so when `body` is `nil`.
    func afterEveryRead(of account: String, _ body: (@Sendable () -> Void)?) {
        guard let body else {
            keychain.afterRead(nil)
            return
        }
        keychain.afterRead { _, readAccount in
            guard readAccount == account else { return }
            body()
        }
    }

    // MARK: Spy plumbing

    fileprivate func recordRead(_ account: String) throws {
        let failure: OSStatus? = withLock {
            reads.append(account)
            return accountFailures[account]
        }
        if let failure {
            throw KeychainAccessError.securityError(failure)
        }
    }

    /// Runs `body` once, just before the next removal of `account` through a record store — so a test
    /// can act while an operation that deletes that record is in progress.
    func onceBeforeRemoving(_ account: String, _ body: @escaping @Sendable () -> Void) {
        withLock { removalHooks[account] = body }
    }

    fileprivate func recordRemoval(_ account: String) throws {
        let (failure, hook) = withLock { (removalFailures[account], removalHooks.removeValue(forKey: account)) }
        hook?()
        if let failure {
            throw KeychainAccessError.securityError(failure)
        }
    }

    fileprivate func recordSet(_ account: String) throws {
        if let failure = withLock({ setFailures[account] ?? writeFailures[account] }) {
            throw KeychainAccessError.securityError(failure)
        }
    }

    fileprivate func recordWrite(_ account: String) throws {
        if let failure = withLock({ writeFailures[account] }) {
            throw KeychainAccessError.securityError(failure)
        }
    }

    fileprivate var listsEveryAccountTwice: Bool {
        withLock { duplicateListing }
    }

    private func withLock<Value>(_ body: () throws -> Value) rethrows -> Value {
        lock.lock()
        defer { lock.unlock() }
        return try body()
    }
}

/// Forwards to the fake, recording reads and applying per-account failures on the way.
private struct SpyItemStore: KeychainItemStoreBehavior {
    let base: InMemoryKeychainItemStore
    let spy: TestKeychain

    func getData(_ key: String) throws -> Data {
        try spy.recordRead(key)
        return try base.getData(key)
    }

    func set(_ value: Data, key: String) throws {
        try spy.recordSet(key)
        try base.set(value, key: key)
    }

    func addIfAbsent(_ value: Data, key: String) throws -> Bool {
        try spy.recordWrite(key)
        return try base.addIfAbsent(value, key: key)
    }

    func replaceIfPresent(_ value: Data, key: String) throws -> Bool {
        try spy.recordWrite(key)
        return try base.replaceIfPresent(value, key: key)
    }

    func move(_ key: String, to destination: KeychainItemAttributes) throws -> KeychainMoveOutcome {
        try base.move(key, to: destination)
    }

    func remove(_ key: String) throws {
        try spy.recordRemoval(key)
        try base.remove(key)
    }

    func removeAll() throws {
        try base.removeAll()
    }

    func hasItems() throws -> Bool {
        try base.hasItems()
    }

    func allAccounts() throws -> [String] {
        let accounts = try base.allAccounts()
        return spy.listsEveryAccountTwice ? accounts + accounts : accounts
    }

    func move(_ entry: KeychainEntry, to destination: KeychainItemAttributes) throws -> KeychainMoveOutcome {
        try base.move(entry, to: destination)
    }

    func remove(_ entry: KeychainEntry) throws {
        try spy.recordRemoval(entry.account)
        try base.remove(entry)
    }

    func allEntries() throws -> [KeychainEntry] {
        let entries = try base.allEntries()
        return spy.listsEveryAccountTwice ? entries + entries : entries
    }
}

/// A clock that starts at a fixed instant and advances one second per reading.
final class TestClock: @unchecked Sendable {
    static let start = Date(timeIntervalSince1970: 1_790_000_000)

    private let lock = NSLock()
    private var readings = 0

    func next() -> Date {
        lock.lock()
        defer { lock.unlock() }
        readings += 1
        return TestClock.start.addingTimeInterval(TimeInterval(readings))
    }
}

/// Counts reads and says yes exactly once, on the chosen one.
private final class ReadCounter: @unchecked Sendable {
    private let lock = NSLock()
    private let firingAt: Int
    private var count = 0

    init(firingAt: Int) {
        self.firingAt = firingAt
    }

    func countAndCheck() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        count += 1
        return count == firingAt
    }
}

/// A flag a hook can set and a test can check, without timing.
final class Flag: @unchecked Sendable {
    private let lock = NSLock()
    private var raised = false

    var isRaised: Bool {
        lock.lock()
        defer { lock.unlock() }
        return raised
    }

    func raise() {
        lock.lock()
        defer { lock.unlock() }
        raised = true
    }
}

// MARK: - Record versions

extension VersionedSessionRecord {

    /// A named session's generation, for tests that count commits. A record versioned by its stored bytes has
    /// none, and fails the test.
    var generation: UInt64 {
        guard case .generation(let generation) = version else {
            XCTFail("expected a record versioned by its generation, got \(version)")
            return 0
        }
        return generation
    }
}

// MARK: - Fixtures

enum StorageFixtures {
    static let userPoolId = "us-east-1_AbCdEf123"
    static let identityPoolId = "us-east-1:0e3c1a52-7f0b-4a55-9d7a-2b6f3c1d9e88"

    static let pools = PoolNamespace.userPoolAndIdentityPool(userPoolId: userPoolId, identityPoolId: identityPoolId)
    static let namespace = SessionStorageNamespace(pools: pools, accessGroup: nil)

    /// Stand-in for the plugin's serialized `AmplifyCredentials`: this layer treats it as opaque bytes.
    static let pluginCredentials = Data(#"{"userPoolAndIdentityPool":{"signedInData":{"username":"alice"}}}"#.utf8)

    static func signedIn(label: String? = nil, username: String = "alice", credentials: String = "tokens-v1") -> SessionRecord {
        SessionRecord(label: label, username: username, kind: .userPoolAndIdentityPool, credentials: Data(credentials.utf8))
    }

    static let guest = SessionRecord(label: nil, username: nil, kind: .guest, credentials: Data("guest-credentials".utf8))

    /// A well-formed record from a schema this build does not know, carrying fields it could not read.
    static let futureSchemaRecord = Data(#"{"schemaVersion":2,"generation":"opaque","kind":{"new":true}}"#.utf8)

    static let corruptRecord = Data("not a record".utf8)
}

/// The Auth plugin's stored record in each of its shapes. Captured by encoding the plugin's own
/// `AmplifyCredentials` with `JSONEncoder` (as `AWSCognitoAuthCredentialStore` stores it) on
/// 2026-09-24; nesting and key spellings are verbatim, token and credential values are shortened.
enum PluginRecordFixtures {
    private static let signedInData = #"""
    {"isRefreshTokenExpired":false,"signedInDate":811967964.567444,"userId":"1234567890",\#
    "signInMethod":{"apiBased":{"_0":{"type":"USER_SRP_AUTH"}}},"username":"alice@corp",\#
    "cognitoUserPoolTokens":{"idToken":"id","accessToken":"access","refreshToken":"refresh","expiration":811968085.5}}
    """#
    private static let awsCredentials =
        #"{"expiration":811968085.567633,"accessKeyId":"accessKey","secretAccessKey":"secretAccessKey","sessionToken":"sessionToken"}"#

    static let userPoolOnly = Data(#"{"userPoolOnly":{"signedInData":\#(signedInData)}}"#.utf8)
    static let userPoolAndIdentityPool = Data(
        #"{"userPoolAndIdentityPool":{"identityID":"identityId","signedInData":\#(signedInData),"credentials":\#(awsCredentials)}}"#.utf8
    )
    static let identityPoolOnly = Data(#"{"identityPoolOnly":{"identityID":"someId","credentials":\#(awsCredentials)}}"#.utf8)
    static let identityPoolWithFederation = Data(
        #"{"identityPoolWithFederation":{"federatedToken":{"provider":{"facebook":{}},"token":"token"},"identityID":"identityId","credentials":\#(awsCredentials)}}"#.utf8
    )
    static let noCredentials = Data(#"{"noCredentials":{}}"#.utf8)
}

extension AuthClientError {

    /// The reason, if this is `storageUnavailable`.
    var storageUnavailableReason: StorageUnavailableReason? {
        guard case .storageUnavailable(let reason, _, _, _) = self else { return nil }
        return reason
    }
}
