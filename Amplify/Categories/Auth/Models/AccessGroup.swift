//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public struct AccessGroup {
    public let name: String?
    public let migrateKeychainItems: Bool

    public init(name: String, migrateKeychainItemsOfUserSession: Bool = false) {
        self.init(name: name, migrateKeychainItems: migrateKeychainItemsOfUserSession)
    }

    public static func none(migrateKeychainItemsOfUserSession: Bool) -> AccessGroup {
        return .init(name: nil, migrateKeychainItems: migrateKeychainItemsOfUserSession)
    }

    public static var none: AccessGroup {
        return .none(migrateKeychainItemsOfUserSession: false)
    }

    private init(name: String?, migrateKeychainItems: Bool) {
        self.name = name
        self.migrateKeychainItems = migrateKeychainItems
    }
}
