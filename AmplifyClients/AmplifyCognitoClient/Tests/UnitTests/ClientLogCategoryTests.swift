//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(AmplifyExperimental) import AmplifyFoundation
@testable import AmplifyFoundation
import InternalAmplifyKeychain
import Security
import XCTest
@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient

/// Every line the client logs outside the engine is under an `AmplifyCognitoClient.<area>` category, so an
/// app's sink can tell it from the Auth plugin's lines and from any other library's.
final class ClientLogCategoryTests: XCTestCase {

    /// The categories the client's lines used before they had their own. None may appear again.
    private static let bareCategories = ["SessionRecordStore", "SessionSignOut", "KeychainItemStore"]

    private var keychain: TestKeychain!
    private var store: SessionRecordStore!
    private var sink: CategoryCapture!
    private let work = ClientFixtures.id("work")
    private let home = ClientFixtures.id("home")

    override func setUp() {
        super.setUp()
        keychain = TestKeychain()
        store = keychain.recordStore(for: StorageFixtures.namespace)
        sink = CategoryCapture()
        AmplifyLogging.addSink(sink)
    }

    override func tearDown() {
        AmplifyLogging.removeSink(sink)
        sink = nil
        super.tearDown()
    }

    private var markerAccount: String {
        SessionRecordKey.markerAccount(for: work, scope: TestKeychain.markerScope)
    }

    /// The categories are spelled out, not derived, so a rename shows here.
    ///
    /// - Given: the client's log areas
    /// - When: their categories are read
    /// - Then:
    ///    - each is `AmplifyCognitoClient.<area>`, and the challenge record's lines use the store's
    func testTheCategoryNames() {
        XCTAssertEqual(ClientLog.category(ClientLog.sessionRecordStore), "AmplifyCognitoClient.SessionRecordStore")
        XCTAssertEqual(ClientLog.category(ClientLog.sessionSignOut), "AmplifyCognitoClient.SessionSignOut")
        XCTAssertEqual(ClientLog.category(ClientLog.keychainItemStore), "AmplifyCognitoClient.KeychainItemStore")
        XCTAssertEqual(ClientLog.category(ClientLog.defaultSession), "AmplifyCognitoClient.DefaultSession")
        XCTAssertEqual(SessionRecordStore.ChallengeLog.category, "AmplifyCognitoClient.SessionRecordStore")
        XCTAssertEqual((ClientLog.logger("X") as? ClientEngineLogger)?.name, "AmplifyCognitoClient.X")
    }

    /// Test that the session record store's warnings are under the client's category
    ///
    /// - Given: a capturing sink
    /// - When:
    ///    - each storage warning site is driven: listing an unrecognised plugin record, a namespace marker
    ///      whose write fails, a sign-out whose previous copies cannot be read, and a challenge sweep whose
    ///      delete fails
    /// - Then:
    ///    - each warning is logged under `AmplifyCognitoClient.SessionRecordStore`
    ///    - no line is logged under a bare `SessionRecordStore`, `SessionSignOut` or `KeychainItemStore`
    func testEveryStorageWarningIsUnderTheClientCategory() throws {
        // An unrecognised plugin record, listed.
        keychain.put(Data("not json".utf8), SessionRecordKey.pluginSessionAccount(in: StorageFixtures.pools))
        _ = try store.storedSessions()

        // A namespace marker whose write fails, at the record's creation.
        keychain.failingSets(of: markerAccount, with: errSecInteractionNotAllowed)
        _ = try store.write(StorageFixtures.signedIn(), for: work, expecting: nil)
        keychain.clearFailures()

        // Previous copies that cannot be read, at sign-out.
        keychain.failingReads(of: markerAccount, with: errSecInteractionNotAllowed)
        _ = try? store.signOut(work)
        keychain.clearFailures()

        // An expired challenge record whose delete fails, at a listing's sweep.
        let createdAt = Date(timeIntervalSince1970: 1_790_000_000)
        try store.putChallenge(
            ChallengeRecord(createdAt: createdAt.addingTimeInterval(-16 * 60), state: .fake(.confirmSignInWithTOTPCode, session: "s")!),
            for: home
        )
        keychain.failingRemovals(of: store.challengeAccount(for: home), with: errSecInteractionNotAllowed)
        _ = try store.storedSessions(sweepingChallengesAt: createdAt)

        let category = ClientLog.category(ClientLog.sessionRecordStore)
        for fragment in [
            "The Auth plugin's session record has a shape this version does not recognise",
            "The session's namespace marker could not be written",
            "A session's copies under a previous configuration could not be read",
            SessionRecordStore.ChallengeLog.sweepFailed
        ] {
            XCTAssertEqual(sink.categories(containing: fragment), [category], fragment)
        }
        XCTAssertEqual(sink.lines(in: Self.bareCategories), [])
    }

    /// Test that the keychain item stores the client builds over the real keychain log under the client's category
    ///
    /// - Given: the session record store, the device record store and the Pinpoint analytics source, each over
    ///   the real keychain (inspected only, never read or written)
    /// - When: each one's `KeychainItemStore` logger is read
    /// - Then:
    ///    - it is the client's logger named `AmplifyCognitoClient.KeychainItemStore`
    func testTheRealKeychainStoresLogUnderTheClientCategory() throws {
        let namespace = SessionStorageNamespace(pools: StorageFixtures.pools, accessGroup: nil)
        let stores: [(String, Any)] = [
            ("SessionRecordStore", SessionRecordStore(namespace: namespace).keychain),
            ("DeviceRecordStore", try XCTUnwrap(Mirror(reflecting: DeviceRecordStore(namespace: namespace)).descendant("keychain"))),
            ("LazyUserPoolAnalytics", try XCTUnwrap(Mirror(reflecting: LazyUserPoolAnalytics(pinpointAppId: nil)).descendant("keychain")))
        ]
        for (owner, keychain) in stores {
            let itemStore = try XCTUnwrap(keychain as? KeychainItemStore, owner)
            let logger = try XCTUnwrap(Mirror(reflecting: itemStore).descendant("logger") as? ClientEngineLogger, owner)
            XCTAssertEqual(logger.name, "AmplifyCognitoClient.KeychainItemStore", owner)
        }
    }
}

/// Records the category (the logger name) of every line logged through `AmplifyLogging` while it is registered.
final class CategoryCapture: LogSinkBehavior, @unchecked Sendable {

    let id = UUID().uuidString

    // `@unchecked Sendable`: `messages` is only touched while holding `lock`.
    private let lock = NSLock()
    private var messages: [(name: String, content: String)] = []

    func isEnabled(for logLevel: LogLevel) -> Bool {
        true
    }

    func emit(message: LogMessage) {
        lock.withLock { messages.append((message.name, message.content)) }
    }

    /// The categories of the lines whose text contains `fragment`, in order, without repeats.
    func categories(containing fragment: String) -> [String] {
        lock.withLock {
            messages.filter { $0.content.contains(fragment) }.map(\.name).reduce(into: [String]()) { names, name in
                if !names.contains(name) { names.append(name) }
            }
        }
    }

    /// The lines logged under any of `categories`.
    func lines(in categories: [String]) -> [String] {
        lock.withLock { messages.filter { categories.contains($0.name) }.map(\.content) }
    }

}
