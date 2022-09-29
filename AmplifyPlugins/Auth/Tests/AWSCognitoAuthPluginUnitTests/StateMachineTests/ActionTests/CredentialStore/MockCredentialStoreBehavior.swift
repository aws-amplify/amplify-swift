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

    var data: [String: Any] = [:]
    let removeAllHandler: VoidHandler?

    init(removeAllHandler: VoidHandler? = nil) {
        self.removeAllHandler = removeAllHandler
    }

    func _getString(_ key: String) throws -> String {
        return (data[key] as? String) ?? ""
    }

    func _getData(_ key: String) throws -> Data {
        guard let internalData = data[key] as? Data else {
            return Data()
        }
        return internalData
    }

    func _set(_ value: String, key: String) throws {
        data[key] = value
    }

    func _set(_ value: Data, key: String) throws {
        data[key] = value
    }

    func _remove(_ key: String) throws {
        data.removeValue(forKey: key)
    }

    func _removeAll() throws {
        removeAllHandler?()
    }
}
