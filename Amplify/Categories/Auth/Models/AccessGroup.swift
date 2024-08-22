//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// A structure representing an access group for managing keychain items.
public struct AccessGroup {
    /// The name of the access group.
    public let name: String?
    
    /// A flag indicating whether to migrate keychain items.
    public let migrateKeychainItems: Bool

    /**
     Initializes an `AccessGroup` with the specified name and migration option.
     
     - Parameter name: The name of the access group.
     - Parameter migrateKeychainItemsOfUserSession: A flag indicating whether to migrate keychain items. Defaults to `false`.
     */
    public init(name: String, migrateKeychainItemsOfUserSession: Bool = false) {
        self.init(name: name, migrateKeychainItems: migrateKeychainItemsOfUserSession)
    }

    /**
     Creates an `AccessGroup` instance with no specified name.
     
     - Parameter migrateKeychainItemsOfUserSession: A flag indicating whether to migrate keychain items.
     - Returns: An `AccessGroup` instance with the migration option set.
     */
    public static func none(migrateKeychainItemsOfUserSession: Bool) -> AccessGroup {
        return .init(migrateKeychainItems: migrateKeychainItemsOfUserSession)
    }

    /**
     A static property representing an `AccessGroup` with no name and no migration.
     
     - Returns: An `AccessGroup` instance with no name and the migration option set to `false`.
     */
    public static var none: AccessGroup {
        return .none(migrateKeychainItemsOfUserSession: false)
    }
    
    private init(name: String? = nil, migrateKeychainItems: Bool) {
        self.name = name
        self.migrateKeychainItems = migrateKeychainItems
    }
}
