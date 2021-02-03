//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

struct AWSCognitoAuthPluginUserDefaults: AWSCognitoAuthPluginUserDefaultsBehavior {

    private let preferPrivateSessionKey = "AWSCognitoAuthPluginUserDefaults.privateSessionKey"

    func storePreferredBrowserSession(privateSessionPrefered: Bool) {
        UserDefaults.standard.setValue(privateSessionPrefered, forKey: preferPrivateSessionKey)
    }

    func isPrivateSessionPreferred() -> Bool {
        return UserDefaults.standard.bool(forKey: preferPrivateSessionKey)
    }
}
