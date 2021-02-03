//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

struct AWSCognitoAuthPluginUserDefaults {

    private static let preferPrivateSessionKey = "AWSCognitoAuthPluginUserDefaults.privateSessionKey"

    static func storePreferredBrowserSession(privateSessionPrefered: Bool) {
        UserDefaults.standard.setValue(privateSessionPrefered, forKey: preferPrivateSessionKey)
    }

    static func isPrivateSessionPreferred() -> Bool {
        return UserDefaults.standard.bool(forKey: preferPrivateSessionKey)
    }
}
