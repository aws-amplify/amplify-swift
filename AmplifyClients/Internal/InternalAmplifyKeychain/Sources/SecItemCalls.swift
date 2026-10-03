//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Security

/// The four `SecItem` functions `KeychainItemStore` calls, so a test can stand in for the keychain at the
/// `SecItem` layer: to count the calls a member makes, or to have another writer land between two of them.
///
/// Every store an app creates uses `.system`, the Security framework's own functions.
package struct SecItemCalls: Sendable {

    package let copyMatching: @Sendable (_ query: CFDictionary, _ result: UnsafeMutablePointer<CFTypeRef?>?) -> OSStatus
    package let add: @Sendable (_ attributes: CFDictionary, _ result: UnsafeMutablePointer<CFTypeRef?>?) -> OSStatus
    package let update: @Sendable (_ query: CFDictionary, _ attributesToUpdate: CFDictionary) -> OSStatus
    package let delete: @Sendable (_ query: CFDictionary) -> OSStatus

    package init(
        copyMatching: @escaping @Sendable (_ query: CFDictionary, _ result: UnsafeMutablePointer<CFTypeRef?>?) -> OSStatus,
        add: @escaping @Sendable (_ attributes: CFDictionary, _ result: UnsafeMutablePointer<CFTypeRef?>?) -> OSStatus,
        update: @escaping @Sendable (_ query: CFDictionary, _ attributesToUpdate: CFDictionary) -> OSStatus,
        delete: @escaping @Sendable (_ query: CFDictionary) -> OSStatus
    ) {
        self.copyMatching = copyMatching
        self.add = add
        self.update = update
        self.delete = delete
    }

    /// `SecItemCopyMatching`, `SecItemAdd`, `SecItemUpdate` and `SecItemDelete`.
    package static let system = SecItemCalls(
        copyMatching: { SecItemCopyMatching($0, $1) },
        add: { SecItemAdd($0, $1) },
        update: { SecItemUpdate($0, $1) },
        delete: { SecItemDelete($0) }
    )
}
