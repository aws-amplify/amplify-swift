//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

struct KeychainStoreAttributes {

    var itemClass: String = KeychainStore.Constants.ClassGenericPassword
    var service: String
    var accessGroup: String?

    var label: String?
    var comment: String?
}

extension KeychainStoreAttributes {

    func query() -> [String: Any] {
        var query: [String: Any] = [
            KeychainStore.Constants.Class: itemClass,
            KeychainStore.Constants.AttributeService: service
        ]
        if let accessGroup = accessGroup {
            query[KeychainStore.Constants.AttributeAccessGroup] = accessGroup
        }
        query[KeychainStore.Constants.AttributeAccessible] = KeychainStore.Constants.AttributeAccessibleAfterFirstUnlock
        query[KeychainStore.Constants.UseDataProtectionKeyChain] = kCFBooleanTrue
        return query
    }

    func fetchAll(for key: String?, and value: Data) -> [String: Any] {

        var attributes: [String: Any]

        if key != nil {
            attributes = query()
            attributes[KeychainStore.Constants.AttributeAccount] = key
        } else {
            attributes = [String: Any]()
        }

        attributes[KeychainStore.Constants.ValueData] = value

        if label != nil {
            attributes[KeychainStore.Constants.AttributeLabel] = label
        }
        if comment != nil {
            attributes[KeychainStore.Constants.AttributeComment] = comment
        }

        return attributes

    }
}
