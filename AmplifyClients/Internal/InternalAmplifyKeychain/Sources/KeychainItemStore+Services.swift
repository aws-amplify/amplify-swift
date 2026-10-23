//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AmplifyFoundation
@preconcurrency import Foundation
import Security

package extension KeychainItemStore {

    /// The services of every generic-password item this app can read, in every access group it can read, each once
    /// and sorted. Reads attributes only, no data, so one unreadable item cannot fail the listing.
    ///
    /// For a caller that must find services it cannot name in advance, such as AWSMobileClient's per-identity-pool
    /// credentials services. An empty keychain lists none; any other failure throws.
    ///
    /// - Parameter secItem: A test seam, the `SecItem` functions to call. `.system` everywhere else.
    static func allServices(secItem: SecItemCalls = .system, logger: any Logger) throws -> [String] {
        logger.verbose("[KeychainStore] Listing services in keychain")
        var result: AnyObject?
        let status = secItem.copyMatching(listServicesQuery() as CFDictionary, &result)
        return try services(fromStatus: status, result: result, logger: logger)
    }

    /// Every generic-password item, in any access group, attributes only: no service, account or access group is
    /// given, and `kSecMatchLimitAll` is set so the listing is not limited to one item.
    static func listServicesQuery() -> [String: Any] {
        [
            KeychainConstants.Class: KeychainConstants.ClassGenericPassword,
            KeychainConstants.UseDataProtectionKeyChain: kCFBooleanTrue as Any,
            KeychainConstants.MatchLimit: KeychainConstants.MatchLimitAll,
            KeychainConstants.ReturnAttributes: kCFBooleanTrue as Any
        ]
    }

    /// Interprets the outcome of `listServicesQuery()`: the distinct services, sorted. Items without a `String`
    /// service are dropped. `errSecItemNotFound` is an empty keychain, so it maps to `[]`; every other failure throws.
    static func services(fromStatus status: OSStatus, result: AnyObject?, logger: any Logger) throws -> [String] {
        switch status {
        case errSecSuccess:
            let items: [[String: Any]]
            if let many = result as? [[String: Any]] {
                items = many
            } else if let one = result as? [String: Any] {
                items = [one]
            } else {
                logger.error("[KeychainStore] The keychain listing retrieved is not the correct type")
                throw KeychainAccessError.unknown("The keychain listing retrieved is not the correct type")
            }
            let services = Set(items.compactMap { $0[KeychainConstants.AttributeService] as? String }).sorted()
            logger.verbose("[KeychainStore] Listed \(services.count) service(s) in keychain")
            return services
        case errSecItemNotFound:
            logger.verbose("[KeychainStore] Keychain has no services to list")
            return []
        default:
            logger.error("[KeychainStore] Error listing keychain services with status=\(status)")
            throw KeychainAccessError.securityError(status)
        }
    }
}
