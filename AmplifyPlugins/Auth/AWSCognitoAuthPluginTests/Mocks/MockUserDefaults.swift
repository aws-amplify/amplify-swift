//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
@testable import AWSCognitoAuthPlugin

struct MockUserDefaults: AWSCognitoAuthPluginUserDefaultsBehavior {

    var userDefaultsDict: NSMutableDictionary

    let privateSessionKey = "AWSCognitoAuthPluginUnitTest.privateSessionKey"

    init() {
        self.userDefaultsDict = NSMutableDictionary()
    }

    func storePreferredBrowserSession(privateSessionPrefered: Bool) {
        userDefaultsDict.setValue(privateSessionPrefered, forKey: privateSessionKey)
    }

    func isPrivateSessionPreferred() -> Bool {
        return userDefaultsDict[privateSessionKey] as? Bool ?? false
    }
}
