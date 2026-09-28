//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSCognitoIdentityProvider
import Foundation

package struct UserPoolAnalytics: UserPoolAnalyticsBehavior {

    package static let AWSPinpointContextKeychainService = "com.amazonaws.AWSPinpointContext"
    package static let AWSPinpointContextKeychainUniqueIdKey = "com.amazonaws.AWSPinpointContextKeychainUniqueIdKey"
    package let pinpointEndpoint: String?

    package init(
        _ configuration: UserPoolConfigurationData?,
        credentialStoreEnvironment: CredentialStoreEnvironment
    ) throws {

        if let pinpointId = configuration?.pinpointAppId, !pinpointId.isEmpty {
            self.pinpointEndpoint = try UserPoolAnalytics.getInternalPinpointEndpoint(
                credentialStoreEnvironment)
        } else {
            self.pinpointEndpoint = nil
        }
    }

    package static func getInternalPinpointEndpoint(
        _ credentialStoreEnvironment: CredentialStoreEnvironment) throws -> String {

            let legacyKeychainStore = credentialStoreEnvironment.legacyKeychainStore(
                AWSPinpointContextKeychainService)

            guard
                let value = try? legacyKeychainStore._getString(
                AWSPinpointContextKeychainUniqueIdKey)
            else {
                let uniqueValue = UUID().uuidString.lowercased()
                try legacyKeychainStore._set(
                    AWSPinpointContextKeychainUniqueIdKey,
                    key: uniqueValue
                )
                return uniqueValue
            }
            return value
        }

    package func analyticsMetadata() -> CognitoIdentityProviderClientTypes.AnalyticsMetadataType? {
        if let pinpointEndpoint {
            return .init(analyticsEndpointId: pinpointEndpoint)
        }
        return nil
    }

}
