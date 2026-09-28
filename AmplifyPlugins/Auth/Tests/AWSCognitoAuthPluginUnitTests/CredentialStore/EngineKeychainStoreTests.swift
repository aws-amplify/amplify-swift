//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import Amplify
import AmplifyKeychainTestCommon
import InternalAmplifyKeychain
import Security
import XCTest
@_spi(KeychainStore) @testable import AWSPluginsCore
@testable import AWSCognitoAuthPlugin
@testable import InternalAWSCognitoAuth

/// `EngineKeychainStore` against `AWSPluginsCore.KeychainStore`, the members it copies: the
/// same results, the same errors (as the engine's copy of `KeychainStoreError`), and the same lines under
/// the `KeychainStore` namespace.
final class EngineKeychainStoreTests: XCTestCase {

    private var capture: CapturingLoggingPlugin!
    private var savedPlugins: [PluginKey: LoggingCategoryPlugin] = [:]
    private var savedRouter: (any EngineLogRouter)?

    override func setUp() async throws {
        capture = CapturingLoggingPlugin()
        savedPlugins = Amplify.Logging.plugins
        savedRouter = EngineLog.router
        Amplify.Logging.plugins = [capture.key: capture]
        Amplify.Logging.logLevel = .verbose
        // The router `AWSCognitoAuthPlugin.init` installs, so the engine's lines reach `Amplify.Logging`.
        EngineLog.install(AmplifyEngineLogRouter())
    }

    override func tearDown() async throws {
        Amplify.Logging.plugins = savedPlugins
        if let savedRouter {
            EngineLog.install(savedRouter)
        }
    }

    // MARK: Results and errors

    /// Test that every member gives what `KeychainStore` gives over the same item store
    ///
    /// - Given: The same in-memory keychain behind a `KeychainStore` and an `EngineKeychainStore`, with
    ///   reads, writes and removals of some accounts failing
    /// - When:
    ///    - Each member runs on each store for present, missing, failing and undecodable accounts
    /// - Then:
    ///    - The results are equal, and every failure is the engine's copy of the same `KeychainStoreError`
    ///
    func testMembersMatchKeychainStore() throws {
        let keychain = InMemoryKeychain()
        let itemStore = keychain.store(service: "svc", accessGroup: "grp")
        let plugin = KeychainStore(service: "svc", accessGroup: "grp", itemStore: itemStore)
        let engine = EngineKeychainStore(itemStore)
        try itemStore.set(Data("value".utf8), key: "present")
        try itemStore.set(Data([0xff, 0xfe]), key: "notUTF8")
        try itemStore.set(Data("x".utf8), key: "lockedRemove")
        keychain.failing(.read, with: errSecInteractionNotAllowed, forAccount: "locked")
        keychain.failing(.write, with: errSecInteractionNotAllowed, forAccount: "lockedWrite")
        keychain.failing(.remove, with: errSecInteractionNotAllowed, forAccount: "lockedRemove")

        for key in ["present", "missing", "locked", "notUTF8"] {
            assertSame(try engine._getString(key), try plugin._getString(key), "_getString \(key)")
            assertSame(try engine._getData(key), try plugin._getData(key), "_getData \(key)")
        }
        assertSame(try engine._set("new", key: "a"), try plugin._set("new", key: "b"), "_set(String)")
        assertSame(try engine._set(Data("d".utf8), key: "c"), try plugin._set(Data("d".utf8), key: "d"), "_set(Data)")
        assertSame(try engine._set("w", key: "lockedWrite"), try plugin._set("w", key: "lockedWrite"), "_set failing")
        assertSame(try engine._remove("a"), try plugin._remove("b"), "_remove")
        assertSame(try engine._remove("lockedRemove"), try plugin._remove("lockedRemove"), "_remove failing")
        assertSame(try engine._hasItems(), try plugin._hasItems(), "_hasItems")
        assertSame(
            try engine.hasItemsExceptSessionRecords(),
            try plugin.hasItemsExceptSessionRecords(),
            "hasItemsExceptSessionRecords"
        )
        assertSame(try engine._removeAll(), try plugin._removeAll(), "_removeAll")
        assertSame(try engine._hasItems(), try plugin._hasItems(), "_hasItems after _removeAll")
    }

    /// Test that the scoped wipe spares session records and fails as `KeychainStore`'s does
    ///
    /// - Given: Two identical keychains holding plugin items and a client session record, one behind each
    ///   store, and a third whose listing fails
    /// - When:
    ///    - `removeAllExceptSessionRecords()` runs on each
    /// - Then:
    ///    - Both keep only the session record, and the failing listing throws the same error from both
    ///
    func testRemoveAllExceptSessionRecordsMatchesKeychainStore() throws {
        func populated() throws -> (InMemoryKeychain, InMemoryKeychainItemStore) {
            let keychain = InMemoryKeychain()
            let store = keychain.store(service: "svc")
            try store.set(Data("s".utf8), key: "amplify.pool.session")
            try store.set(Data("c".utf8), key: "amplify.1.pool.$default.session")
            return (keychain, store)
        }
        let (_, engineItems) = try populated()
        let (_, pluginItems) = try populated()
        try EngineKeychainStore(engineItems).removeAllExceptSessionRecords()
        try KeychainStore(service: "svc", itemStore: pluginItems).removeAllExceptSessionRecords()
        XCTAssertEqual(try engineItems.allAccounts(), ["amplify.1.pool.$default.session"])
        XCTAssertEqual(try engineItems.allAccounts(), try pluginItems.allAccounts())

        let (failing, failingItems) = try populated()
        failing.failing(.listAccounts, with: errSecInteractionNotAllowed)
        assertSame(
            try EngineKeychainStore(failingItems).removeAllExceptSessionRecords(),
            try KeychainStore(service: "svc", itemStore: failingItems).removeAllExceptSessionRecords(),
            "failed listing"
        )
    }

    // MARK: Log lines

    /// Test that the engine store logs what `KeychainStore` logs, under the same namespace and level
    ///
    /// - Given: A `KeychainStore` and an `EngineKeychainStore` over the same in-memory keychain
    /// - When:
    ///    - Each reads a string, fails to decode one, writes a string, and wipes the service
    /// - Then:
    ///    - The captured lines are identical: namespace `KeychainStore`, same levels, same messages
    ///
    func testLogLinesMatchKeychainStore() throws {
        let keychain = InMemoryKeychain()
        let itemStore = keychain.store(service: "svc")
        try itemStore.set(Data("value".utf8), key: "present")
        try itemStore.set(Data([0xff, 0xfe]), key: "notUTF8")

        func run(_ getString: (String) throws -> String, _ setString: (String, String) throws -> Void, _ wipe: () throws -> Void) {
            _ = try? getString("present")
            _ = try? getString("notUTF8")
            try? setString("new", "written")
            try? wipe()
        }

        let plugin = KeychainStore(service: "svc", itemStore: itemStore)
        run(plugin._getString, plugin._set, plugin.removeAllExceptSessionRecords)
        let pluginLines = capture.lines
        capture.clear()

        try itemStore.set(Data("value".utf8), key: "present")
        try itemStore.set(Data([0xff, 0xfe]), key: "notUTF8")
        let engine = EngineKeychainStore(itemStore)
        run(engine._getString, engine._set, engine.removeAllExceptSessionRecords)
        let engineLines = capture.lines

        XCTAssertFalse(pluginLines.isEmpty)
        XCTAssertEqual(engineLines, pluginLines)
        XCTAssertEqual(Set(engineLines.map(\.namespace)), ["KeychainStore"])
        XCTAssertTrue(engineLines.contains { $0.level == "error" && $0.message.contains("Unable to create String") })
    }

    /// Test that the production item store is the one `KeychainStore(service:accessGroup:)` builds
    ///
    /// - Given: A service with and without an access group
    /// - When:
    ///    - `EngineKeychainStore.makeItemStore(service:accessGroup:)` and `KeychainStore(service:accessGroup:)`
    ///      each build their store
    /// - Then:
    ///    - The item attributes are equal, and both log the same "Initialized keychain" line under the
    ///      `KeychainStore` namespace
    ///
    func testMakeItemStoreMatchesKeychainStoreInit() {
        for accessGroup in [nil, "group.example"] as [String?] {
            capture.clear()
            let plugin = KeychainStore(service: "svc", accessGroup: accessGroup)
            let pluginLines = capture.lines
            capture.clear()
            let engine = EngineKeychainStore.makeItemStore(service: "svc", accessGroup: accessGroup)
            let engineLines = capture.lines

            XCTAssertEqual(engine.attributes, plugin.itemStore.attributes, "\(accessGroup ?? "-")")
            XCTAssertEqual(pluginLines.count, 1)
            XCTAssertEqual(engineLines, pluginLines, "\(accessGroup ?? "-")")
        }
    }

    /// Test that the quiet variant is `KeychainStore.quietBackingStore`
    ///
    /// - Given: A production item store and a test double
    /// - When:
    ///    - Each is passed to `EngineKeychainStore.quiet(_:)`
    /// - Then:
    ///    - The production store comes back with the same attributes and logs its failures at verbose
    ///      level only; the double comes back as it is
    ///
    func testQuietMatchesQuietBackingStore() throws {
        let production = EngineKeychainStore.makeItemStore(service: "svc", accessGroup: "grp")
        let quiet = try XCTUnwrap(EngineKeychainStore.quiet(production) as? KeychainItemStore)
        XCTAssertEqual(quiet.attributes, production.attributes)
        XCTAssertEqual(
            quiet.attributes,
            try XCTUnwrap(KeychainStore(service: "svc", accessGroup: "grp").quietBackingStore as? KeychainItemStore).attributes
        )

        // `hasItems()` over the real keychain fails unsigned; whatever it logs must be verbose only.
        capture.clear()
        _ = try? quiet.hasItems()
        XCTAssertEqual(capture.lines.filter { $0.level != "verbose" }, [])

        let double = InMemoryKeychain().store(service: "svc")
        XCTAssertTrue(EngineKeychainStore.quiet(double) is InMemoryKeychainItemStore)
    }

    // MARK: Helpers

    /// Both results equal, or both failures the same error once the public one is converted.
    private func assertSame<Value: Equatable>(
        _ engine: @autoclosure () throws -> Value,
        _ plugin: @autoclosure () throws -> Value,
        _ label: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let engineResult = Result { try engine() }
        let pluginResult = Result { try plugin() }
        switch (engineResult, pluginResult) {
        case (.success(let engineValue), .success(let pluginValue)):
            XCTAssertEqual(engineValue, pluginValue, label, file: file, line: line)
        case (.failure(let engineError), .failure(let pluginError)):
            guard let engineError = engineError as? EngineCredentialStoreError,
                  let pluginError = pluginError as? KeychainStoreError else {
                return XCTFail("\(label): \(engineError) / \(pluginError)", file: file, line: line)
            }
            XCTAssertEqual(engineError.debugDescription, pluginError.debugDescription, label, file: file, line: line)
            XCTAssertEqual(
                EngineCredentialStoreErrorTests.shape(engineError),
                EngineCredentialStoreErrorTests.shape(pluginError),
                label,
                file: file,
                line: line
            )
        default:
            XCTFail("\(label): \(engineResult) / \(pluginResult)", file: file, line: line)
        }
    }

    private func assertSame(
        _ engine: @autoclosure () throws -> Void,
        _ plugin: @autoclosure () throws -> Void,
        _ label: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        struct Done: Equatable {}
        assertSame(try { try engine()
        return Done()
        }(), try { try plugin()
        return Done()
        }(), label, file: file, line: line)
    }
}
