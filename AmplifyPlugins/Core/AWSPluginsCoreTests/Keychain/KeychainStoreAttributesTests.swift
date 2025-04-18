//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
@testable import AWSPluginsCore

class KeychainStoreAttributesTests: XCTestCase {

    var keychainStoreAttribute: KeychainStoreAttributes!

    /// Given: an instance of `KeychainStoreAttributes`
    /// When: `keychainStoreAttribute.defaultGetQuery()` is invoked with a required service param
    /// Then: Validate if the attributes contain the correct get query params
    ///     - AttributeService
    ///     - Class
    func testDefaultGetQuery() {
        keychainStoreAttribute = KeychainStoreAttributes(service: "someService")

        let defaultGetAttributes = keychainStoreAttribute.defaultGetQuery()
        XCTAssertEqual(defaultGetAttributes[KeychainStore.Constants.AttributeService] as? String, "someService")
        XCTAssertEqual(defaultGetAttributes[KeychainStore.Constants.Class] as? String, KeychainStore.Constants.ClassGenericPassword)
        XCTAssertNil(defaultGetAttributes[KeychainStore.Constants.AttributeAccessGroup] as? String)
        XCTAssertNil(defaultGetAttributes[KeychainStore.Constants.AttributeAccessible] as? String)
        XCTAssertNil(defaultGetAttributes[KeychainStore.Constants.UseDataProtectionKeyChain] as? String)
    }

    /// Given: an instance of `KeychainStoreAttributes`
    /// When: `keychainStoreAttribute.defaultGetQuery()` is invoked with a required service param and access group
    /// Then: Validate if the attributes contain the correct get query params
    ///     - AttributeService
    ///     - Class
    ///     - AttributeAccessGroup
    func testDefaultGetQueryWithAccessGroup() {
        keychainStoreAttribute = KeychainStoreAttributes(service: "someService", accessGroup: "someAccessGroup")

        let defaultGetAttributes = keychainStoreAttribute.defaultGetQuery()
        XCTAssertEqual(defaultGetAttributes[KeychainStore.Constants.AttributeService] as? String, "someService")
        XCTAssertEqual(defaultGetAttributes[KeychainStore.Constants.Class] as? String, KeychainStore.Constants.ClassGenericPassword)
        XCTAssertEqual(defaultGetAttributes[KeychainStore.Constants.AttributeAccessGroup] as? String, "someAccessGroup")
        XCTAssertNil(defaultGetAttributes[KeychainStore.Constants.AttributeAccessible] as? String)
        XCTAssertNil(defaultGetAttributes[KeychainStore.Constants.UseDataProtectionKeyChain] as? String)
    }
    
    /// Given: an instance of `KeychainStoreAttributes`
    /// When: `keychainStoreAttribute.defaultSetQuery()` is invoked with a required service param
    /// Then: Validate if the attributes contain the correct set query params
    ///     - AttributeService
    ///     - Class
    ///     - AttributeAccessible
    ///     - UseDataProtectionKeyChain
    func testDefaultSetQuery() {
        keychainStoreAttribute = KeychainStoreAttributes(service: "someService")

        let defaultSetAttributes = keychainStoreAttribute.defaultSetQuery()
        XCTAssertEqual(defaultSetAttributes[KeychainStore.Constants.AttributeService] as? String, "someService")
        XCTAssertEqual(defaultSetAttributes[KeychainStore.Constants.Class] as? String, KeychainStore.Constants.ClassGenericPassword)
        XCTAssertNil(defaultSetAttributes[KeychainStore.Constants.AttributeAccessGroup] as? String)
        XCTAssertEqual(defaultSetAttributes[KeychainStore.Constants.AttributeAccessible] as? String, KeychainStore.Constants.AttributeAccessibleAfterFirstUnlockThisDeviceOnly)
        XCTAssertEqual(defaultSetAttributes[KeychainStore.Constants.UseDataProtectionKeyChain] as? Bool, true)
    }

    /// Given: an instance of `KeychainStoreAttributes`
    /// When: `keychainStoreAttribute.defaultSetQuery()` is invoked with a required service param and access group
    /// Then: Validate if the attributes contain the correct set query params
    ///     - AttributeService
    ///     - Class
    ///     - AttributeAccessGroup
    ///     - AttributeAccessible
    ///     - UseDataProtectionKeyChain
    func testDefaultSetQueryWithAccessGroup() {
        keychainStoreAttribute = KeychainStoreAttributes(service: "someService", accessGroup: "someAccessGroup")

        let defaultSetAttributes = keychainStoreAttribute.defaultSetQuery()
        XCTAssertEqual(defaultSetAttributes[KeychainStore.Constants.AttributeService] as? String, "someService")
        XCTAssertEqual(defaultSetAttributes[KeychainStore.Constants.Class] as? String, KeychainStore.Constants.ClassGenericPassword)
        XCTAssertEqual(defaultSetAttributes[KeychainStore.Constants.AttributeAccessGroup] as? String, "someAccessGroup")
        XCTAssertEqual(defaultSetAttributes[KeychainStore.Constants.AttributeAccessible] as? String, KeychainStore.Constants.AttributeAccessibleAfterFirstUnlockThisDeviceOnly)
        XCTAssertEqual(defaultSetAttributes[KeychainStore.Constants.UseDataProtectionKeyChain] as? Bool, true)
    }

    override func tearDown() {
        keychainStoreAttribute = nil
    }
}
