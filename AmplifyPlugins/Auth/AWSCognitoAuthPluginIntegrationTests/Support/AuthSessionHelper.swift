//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import AWSMobileClient
@testable import Amplify
import AWSCognitoAuthPlugin

struct AuthSessionHelper {

    static func invalidateSession(username: String) {
        let bundleID = Bundle.main.bundleIdentifier
        let keychain = AWSUICKeyChainStore(service: "\(bundleID!).\(AWSCognitoIdentityUserPool.self)")
        let namespace = "\(AWSMobileClient.default().userPoolClient!.userPoolConfiguration.clientId).\(username)"
        let key = "\(namespace).tokenExpiration"
        keychain.removeItem(forKey: key)
    }
}
