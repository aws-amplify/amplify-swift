//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public enum AccessGroup {
    case named(String, migrateKeychainItemsOfUserSession: Bool)
    case unnamed(migrateKeychainItemsOfUserSession: Bool)

    public init(name: String?, migrateKeychainItemsOfUserSession: Bool = false) {
        if let name = name {
            self = .named(name, migrateKeychainItemsOfUserSession: migrateKeychainItemsOfUserSession)
        } else {
            self = .unnamed(migrateKeychainItemsOfUserSession: migrateKeychainItemsOfUserSession)
        }
    }
}
