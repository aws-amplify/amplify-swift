//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import InternalAmplifyKeychain
import Security
import XCTest
@testable import AWSPluginsCore

/// `KeychainStore` delegates to `InternalAmplifyKeychain`. These tests pin that the delegation targets
/// the same items and reports the same errors as before the extraction. The queries themselves are pinned
/// in `KeychainStorePreservedQueryTests`.
class KeychainStoreDelegationTests: XCTestCase {

    /// The shared implementation is built from exactly the attributes the store was created with.
    ///
    /// - Given: stores created with and without an access group
    /// - When: their shared implementation is inspected
    /// - Then:
    ///    - it uses the same item class, service and access group
    func testDelegateUsesSameAttributes() {
        let store = KeychainStore(service: "com.amplify.awsCognitoAuthPlugin")
        XCTAssertEqual(
            store.itemStore.attributes,
            KeychainItemAttributes(service: "com.amplify.awsCognitoAuthPlugin", accessGroup: nil)
        )

        let sharedStore = KeychainStore(service: "com.amplify.awsCognitoAuthPluginShared", accessGroup: "group")
        XCTAssertEqual(
            sharedStore.itemStore.attributes,
            KeychainItemAttributes(service: "com.amplify.awsCognitoAuthPluginShared", accessGroup: "group")
        )
        XCTAssertEqual(sharedStore.itemStore.attributes.itemClass, KeychainStore.Constants.ClassGenericPassword)
    }

    /// Every failure from the shared module maps to the case `KeychainStoreError` has always used,
    /// carrying the same status or message.
    ///
    /// - Given: each `KeychainAccessError` case
    /// - When: it is mapped
    /// - Then:
    ///    - `itemNotFound`, `securityError` and `unknown` map one-to-one, with payloads preserved
    func testErrorMappingIsOneToOne() {
        XCTAssertEqual(KeychainStoreError(KeychainAccessError.itemNotFound), .itemNotFound)

        guard case .securityError(let status) = KeychainStoreError(.securityError(errSecMissingEntitlement)) else {
            return XCTFail("Expected securityError")
        }
        XCTAssertEqual(status, errSecMissingEntitlement)

        guard case .unknown(let description, _) = KeychainStoreError(.unknown("The keychain item retrieved is not the correct type")) else {
            return XCTFail("Expected unknown")
        }
        XCTAssertEqual(description, "The keychain item retrieved is not the correct type")
    }

    /// The mapping wrapper converts only shared-module errors and passes everything else through.
    ///
    /// - Given: a body that throws a `KeychainAccessError`, and one that throws some other error
    /// - When: each runs inside `KeychainStoreError.mapping`
    /// - Then:
    ///    - the first surfaces as `KeychainStoreError` and the second is unchanged
    func testMappingConvertsOnlySharedModuleErrors() {
        struct Unrelated: Error {}
        func throwAccessError() throws {
            throw KeychainAccessError.itemNotFound
        }
        func throwUnrelatedError() throws {
            throw Unrelated()
        }

        XCTAssertThrowsError(try KeychainStoreError.mapping(throwAccessError)) { error in
            XCTAssertEqual(error as? KeychainStoreError, .itemNotFound)
        }
        XCTAssertThrowsError(try KeychainStoreError.mapping(throwUnrelatedError)) { error in
            XCTAssertTrue(error is Unrelated)
        }
    }
}
