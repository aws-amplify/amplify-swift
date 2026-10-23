//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

import AWSPluginsCore
import InternalAmplifyKeychain
@testable import AWSCognitoAuthPlugin

// `@unchecked Sendable`: the protocol it conforms to now requires `Sendable`. Test double driven

// by a single test at a time.

class MockKeychainStoreBehavior: LegacyKeychainItemStoreDouble, @unchecked Sendable {

    typealias VoidHandler = () -> Void

    let data: String
    let removeAllHandler: VoidHandler?
    /// Returns the error a read of the given key should throw, or `nil` to return `data`.
    let readErrorForKey: ((String) -> Error?)?
    /// The error `hasItems()` should throw, or `nil` to report whether `data` is non-empty.
    let hasItemsError: Error?

    init(
        data: String,
        removeAllHandler: VoidHandler? = nil,
        readErrorForKey: ((String) -> Error?)? = nil,
        hasItemsError: Error? = nil
    ) {
        self.data = data
        self.removeAllHandler = removeAllHandler
        self.readErrorForKey = readErrorForKey
        self.hasItemsError = hasItemsError
    }

    func getData(_ key: String) throws -> Data {
        if let error = readErrorForKey?(key) {
            throw error
        }
        return Data(data.utf8)
    }

    func set(_ value: Data, key: String) throws { }

    func remove(_ key: String) throws {
    }

    func removeAll() throws {
        removeAllHandler?()
    }

    func hasItems() throws -> Bool {
        if let hasItemsError {
            throw hasItemsError
        }
        return !data.isEmpty
    }
}
