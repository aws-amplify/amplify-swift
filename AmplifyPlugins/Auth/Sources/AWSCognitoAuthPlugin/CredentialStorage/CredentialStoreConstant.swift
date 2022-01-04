//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Security

struct CredentialStoreConstant {
    /** Class Key Constant */
    static let Class = String(kSecClass)
    static let ClassGenericPassword = String(kSecClassGenericPassword)

    /** Attribute Key Constants */
    static let AttributeAccessGroup = String(kSecAttrAccessGroup)
    static let AttributeAccount = String(kSecAttrAccount)
    static let AttributeService = String(kSecAttrService)
    static let AttributeGeneric = String(kSecAttrGeneric)
    static let AttributeLabel = String(kSecAttrLabel)
    static let AttributeComment = String(kSecAttrComment)

    /** Search Constants */
    static let MatchLimit = String(kSecMatchLimit)
    static let MatchLimitOne = kSecMatchLimitOne
    static let MatchLimitAll = kSecMatchLimitAll

    /** Return Type Key Constants */
    static let ReturnData = String(kSecReturnData)
    static let ReturnAttributes = String(kSecReturnAttributes)

    /** Value Type Key Constants */
    static let ValueData = String(kSecValueData)
}

