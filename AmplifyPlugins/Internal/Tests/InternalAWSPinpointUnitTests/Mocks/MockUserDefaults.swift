//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import InternalAWSPinpoint
import Foundation

class MockUserDefaults: UserDefaultsBehaviour {
    var data: [String: UserDefaultsBehaviourValue] = [:]
    var mockedValue: UserDefaultsBehaviourValue?

    func addMockValue(_ value: UserDefaultsBehaviourValue?, forKey key: String) {
        data[key] = value
    }

    var saveCount = 0
    func save(_ value: UserDefaultsBehaviourValue?, forKey key: String) {
        saveCount += 1
        data[key] = value
    }

    var removeObjectCount = 0
    func removeObject(forKey key: String) {
        removeObjectCount += 1
        data[key] = nil
    }

    var stringForKeyCount = 0
    func string(forKey key: String) -> String? {
        stringForKeyCount += 1
        if let stored = data[key] as? String {
            return stored
        }
        return mockedValue as? String
    }

    var dataForKeyCount = 0
    var dataForKeyCountMap: [String: Int] = [:]
    func data(forKey key: String) -> Data? {
        dataForKeyCountMap[key] = dataForKeyCountMap[key, default: 0] + 1
        dataForKeyCount += 1
        if let stored = data[key] as? Data {
            return stored
        }
        return mockedValue as? Data
    }

    var objectForKeyCount = 0
    func object(forKey key: String) -> Any? {
        objectForKeyCount += 1
        if let stored = data[key] {
            return stored
        }
        return mockedValue
    }

    func resetCounters() {
        saveCount = 0
        dataForKeyCount = 0
        stringForKeyCount = 0
    }
}
