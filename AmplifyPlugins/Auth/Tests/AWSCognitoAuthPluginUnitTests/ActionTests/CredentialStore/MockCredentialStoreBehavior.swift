//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

@testable import AWSCognitoAuthPlugin
import AWSPluginsCore

class MockKeychainStoreBehavior: KeychainStoreBehavior {

    typealias VoidHandler = () -> Void

    let data: String
    let allData: [(key: String, value: Data)]
    let removeAllHandler: VoidHandler?
    let mockKey: String = "mockKey"

    init(data: String,
         removeAllHandler: VoidHandler? = nil) {
        self.data = data
        self.removeAllHandler = removeAllHandler
        self.allData = [(key: mockKey, value: Data(data.utf8))]
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
    
    func _getAll() throws -> [(key: String, value: Data)] {
        return allData
    }
}
