//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import AWSPinpointAnalyticsPlugin
import Foundation

class MockUserDefaults: UserDefaultsBehaviour {
    private var data: [String: UserDefaultsBehaviourValue] = [:]
    var mockedValue: UserDefaultsBehaviourValue?

    var saveCount = 0
    func save(_ value: UserDefaultsBehaviourValue?, forKey key: String) {
        saveCount += 1
        data[key] = value
    }

    func removeObject(forKey key: String) {
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
    func data(forKey key: String) -> Data? {
        dataForKeyCount += 1
        if let stored = data[key] as? Data {
            return stored
        }
        return mockedValue as? Data
    }

    func resetCounters() {
        saveCount = 0
        dataForKeyCount = 0
        stringForKeyCount = 0
    }
}
