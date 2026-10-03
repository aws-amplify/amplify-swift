//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(AmplifyExperimental) import AmplifyFoundation
import Foundation
import XCTest
@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient

/// Builds clients over an isolated registry, gate table and in-memory keychain, with a fake engine per
/// session, so no test touches process-wide state or the real keychain.
final class ClientHarness: @unchecked Sendable {

    let keychain = TestKeychain()
    let registry: SessionCoreDependencies.Registry
    let gates = SessionRecordGates()
    let revoker = FakeRevoker()
    /// What revokes a login `.default`'s configuration-change rule deleted, so no test reaches Cognito.
    let previousConfigurationRevoker = FakeRevoker()
    #if os(iOS) || os(macOS) || os(visionOS)
    /// This harness's own system-sheet lock, so no test touches `SystemSheetLock.shared`. A test may replace
    /// it, with seams, before it makes its clients.
    var sheetLock = SystemSheetLock()
    #endif

    // `@unchecked Sendable`: the properties below are only touched while holding `lock`.
    private let lock = NSLock()
    private var madeEngines: [FakeSessionEngine] = []
    private var engineFailure: Error?
    private var clientsFactory: (@Sendable (
        AuthClientConfiguration,
        AmplifyCognitoClientUserPoolConfigurationProvider?
    ) throws -> CognitoServiceClients)?
    private var restoreBound: UInt64
    private var clockOffset: TimeInterval = 0
    private var restoresOnConstruction: Bool

    /// - Parameters:
    ///   - restoreBound: Generous by default, so a slow machine never trips it by accident.
    ///   - restoresOnConstruction: Whether construction schedules a warm restore, as `live` does. Off by
    ///     default, so a test controls exactly when storage is read.
    init(
        registry: SessionCoreDependencies.Registry = .init(),
        restoreBound: UInt64 = 60_000_000_000,
        restoresOnConstruction: Bool = false
    ) {
        self.registry = registry
        self.restoreBound = restoreBound
        self.restoresOnConstruction = restoresOnConstruction
    }

    var dependencies: SessionCoreDependencies {
        let (bound, warm) = withLock { (restoreBound, restoresOnConstruction) }
        var dependencies = SessionCoreDependencies(
            registry: registry,
            gates: gates,
            makeStore: { [keychain] namespace in keychain.recordStore(for: namespace) },
            makeClients: { [self] configuration, configure in
                if let factory = withLock({ clientsFactory }) {
                    return try factory(configuration, configure)
                }
                return try CognitoServiceClients(configuration: configuration, configureUserPoolClient: configure)
            },
            makeEngine: { [self] context in
                try withLock {
                    if let engineFailure {
                        throw engineFailure
                    }
                    let engine = FakeSessionEngine(context: context)
                    madeEngines.append(engine)
                    return engine
                }
            },
            makeRevoker: { [revoker] _ in revoker },
            scheduleRestore: { core in
                guard warm else { return }
                Task { await core.warmRestore() }
            },
            bounds: .init(restoreNanoseconds: bound),
            now: { [self] in TestClock.start.addingTimeInterval(withLock { clockOffset }) }
        )
        dependencies.makePreviousConfigurationRevoker = { [previousConfigurationRevoker] _ in previousConfigurationRevoker }
        #if os(iOS) || os(macOS) || os(visionOS)
        dependencies.sheetLock = sheetLock
        #endif
        return dependencies
    }

    // MARK: Configuration

    /// Moves the cores' clock (`TestClock.start` by default) forward.
    func advanceClock(by seconds: TimeInterval) {
        withLock { clockOffset += seconds }
    }

    func setRestoreBound(nanoseconds: UInt64) {
        withLock { restoreBound = nanoseconds }
    }

    func failEngineCreation(with error: Error?) {
        withLock { engineFailure = error }
    }

    func useClientsFactory(
        _ factory: (@Sendable (
            AuthClientConfiguration,
            AmplifyCognitoClientUserPoolConfigurationProvider?
        ) throws -> CognitoServiceClients)?
    ) {
        withLock { clientsFactory = factory }
    }

    // MARK: Construction

    func client(
        _ sessionId: SessionID = .default,
        configuration: AuthClientConfiguration = ClientFixtures.configuration,
        accessGroup: String? = nil,
        configureUserPoolClient: AmplifyCognitoClientUserPoolConfigurationProvider? = nil
    ) throws -> AmplifyCognitoClient {
        try AmplifyCognitoClient(
            configuration: configuration,
            options: .init(sessionId: sessionId, accessGroup: accessGroup, configureUserPoolClient: configureUserPoolClient),
            dependencies: dependencies
        )
    }

    // MARK: Inspection

    var engines: [FakeSessionEngine] {
        withLock { madeEngines }
    }

    /// The most recently made engine for `sessionId`.
    func engine(for sessionId: SessionID) -> FakeSessionEngine? {
        engines.last { $0.context.sessionId == sessionId }
    }

    /// A record store over this harness's keychain, for fixtures and inspection.
    func store(
        configuration: AuthClientConfiguration = ClientFixtures.configuration,
        accessGroup: String? = nil
    ) -> SessionRecordStore {
        keychain.recordStore(for: SessionStorageNamespace(pools: configuration.poolNamespace, accessGroup: accessGroup))
    }

    /// Stores `payload` as a signed-in record for `sessionId`, then clears the keychain logs.
    @discardableResult
    func signIn(
        _ sessionId: SessionID,
        _ payload: FakePayload = .signedIn(),
        label: String? = nil,
        accessGroup: String? = nil
    ) throws -> VersionedSessionRecord {
        let outcome = try store(accessGroup: accessGroup).write(payload.record(label: label), for: sessionId, expecting: nil)
        keychain.resetLogs()
        guard case .committed(let committed) = outcome else {
            throw FixtureError(description: "fixture sign-in was discarded")
        }
        return committed
    }

    /// The stored record for `sessionId`, if readable.
    func storedRecord(_ sessionId: SessionID, accessGroup: String? = nil) throws -> SessionRecord? {
        guard case .record(let envelope) = try store(accessGroup: accessGroup).read(sessionId) else {
            return nil
        }
        return envelope.record
    }

    /// The bytes stored under `sessionId`'s own record key, if any (for `.default`, the Auth plugin's record): what a
    /// test compares with an envelope's `encoded()` to check every field of it, the schema version and timestamp
    /// included.
    func storedBytes(_ sessionId: SessionID, accessGroup: String? = nil) -> Data? {
        keychain.value(store(accessGroup: accessGroup).sessionAccount(for: sessionId), accessGroup: accessGroup)
    }

    /// Reads of `sessionId`'s own record key since the logs were last cleared.
    func recordReads(_ sessionId: SessionID, accessGroup: String? = nil) -> Int {
        let account = store(accessGroup: accessGroup).sessionAccount(for: sessionId)
        return keychain.readAccounts.count(where: { $0 == account })
    }

    /// Waits until the registry and the gate table are back to empty: every core released and pruned.
    func waitForBaseline(file: StaticString = #filePath, line: UInt = #line) async {
        await waitUntil("registry and gate table return to baseline", file: file, line: line) {
            registry.entryCount == 0 && gates.liveGateCount == 0
        }
    }

    private func withLock<Value>(_ body: () throws -> Value) rethrows -> Value {
        lock.lock()
        defer { lock.unlock() }
        return try body()
    }
}

enum ClientFixtures {

    static let userPool = AuthClientConfiguration.UserPool(
        poolId: StorageFixtures.userPoolId,
        appClientId: "app-client-1",
        region: "us-east-1"
    )

    static let identityPool = AuthClientConfiguration.IdentityPool(poolId: StorageFixtures.identityPoolId, region: "us-east-1")

    /// Both pools: the namespace is `StorageFixtures.namespace`.
    static let configuration = make(userPool: userPool, identityPool: identityPool)

    static let userPoolOnlyConfiguration = make(userPool: userPool, identityPool: nil)

    static let identityPoolOnlyConfiguration = make(userPool: nil, identityPool: identityPool)

    static func make(
        userPool: AuthClientConfiguration.UserPool?,
        identityPool: AuthClientConfiguration.IdentityPool?
    ) -> AuthClientConfiguration {
        do {
            return try AuthClientConfiguration(userPool: userPool, identityPool: identityPool)
        } catch {
            preconditionFailure("fixture configuration is invalid: \(error)")
        }
    }

    static func id(_ name: String) -> SessionID {
        do {
            return try SessionID.named(name)
        } catch {
            preconditionFailure("fixture session ID is invalid: \(error)")
        }
    }
}

/// Counts calls from synchronous code, such as an escape-hatch closure.
final class CallCounter: @unchecked Sendable {
    private let lock = NSLock()
    private var calls = 0

    var count: Int {
        lock.lock()
        defer { lock.unlock() }
        return calls
    }

    func increment() {
        lock.lock()
        calls += 1
        lock.unlock()
    }
}

/// Holds a client so a test can drop it from anywhere, including a hook running under a lock.
final class HandleHolder: @unchecked Sendable {
    private let lock = NSLock()
    private var held: AmplifyCognitoClient?

    func hold(_ client: AmplifyCognitoClient) {
        lock.lock()
        held = client
        lock.unlock()
    }

    /// Releases the client. Taken out of the lock first, so the release does not run under it.
    func drop() {
        lock.lock()
        let dropped = held
        held = nil
        lock.unlock()
        _ = dropped
    }
}

/// Blocks a thread until released: a keychain call that is stuck. The only way to simulate one, since
/// the store is synchronous.
final class Stall: @unchecked Sendable {
    private let semaphore = DispatchSemaphore(value: 0)
    private let reached = Flag()

    var hasBeenReached: Bool {
        reached.isRaised
    }

    func block() {
        reached.raise()
        semaphore.wait()
    }

    func release() {
        semaphore.signal()
    }
}

/// Another writer — another handle's process — that commits to a session's record from inside a
/// keychain hook. Its own reads fire the hook too, so it guards against re-entering itself, and it
/// stops after `budget` commits.
final class ConcurrentWriter: @unchecked Sendable {

    private let store: SessionRecordStore
    private let sessionId: SessionID
    private let budget: Int
    private let change: @Sendable (VersionedSessionRecord) -> SessionRecord
    private let lock = NSLock()
    private var moving = false
    private var commitCount = 0

    init(
        store: SessionRecordStore,
        sessionId: SessionID,
        budget: Int = 1,
        change: @escaping @Sendable (VersionedSessionRecord) -> SessionRecord
    ) {
        self.store = store
        self.sessionId = sessionId
        self.budget = budget
        self.change = change
    }

    var commits: Int {
        lock.lock()
        defer { lock.unlock() }
        return commitCount
    }

    func move() {
        lock.lock()
        guard !moving, commitCount < budget else {
            lock.unlock()
            return
        }
        moving = true
        lock.unlock()
        defer {
            lock.lock()
            moving = false
            lock.unlock()
        }
        guard case .record(let envelope) = try? store.read(sessionId) else {
            return
        }
        if case .committed? = try? store.write(change(envelope), for: sessionId, expecting: envelope.version) {
            lock.lock()
            commitCount += 1
            lock.unlock()
        }
    }
}

/// Collects a stream's elements on a task, so a test can wait for a count without timing.
final class StreamRecorder<Element: Sendable>: @unchecked Sendable {

    private let lock = NSLock()
    private var elements: [Element] = []
    private var finished = false
    private var task: Task<Void, Never>?

    init(_ stream: AsyncStream<Element>) {
        let task = Task { [weak self] in
            for await element in stream {
                self?.append(element)
            }
            self?.finish()
        }
        lock.lock()
        self.task = task
        lock.unlock()
    }

    var received: [Element] {
        lock.lock()
        defer { lock.unlock() }
        return elements
    }

    var isFinished: Bool {
        lock.lock()
        defer { lock.unlock() }
        return finished
    }

    /// Waits until at least `count` elements have arrived.
    func waitFor(_ count: Int, file: StaticString = #filePath, line: UInt = #line) async {
        await waitUntil("\(count) stream elements", file: file, line: line) { received.count >= count }
    }

    /// Waits until the stream has ended.
    func waitForFinish(file: StaticString = #filePath, line: UInt = #line) async {
        await waitUntil("the stream finishes", file: file, line: line) { isFinished }
    }

    func cancel() {
        lock.lock()
        let task = task
        lock.unlock()
        task?.cancel()
    }

    private func append(_ element: Element) {
        lock.lock()
        elements.append(element)
        lock.unlock()
    }

    private func finish() {
        lock.lock()
        finished = true
        lock.unlock()
    }
}

extension AuthClientError {

    /// Whether this is `sessionConfigurationMismatch` for `sessionId`.
    func isMismatch(for sessionId: SessionID) -> Bool {
        guard case .sessionConfigurationMismatch(let id, _, _, _) = self else { return false }
        return id == sessionId
    }
}

/// Runs `body`, expecting it to throw an `AuthClientError`, and returns that error.
func authClientError(
    _ body: () async throws -> some Any,
    file: StaticString = #filePath,
    line: UInt = #line
) async -> AuthClientError? {
    do {
        _ = try await body()
        XCTFail("expected an error", file: file, line: line)
        return nil
    } catch let error as AuthClientError {
        return error
    } catch {
        XCTFail("expected an AuthClientError, got \(error)", file: file, line: line)
        return nil
    }
}

/// The error of a `.failed` sign-out, expecting one: what a sign-out that used to throw now returns.
func failedSignOutError(
    _ result: AuthClientSignOutResult,
    file: StaticString = #filePath,
    line: UInt = #line
) -> AuthClientError? {
    guard case .failed(let error) = result else {
        XCTFail("expected .failed, got \(result)", file: file, line: line)
        return nil
    }
    XCTAssertFalse(result.signedOutLocally, file: file, line: line)
    return error
}

extension AuthClientSignOutResult {

    /// `.partial`, with each part `nil` unless given.
    static func partialResult(
        revokeTokenError: AuthClientError? = nil,
        globalSignOutError: AuthClientError? = nil,
        hostedUIError: AuthClientError? = nil,
        storageError: AuthClientError? = nil
    ) -> AuthClientSignOutResult {
        .partial(
            revokeTokenError: revokeTokenError,
            globalSignOutError: globalSignOutError,
            hostedUIError: hostedUIError,
            storageError: storageError
        )
    }

    /// The parts of a `.partial` result, by name.
    struct PartialErrors {
        let revokeTokenError: AuthClientError?
        let globalSignOutError: AuthClientError?
        let hostedUIError: AuthClientError?
        let storageError: AuthClientError?
    }

    /// The parts, or `nil` for any other case.
    var partialErrors: PartialErrors? {
        guard case .partial(let revoke, let global, let hostedUI, let storage) = self else {
            return nil
        }
        return PartialErrors(revokeTokenError: revoke, globalSignOutError: global, hostedUIError: hostedUI, storageError: storage)
    }
}

extension AmplifyCognitoClient {

    /// Signs in through the public API as `username`, with the fake engine's default (done).
    @discardableResult
    func signInForTest(_ username: String = "alice") async throws -> AuthClientSignInResult {
        try await signIn(username: username, password: "password")
    }
}

extension CredentialsError {

    var isNotSignedIn: Bool {
        if case .notSignedIn = self { return true }
        return false
    }

    var isSessionExpired: Bool {
        if case .sessionExpired = self { return true }
        return false
    }

    var isNotConfigured: Bool {
        if case .notConfigured = self { return true }
        return false
    }

    var isUnknown: Bool {
        if case .unknown = self { return true }
        return false
    }

    var storageUnavailableReason: StorageUnavailableReason? {
        guard case .storageUnavailable(let reason, _, _, _) = self else { return nil }
        return reason
    }
}
