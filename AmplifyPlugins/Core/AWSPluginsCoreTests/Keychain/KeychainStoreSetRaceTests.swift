//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AmplifyKeychainTestCommon
import Foundation
import InternalAmplifyKeychain
import XCTest
@_spi(KeychainStore) @testable import AWSPluginsCore

/// `KeychainStore._set` delegates to `KeychainItemStore.set`, so it survives the same lost race: another writer
/// creating the item between the check and the add. This is how the plugin's credential store writes its
/// `authConfiguration` item while a Cognito client restoring `.default` writes the same item.
class KeychainStoreSetRaceTests: XCTestCase {

    /// Test that `_set` updates the item when another writer adds it between the check and the add
    ///
    /// - Given: A `KeychainStore` over a `KeychainItemStore` whose `SecItem` calls go to a double, with no item
    /// - When:
    ///    - `_set` runs, and another writer adds the item after the check and before the add
    /// - Then:
    ///    - `_set` does not throw, the item holds `_set`'s value, and the calls are check, add, update
    ///
    func testSetUpdatesWhenAnotherWriterAddsBetweenTheCheckAndTheAdd() throws {
        let keychain = SecItemKeychainDouble()
        let attributes = KeychainStore(service: "com.amplify.test.setRace").itemStore.attributes
        let store = KeychainStore(
            service: attributes.service,
            itemStore: KeychainItemStore(
                attributes: attributes,
                logger: AmplifyLoggerBridge<KeychainStore>(),
                secItem: keychain.secItemCalls
            )
        )
        let account = "amplify.pool.authConfiguration"
        keychain.beforeNext(.add) { $0.store(Data("theirs".utf8), account: account) }

        try store._set(Data("ours".utf8), key: account)

        XCTAssertEqual(keychain.value(for: account), Data("ours".utf8))
        XCTAssertEqual(keychain.calls, [.copyMatching, .add, .update])
    }
}
