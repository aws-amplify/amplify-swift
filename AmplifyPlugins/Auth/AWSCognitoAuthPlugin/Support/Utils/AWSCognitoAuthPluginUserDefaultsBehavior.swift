//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

protocol AWSCognitoAuthPluginUserDefaultsBehavior {

    func storePreferredBrowserSession(privateSessionPrefered: Bool)

    func isPrivateSessionPreferred() -> Bool
}
