//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

import AWSPluginsCore
@testable import AWSCognitoAuthPlugin

class MockKeychainStoreBehavior: KeychainStoreBehavior {

    typealias VoidHandler = () -> Void

    let data: String
    let removeAllHandler: VoidHandler?

    init(
        data: String,
        removeAllHandler: VoidHandler? = nil
    ) {
        self.data = data
        self.removeAllHandler = removeAllHandler
    }

    func _getString(_ key: String) throws -> String {
        return data
    }

    func _getData(_ key: String) throws -> Data {
        return Data(data.utf8)
    }

    func _set(_ value: String, key: String) throws { }

    func _set(_ value: Data, key: String) throws { }

    func _remove(_ key: String) throws {
    }

    func _removeAll() throws {
        removeAllHandler?()
    }
}
