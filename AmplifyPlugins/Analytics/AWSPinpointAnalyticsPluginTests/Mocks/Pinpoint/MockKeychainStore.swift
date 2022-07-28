//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSPluginsCore

class MockKeychainStore: KeychainStoreBehavior {
    var stringValues: [String: String] = [:]
    var dataValues: [String: Data] = [:]

    var stringForKeyCount = 0
    var stringForKeyCountMap: [String: Int] = [:]
    func _getString(_ key: String) throws -> String {
        stringForKeyCount += 1
        stringForKeyCountMap[key] = stringForKeyCountMap[key, default: 0] + 1
        return stringValues[key]!
    }

    var dataForKeyCount = 0
    var dataForKeyCountMap: [String: Int] = [:]
    func _getData(_ key: String) throws -> Data {
        dataForKeyCount += 1
        dataForKeyCountMap[key] = dataForKeyCountMap[key, default: 0] + 1
        guard let data = dataValues[key] else {
            throw KeychainStoreError.itemNotFound
        }
        return data
    }

    var saveStringCount = 0
    func _set(_ value: String, key: String) throws {
        saveStringCount += 1
        stringValues[key] = value
    }

    var saveDataCount = 0
    func _set(_ value: Data, key: String) throws {
        saveDataCount += 1
        dataValues[key] = value
    }

    var removeObjectCount = 0
    func _remove(_ key: String) throws {
        removeObjectCount += 1
        if stringValues.keys.contains(where: { $0 == key }) {
            stringValues.removeValue(forKey: key)
        }

        if dataValues.keys.contains(where: { $0 == key }) {
            dataValues.removeValue(forKey: key)
        }
    }
    
    func _removeAll() throws {
        stringValues.removeAll()
        dataValues.removeAll()
    }

    func resetCounters() {
        dataForKeyCount = 0
        stringForKeyCount = 0
        removeObjectCount = 0
        saveStringCount = 0
        saveDataCount = 0
    }
}
