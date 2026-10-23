//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import InternalAmplifyKeychain
import XCTest

/// A `KeychainItemStoreBehavior` test double for the stores behind `legacyKeychainStoreFactory`.
///
/// The legacy paths (the AWSMobileClient migration and clear, the Pinpoint endpoint read) only read,
/// write, remove, clear and check for items, so a double implements `getData`, `set`, `remove`,
/// `removeAll` and `hasItems`. The other requirements default to failing the test that reaches them.
protocol LegacyKeychainItemStoreDouble: KeychainItemStoreBehavior {}

extension LegacyKeychainItemStoreDouble {

    func addIfAbsent(_ value: Data, key: String) throws -> Bool {
        XCTFail("A legacy store is never asked to \(#function)")
        return false
    }

    func replaceIfPresent(_ value: Data, key: String) throws -> Bool {
        XCTFail("A legacy store is never asked to \(#function)")
        return false
    }

    func move(_ key: String, to destination: KeychainItemAttributes) throws -> KeychainMoveOutcome {
        XCTFail("A legacy store is never asked to \(#function)")
        return .notFound
    }

    func move(_ entry: KeychainEntry, to destination: KeychainItemAttributes) throws -> KeychainMoveOutcome {
        XCTFail("A legacy store is never asked to \(#function)")
        return .notFound
    }

    func remove(_ entry: KeychainEntry) throws {
        XCTFail("A legacy store is never asked to \(#function)")
    }

    func allAccounts() throws -> [String] {
        XCTFail("A legacy store is never asked to \(#function)")
        return []
    }

    func allEntries() throws -> [KeychainEntry] {
        XCTFail("A legacy store is never asked to \(#function)")
        return []
    }
}
