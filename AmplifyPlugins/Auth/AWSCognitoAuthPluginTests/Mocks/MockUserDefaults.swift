//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
@testable import AWSCognitoAuthPlugin

struct MockUserDefaults: AWSCognitoAuthPluginUserDefaultsBehavior {

    let userDefaults: UserDefaults
    let suiteName = "AWSCognitoAuthPluginUnitTest"
    let privateSessionKey = "AWSCognitoAuthPluginUnitTest.privateSessionKey"

    init() {
        self.userDefaults = UserDefaults.init(suiteName: suiteName)!
    }

    func storePreferredBrowserSession(privateSessionPrefered: Bool) {
        userDefaults.setValue(privateSessionPrefered, forKey: privateSessionKey)
    }

    func isPrivateSessionPreferred() -> Bool {
        return userDefaults.bool(forKey: privateSessionKey)
    }

    func clearDefaults() {
        userDefaults.removeObject(forKey: privateSessionKey)
    }
}
