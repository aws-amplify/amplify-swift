//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@preconcurrency import Foundation
import Security

// swiftlint:disable identifier_name
/// The `SecItem` dictionary keys and values used by every keychain query in the repo.
///
/// These were previously `KeychainStore.Constants` in `AWSPluginsCore`, which still exposes them under
/// that name. Changing any value here changes the identity of every stored item.
package enum KeychainConstants {
    /** Class Key Constant */
    package static let Class = String(kSecClass)
    package static let ClassGenericPassword = String(kSecClassGenericPassword)

    /** Attribute Key Constants */
    package static let AttributeAccessGroup = String(kSecAttrAccessGroup)
    package static let AttributeAccount = String(kSecAttrAccount)
    package static let AttributeService = String(kSecAttrService)
    package static let AttributeGeneric = String(kSecAttrGeneric)
    package static let AttributeLabel = String(kSecAttrLabel)
    package static let AttributeComment = String(kSecAttrComment)
    package static let AttributeAccessible = String(kSecAttrAccessible)
    package static let AttributeSynchronizable = String(kSecAttrSynchronizable)

    /** Attribute Accessible Constants */
    package static let AttributeAccessibleAfterFirstUnlockThisDeviceOnly = String(kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly)

    /** Search Constants */
    package static let MatchLimit = String(kSecMatchLimit)
    package static let MatchLimitOne = kSecMatchLimitOne
    package static let MatchLimitAll = kSecMatchLimitAll

    /** Return Type Key Constants */
    package static let ReturnData = String(kSecReturnData)
    package static let ReturnAttributes = String(kSecReturnAttributes)
    package static let ReturnRef = String(kSecReturnRef)

    /** Value Type Key Constants */
    package static let ValueData = String(kSecValueData)

    /** Indicates whether to treat macOS keychain items like iOS keychain items without setting kSecAttrSynchronizable */
    package static let UseDataProtectionKeyChain = String(kSecUseDataProtectionKeychain)
}
// swiftlint:enable identifier_name
