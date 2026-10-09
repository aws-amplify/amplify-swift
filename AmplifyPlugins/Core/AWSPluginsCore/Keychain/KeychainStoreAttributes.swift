//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import InternalAmplifyKeychain

struct KeychainStoreAttributes {

    var itemClass: String = KeychainStore.Constants.ClassGenericPassword
    var service: String
    var accessGroup: String?

}

extension KeychainStoreAttributes {

    /// The same attributes as the shared keychain module's type, which builds every query.
    var itemAttributes: KeychainItemAttributes {
        KeychainItemAttributes(itemClass: itemClass, service: service, accessGroup: accessGroup)
    }

    func defaultGetQuery() -> [String: Any] {
        itemAttributes.defaultGetQuery()
    }

    func defaultSetQuery() -> [String: Any] {
        itemAttributes.defaultSetQuery()
    }
}
