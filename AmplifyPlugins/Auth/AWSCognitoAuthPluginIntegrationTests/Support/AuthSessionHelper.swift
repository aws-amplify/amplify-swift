//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import AWSMobileClient
@testable import Amplify
import AWSCognitoAuthPlugin

struct AuthSessionHelper {

    static func clearKeychain() {
        let bundleID = Bundle.main.bundleIdentifier
        let keychain = AWSUICKeyChainStore(service: "\(bundleID!).\(AWSCognitoIdentityUserPool.self)")
        keychain.removeAllItems()
    }

    static func invalidateSession(username: String) {
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
    }
}
