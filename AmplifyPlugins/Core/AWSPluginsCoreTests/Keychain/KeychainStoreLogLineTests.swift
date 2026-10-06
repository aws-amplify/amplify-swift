//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import Amplify
import AmplifyKeychainTestCommon
@testable import AmplifyTestCommon
import Foundation
import InternalAmplifyKeychain
import XCTest
@_spi(KeychainStore) @testable import AWSPluginsCore

/// No `KeychainStore` log line names the keychain key: a device record's key holds the username.
/// The lines name the record kind instead, the key's last component.
class KeychainStoreLogLineTests: XCTestCase {

    private static let account = "amplify.p.alice.deviceMetadata"
    private var capture: MockLoggingCategoryPlugin!
    private var lines = AtomicValue<[String]>(initialValue: [])
    private var savedPlugins: [PluginKey: LoggingCategoryPlugin] = [:]
    private var savedLogLevel: LogLevel = .error

    override func setUp() {
        capture = MockLoggingCategoryPlugin()
        capture.listeners.append { [lines] message in lines.append(message) }
        savedPlugins = Amplify.Logging.plugins
        savedLogLevel = Amplify.Logging.logLevel
        Amplify.Logging.plugins = [capture.key: capture]
        Amplify.Logging.logLevel = .verbose
    }

    override func tearDown() {
        Amplify.Logging.plugins = savedPlugins
        Amplify.Logging.logLevel = savedLogLevel
        capture = nil
    }

    /// Test that the store's own lines, and its item store's, name the record kind and never the key
    ///
    /// - Given: A capturing logging plugin, a `KeychainStore` over the in-memory keychain, and one over the real
    ///   keychain with a service of this test's own (under `swift test` the runner is unsigned, so the keychain
    ///   refuses each call, which is logged too)
    /// - When:
    ///    - Each store reads and writes a string and data, and removes them, on key `amplify.p.alice.deviceMetadata`
    /// - Then:
    ///    - Lines were logged, the string lines name `kind=deviceMetadata`
    ///    - No line contains `alice`, the key or `key=`
    ///
    func testVerboseLinesNeverNameTheAccount() {
        let account = Self.account
        let inMemory = KeychainStore(service: "svc", itemStore: InMemoryKeychain().store(service: "svc"))
        let service = "com.amplify.test.logLines.\(UUID().uuidString)"
        let real = KeychainStore(service: service)
        defer { try? real._removeAll() }
        for store in [inMemory, real] {
            try? store._set("value", key: account)
            _ = try? store._getString(account)
            try? store._set(Data("value".utf8), key: account)
            _ = try? store._getData(account)
            try? store._remove(account)
        }

        let logged = lines.get()
        XCTAssertTrue(logged.contains { $0.contains("[KeychainStore] Started setting `String` for kind=deviceMetadata") }, "\(logged)")
        XCTAssertTrue(logged.contains { $0.contains("[KeychainStore] Successfully added `String` for kind=deviceMetadata") }, "\(logged)")
        XCTAssertTrue(logged.contains { $0.contains("[KeychainStore] Started setting `Data` for kind=deviceMetadata") }, "\(logged)")
        for line in logged {
            XCTAssertFalse(line.contains("alice"), line)
            XCTAssertFalse(line.contains(account), line)
            XCTAssertFalse(line.contains("key="), line)
        }
    }
}
