//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AmplifyFoundation
import Foundation
import Security
import XCTest
@testable import InternalAmplifyKeychain

/// No `KeychainItemStore` log line names the account it works on: a device record's account
/// holds the username, and a client session record's holds the session ID. The lines name the record kind
/// instead, the account's last component.
final class KeychainItemStoreLogLineTests: XCTestCase {

    private static let account = "amplify.p.alice.deviceMetadata"

    /// Test that every operation logs the record kind and never the account
    ///
    /// - Given: A capturing logger behind a `KeychainItemStore` for a service of this test's own
    /// - When:
    ///    - Each operation runs on account `amplify.p.alice.deviceMetadata` (set, get, add-if-absent,
    ///      replace-if-present, set-if-unchanged, move, remove), and then each status interpreter is fed the
    ///      success, not-found and refused statuses for it. Under `swift test` the keychain refuses every call
    ///      (an unsigned runner); on a simulator they succeed. Both paths are logged
    /// - Then:
    ///    - Lines were logged at verbose level, and those that speak of the item name `kind=deviceMetadata`
    ///    - No line, at any level, contains `alice` or the account
    ///
    func testVerboseLinesNeverNameTheAccount() throws {
        let logger = RecordingLogger()
        let service = "com.amplify.test.logLines.\(UUID().uuidString)"
        let store = KeychainItemStore(attributes: KeychainItemAttributes(service: service, accessGroup: nil), logger: logger)
        let destination = KeychainItemAttributes(service: "\(service).moved", accessGroup: nil)
        defer {
            try? KeychainItemStore(attributes: KeychainItemAttributes(service: service, accessGroup: nil), logger: logger).removeAll()
            try? KeychainItemStore(attributes: destination, logger: logger).removeAll()
        }
        let value = Data("value".utf8)
        let account = Self.account

        try? store.set(value, key: account)
        _ = try? store.getData(account)
        _ = try? store.addIfAbsent(value, key: account)
        _ = try? store.replaceIfPresent(value, key: account)
        _ = try? store.setIfUnchanged(value, key: account, expecting: value)
        _ = try? store.move(account, to: destination)
        try? store.remove(account)

        _ = try? KeychainItemStore.data(fromStatus: errSecSuccess, result: value as NSData, key: account, logger: logger)
        _ = try? KeychainItemStore.data(fromStatus: errSecItemNotFound, result: nil, key: account, logger: logger)
        _ = try? KeychainItemStore.data(fromStatus: errSecInteractionNotAllowed, result: nil, key: account, logger: logger)
        for status in [errSecSuccess, errSecDuplicateItem, errSecInteractionNotAllowed] {
            _ = try? KeychainItemStore.writeOutcome(fromStatus: status, refusedBy: errSecDuplicateItem, key: account, logger: logger)
        }

        let verbose = logger.messages(at: .verbose)
        XCTAssertFalse(verbose.isEmpty)
        XCTAssertTrue(verbose.contains("[KeychainStore] Started setting `Data` for kind=deviceMetadata"), "\(verbose)")
        XCTAssertTrue(
            verbose.contains("[KeychainStore] Successfully retrieved `Data` from the store with kind=deviceMetadata"),
            "\(verbose)"
        )
        XCTAssertTrue(verbose.contains("[KeychainStore] Conditional write succeeded for kind=deviceMetadata"), "\(verbose)")
        let everyLine = LogLevel.allLevels.flatMap { logger.messages(at: $0) }
        for line in everyLine {
            XCTAssertFalse(line.contains("alice"), line)
            XCTAssertFalse(line.contains(account), line)
            XCTAssertFalse(line.contains("key="), line)
        }
    }
}

private extension LogLevel {
    static let allLevels: [LogLevel] = [.error, .warn, .info, .debug, .verbose]
}
