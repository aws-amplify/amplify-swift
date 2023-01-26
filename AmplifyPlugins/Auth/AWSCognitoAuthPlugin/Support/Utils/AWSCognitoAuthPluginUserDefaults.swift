//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

struct AWSCognitoAuthPluginUserDefaults: AWSCognitoAuthPluginUserDefaultsBehavior {

    private let preferPrivateSessionKey = "AWSCognitoAuthPluginUserDefaults.privateSessionKey"

    var defaults: UserDefaults = .standard

    func storePreferredBrowserSession(privateSessionPrefered: Bool) {
        defaults.setValue(privateSessionPrefered, forKey: preferPrivateSessionKey)
    }

    func isPrivateSessionPreferred() -> Bool {
        return defaults.bool(forKey: preferPrivateSessionKey)
    }
}
