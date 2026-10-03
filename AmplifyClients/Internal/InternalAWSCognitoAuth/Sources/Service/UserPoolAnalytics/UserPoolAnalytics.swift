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

    /// - Parameter logger: the caller's, which the Pinpoint context's keychain store logs through.
    package init(
        _ configuration: UserPoolConfigurationData?,
        credentialStoreEnvironment: CredentialStoreEnvironment,
        logger: any EngineScopedLogger
    ) throws {

        if let pinpointId = configuration?.pinpointAppId, !pinpointId.isEmpty {
            self.pinpointEndpoint = try UserPoolAnalytics.getInternalPinpointEndpoint(
                credentialStoreEnvironment,
                logger: logger
            )
        } else {
            self.pinpointEndpoint = nil
        }
    }

    package static func getInternalPinpointEndpoint(
        _ credentialStoreEnvironment: CredentialStoreEnvironment,
        logger: any EngineScopedLogger
    ) throws -> String {

            let legacyKeychainStore = credentialStoreEnvironment.legacyKeychainStore(
                AWSPinpointContextKeychainService,
                logger: logger
            )

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
