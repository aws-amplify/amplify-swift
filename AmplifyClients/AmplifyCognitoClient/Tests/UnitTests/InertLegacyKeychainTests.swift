//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import InternalAmplifyKeychain
import XCTest
@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient

final class InertLegacyKeychainTests: XCTestCase {

    /// Every read misses, so the engine's legacy migration finds nothing to migrate.
    ///
    /// - Given: an inert legacy keychain from the engine factory, for each AWSMobileClient legacy service
    /// - When:
    ///    - a value is written under a key, and then the key is read
    /// - Then:
    ///    - the read throws `KeychainAccessError.itemNotFound` (absent, not a failure)
    ///    - the listings are empty and `hasItems` is `false`
    ///
    func testReadsAlwaysMiss() throws {
        for service in ["com.example.AWSCognitoIdentityUserPool", "com.example.AWSMobileClient", "com.amazonaws.AWSPinpointContext"] {
            let keychain = InertLegacyKeychain.factory(service)
            try keychain.set(Data("value".utf8), key: "key")
            XCTAssertTrue(try keychain.addIfAbsent(Data("value".utf8), key: "other"))

            XCTAssertThrowsError(try keychain.getData("key")) { error in
                XCTAssertEqual(error as? KeychainAccessError, .itemNotFound)
            }
            XCTAssertNil(try keychain.dataIfPresent("other"))
            XCTAssertEqual(try keychain.allAccounts(), [])
            XCTAssertEqual(try keychain.allEntries(), [])
            XCTAssertFalse(try keychain.hasItems())
        }
    }

    /// Every write, move and removal succeeds without changing anything, so the migration's wipe is a no-op.
    ///
    /// - Given: an inert legacy keychain
    /// - When:
    ///    - each mutating requirement is called
    /// - Then:
    ///    - none throws; `replaceIfPresent` reports no item, and both moves report `.notFound`
    ///
    func testMutationsAreDropped() throws {
        let keychain = InertLegacyKeychain()
        let destination = KeychainItemAttributes(service: "destination")

        XCTAssertFalse(try keychain.replaceIfPresent(Data("value".utf8), key: "key"))
        XCTAssertEqual(try keychain.move("key", to: destination), .notFound)
        XCTAssertEqual(try keychain.move(KeychainEntry(account: "key", accessGroup: nil), to: destination), .notFound)
        XCTAssertFalse(try keychain.setIfUnchanged(Data("value".utf8), key: "key", expecting: Data("old".utf8)))
        try keychain.remove("key")
        try keychain.remove(KeychainEntry(account: "key", accessGroup: "group"))
        try keychain.removeAll()
    }
}
