//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

public struct AWSCognitoSecureStoragePreferences {

    /// The access group that the keychain will use for auth items
    public let accessGroup: AccessGroup?
    
    public let migrateKeychainItemsOfUserSession: Bool

    public init(accessGroup: AccessGroup? = nil, migrateKeychainItemsOfUserSession: Bool = true) {
        self.accessGroup = accessGroup
        self.migrateKeychainItemsOfUserSession = migrateKeychainItemsOfUserSession
    }
}
