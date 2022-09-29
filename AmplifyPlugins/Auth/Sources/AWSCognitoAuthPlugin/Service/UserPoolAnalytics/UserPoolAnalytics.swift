//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSCognitoIdentityProvider
@_spi(KeychainStore) import AWSPluginsCore

struct UserPoolAnalytics: UserPoolAnalyticsBehavior {

    static let AWSPinpointContextKeychainService = "com.amazonaws.AWSPinpointContext"
    static let AWSPinpointContextKeychainUniqueIdKey = "com.amazonaws.AWSPinpointContextKeychainUniqueIdKey"
    let pinpointEndpoint: String?

    init(_ configuration: UserPoolConfigurationData?,
         credentialStoreEnvironment: CredentialStoreEnvironment) throws {

        if let pinpointId = configuration?.pinpointAppId, !pinpointId.isEmpty {
            pinpointEndpoint = try UserPoolAnalytics.getInternalPinpointEndpoint(
                credentialStoreEnvironment)
        } else {
            pinpointEndpoint = nil
        }
    }

    static func getInternalPinpointEndpoint(
        _ credentialStoreEnvironment: CredentialStoreEnvironment) throws -> String {

            let legacyKeychainStore = credentialStoreEnvironment.legacyKeychainStoreFactory(
                AWSPinpointContextKeychainService)

            guard
                let value = try? legacyKeychainStore._getString(
                AWSPinpointContextKeychainUniqueIdKey)
            else {
                let uniqueValue = UUID().uuidString.lowercased()
                try legacyKeychainStore._set(AWSPinpointContextKeychainUniqueIdKey,
                                              key: uniqueValue)
                return uniqueValue
            }
            return value
        }

    func analyticsMetadata() -> CognitoIdentityProviderClientTypes.AnalyticsMetadataType? {
        if let pinpointEndpoint = pinpointEndpoint {
            return .init(analyticsEndpointId: pinpointEndpoint)
        }
        return nil
    }

}
