//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import Amplify
import AWSCognitoAuthPlugin

struct AuthSessionHelper {

    static func invalidateSession(username: String) {
        /* TODO: Find a way to invalidate session using SPM
        let bundleID = Bundle.main.bundleIdentifier
        let keychain = AWSUICKeyChainStore(service: "\(bundleID!).\(AWSCognitoIdentityUserPool.self)")
        let namespace = "\(AWSMobileClient.default().userPoolClient!.userPoolConfiguration.clientId).\(username)"
        let expirationKey = "\(namespace).tokenExpiration"
        let refreshTokenKey = "\(namespace).refreshToken"
        if keychain[expirationKey] == nil {
            print("No expiration key found in keychain")
        }
        keychain[expirationKey] = "2020-05-27T21:01:03Z"
        keychain[refreshTokenKey] = "invalid"
        */
    }
}
