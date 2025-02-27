//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

public struct KeychainStoreMigrator {
    let oldAttributes: KeychainStoreAttributes
    let newAttributes: KeychainStoreAttributes
    
    public init(oldService: String, newService: String, oldAccessGroup: String?, newAccessGroup: String?) {
        self.oldAttributes = KeychainStoreAttributes(service: oldService, accessGroup: oldAccessGroup)
        self.newAttributes = KeychainStoreAttributes(service: newService, accessGroup: newAccessGroup)
    }
    
    public func migrate() throws {
        log.verbose("[KeychainStoreMigrator] Starting to migrate items")

        // Check if there are any existing items under the new service and access group
        let existingItemsQuery = newAttributes.defaultGetQuery()
        let existingItemsStatus = SecItemCopyMatching(existingItemsQuery as CFDictionary, nil)

        if existingItemsStatus == errSecSuccess {
            // Remove existing items to avoid duplicate item error
            try? KeychainStore(service: newAttributes.service, accessGroup: newAttributes.accessGroup)._removeAll()
        }
        
        var updateQuery = oldAttributes.defaultGetQuery()

        var updateAttributes = [String: Any]()
        updateAttributes[KeychainStore.Constants.AttributeService] = newAttributes.service
        updateAttributes[KeychainStore.Constants.AttributeAccessGroup] = newAttributes.accessGroup

        let updateStatus = SecItemUpdate(updateQuery as CFDictionary, updateAttributes as CFDictionary)
        switch updateStatus {
        case errSecSuccess:
            break
        case errSecItemNotFound:
            log.verbose("[KeychainStoreMigrator] No items to migrate, keychain under new access group is cleared")
        case errSecDuplicateItem:
            log.verbose("[KeychainStoreMigrator] Duplicate items found, could not migrate")
            return
        default:
            log.error("[KeychainStoreMigrator] Error of status=\(updateStatus) occurred when attempting to migrate items in keychain")
            throw KeychainStoreError.securityError(updateStatus)
        }

        log.verbose("[KeychainStoreMigrator] Successfully migrated items to new service and access group")
    }
}

extension KeychainStoreMigrator: DefaultLogger { }
