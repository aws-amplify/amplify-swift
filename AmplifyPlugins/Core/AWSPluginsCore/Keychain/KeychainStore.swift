//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Security

public protocol KeychainStoreBehavior {

    @_spi(KeychainStore)
    func _getString(_ key: String) throws -> String
    @_spi(KeychainStore)
    func _getData(_ key: String) throws -> Data
    @_spi(KeychainStore)
    func _set(_ value: String, key: String) throws
    @_spi(KeychainStore)
    func _set(_ value: Data, key: String) throws
    @_spi(KeychainStore)
    func _remove(_ key: String) throws
    @_spi(KeychainStore)
    func _removeAll() throws
}

public struct KeychainStore: KeychainStoreBehavior {

    let attributes: KeychainStoreAttributes

    private init(attributes: KeychainStoreAttributes) {
        self.attributes = attributes
    }

    public init() {
        guard let bundleIdentifier = Bundle.main.bundleIdentifier else {
            fatalError("Unable to retrieve bundle identifier to initialize keychain")
        }
        self.init(service: bundleIdentifier)
    }

    public init(service: String) {
        self.init(service: service, accessGroup: nil)
    }

    public init(service: String, accessGroup: String? = nil) {
        var attributes = KeychainStoreAttributes(service: service)
        attributes.accessGroup = accessGroup
        self.init(attributes: attributes)
    }

    @_spi(KeychainStore)
    public func _getString(_ key: String) throws -> String {

        let data = try _getData(key)

        guard let string = String(data: data, encoding: .utf8) else {
            throw KeychainStoreError.conversionError("Unable to create String from Data retrieved")
        }
        return string

    }

    @_spi(KeychainStore)
    public func _getData(_ key: String) throws -> Data {
        var query = attributes.query()

        query[Constants.MatchLimit] = Constants.MatchLimitOne
        query[Constants.ReturnData] = kCFBooleanTrue

        query[Constants.AttributeAccount] = key

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        switch status {
        case errSecSuccess:
            guard let data = result as? Data else {
                throw KeychainStoreError.unknown("The keychain item retrieved is not the correct type")
            }
            return data
        case errSecItemNotFound:
            throw KeychainStoreError.itemNotFound
        default:
            throw KeychainStoreError.securityError(status)
        }
    }

    @_spi(KeychainStore)
    public func _set(_ value: String, key: String) throws {
        guard let data = value.data(using: .utf8, allowLossyConversion: false) else {
            throw KeychainStoreError.conversionError("Unable to create Data from String retrieved")
        }
        try _set(data, key: key)
    }

    @_spi(KeychainStore)
    public func _set(_ value: Data, key: String) throws {
        var query = attributes.query()
        query[Constants.AttributeAccount] = key

        let fetchStatus = SecItemCopyMatching(query as CFDictionary, nil)
        switch fetchStatus {
        case errSecSuccess:

            var attributesToUpdate = [String: Any]()
            attributesToUpdate[Constants.ValueData] = value

            let updateStatus = SecItemUpdate(query as CFDictionary, attributesToUpdate as CFDictionary)
            if updateStatus != errSecSuccess {
                throw KeychainStoreError.securityError(updateStatus)
            }
        case errSecItemNotFound:
            let attributes = attributes.fetchAll(for: key, and: value)

            let addStatus = SecItemAdd(attributes as CFDictionary, nil)
            if addStatus != errSecSuccess {
                throw KeychainStoreError.securityError(addStatus)
            }
        default:
            throw KeychainStoreError.securityError(fetchStatus)
        }
    }

    @_spi(KeychainStore)
    public func _remove(_ key: String) throws {
        var query = attributes.query()
        query[Constants.AttributeAccount] = key

        let status = SecItemDelete(query as CFDictionary)
        if status != errSecSuccess && status != errSecItemNotFound {
            throw KeychainStoreError.securityError(status)
        }
    }
    
    @_spi(KeychainStore)
    public func _removeAll() throws {
        var query = attributes.query()
#if !os(iOS) && !os(watchOS) && !os(tvOS)
        query[Constants.MatchLimit] = Constants.MatchLimitAll
#endif

        let status = SecItemDelete(query as CFDictionary)
        if status != errSecSuccess && status != errSecItemNotFound {
            throw KeychainStoreError.securityError(status)
        }
    }

}

extension KeychainStore {
    struct Constants {
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
        static let AttributeAccessible = String(kSecAttrAccessible)
        
        /** Attribute Accessible Constants */
        static let AttributeAccessibleAfterFirstUnlock = String(kSecAttrAccessibleAfterFirstUnlock)

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
}
