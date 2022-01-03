//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Security

struct AmplifyKeychain: CredentialStoreBehavior {

    let attributes: KeychainAttributes

    private init(attributes: KeychainAttributes) {
        self.attributes = attributes
    }

    init() {
        guard let bundleIdentifier = Bundle.main.bundleIdentifier else {
            fatalError("Unable to retrieve bundle identifier to initialize keychain")
        }
        self.init(service: bundleIdentifier)
    }

    init(service: String) {
        self.init(service: service, accessGroup: nil)
    }

    init(service: String, accessGroup: String? = nil) {
        var attributes = KeychainAttributes(service: service)
        attributes.accessGroup = accessGroup
        self.init(attributes: attributes)
    }

    func getString(_ key: String) throws -> String {

        let data = try getData(key)

        guard let string = String(data: data, encoding: .utf8) else {
            throw AmplifyKeychainError.conversionError("Unable to create String from Data retrieved")
        }
        return string

    }

    func getData(_ key: String) throws -> Data {
        var query = attributes.query()

        query[AmplifyKeychainConstant.MatchLimit] = AmplifyKeychainConstant.MatchLimitOne
        query[AmplifyKeychainConstant.ReturnData] = kCFBooleanTrue

        query[AmplifyKeychainConstant.AttributeAccount] = key

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        switch status {
        case errSecSuccess:
            guard let data = result as? Data else {
                throw AmplifyKeychainError.unknown("The keychain item retrieved is not the correct type")
            }
            return data
        case errSecItemNotFound:
            throw AmplifyKeychainError.itemNotFound
        default:
            throw AmplifyKeychainError.securityError(status)
        }
    }


    func set(_ value: String, key: String) throws {
        guard let data = value.data(using: .utf8, allowLossyConversion: false) else {
            throw AmplifyKeychainError.conversionError("Unable to create Data from String retrieved")
        }
        try set(data, key: key)
    }

    func set(_ value: Data, key: String) throws {
        var query = attributes.query()
        query[AmplifyKeychainConstant.AttributeAccount] = key

        let fetchStatus = SecItemCopyMatching(query as CFDictionary, nil)
        switch fetchStatus {
        case errSecSuccess:

            var attributesToUpdate = [String: Any]()
            attributesToUpdate[AmplifyKeychainConstant.ValueData] = value

            let updateStatus = SecItemUpdate(query as CFDictionary, attributesToUpdate as CFDictionary)
            if updateStatus != errSecSuccess {
                throw AmplifyKeychainError.securityError(updateStatus)
            }
        case errSecItemNotFound:
            let attributes = attributes.fetchAll(for: key, and: value)

            let addStatus = SecItemAdd(attributes as CFDictionary, nil)
            if addStatus != errSecSuccess {
                throw AmplifyKeychainError.securityError(addStatus)
            }
        default:
            throw AmplifyKeychainError.securityError(fetchStatus)
        }
    }

    // MARK:
    func remove(_ key: String) throws {
        var query = attributes.query()
        query[AmplifyKeychainConstant.AttributeAccount] = key

        let status = SecItemDelete(query as CFDictionary)
        if status != errSecSuccess && status != errSecItemNotFound {
            throw AmplifyKeychainError.securityError(status)
        }
    }

    func removeAll() throws {
        var query = attributes.query()
#if !os(iOS) && !os(watchOS) && !os(tvOS)
        query[MatchLimit] = MatchLimitAll
#endif

        let status = SecItemDelete(query as CFDictionary)
        if status != errSecSuccess && status != errSecItemNotFound {
            throw AmplifyKeychainError.securityError(status)
        }
    }

}
