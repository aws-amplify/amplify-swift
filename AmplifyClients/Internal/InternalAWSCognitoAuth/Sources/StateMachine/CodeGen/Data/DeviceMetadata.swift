//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSCognitoIdentityProvider
import Foundation

package enum DeviceMetadata {

    case metadata(Data)

    case noData

    package struct Data: Codable, Equatable {
        package let deviceKey: String
        package let deviceGroupKey: String
        package let deviceSecret: String

        package init(
            deviceKey: String,
            deviceGroupKey: String,
            deviceSecret: String = UUID().uuidString
        ) {
            self.deviceKey = deviceKey
            self.deviceGroupKey = deviceGroupKey
            self.deviceSecret = deviceSecret
        }
    }
}

extension DeviceMetadata: Codable { }

extension DeviceMetadata: Equatable { }

// Three strings: sendable as it is. The Cognito client moves device records to its keychain queue.
extension DeviceMetadata: Sendable { }

extension DeviceMetadata.Data: Sendable { }

extension DeviceMetadata: CustomDebugDictionaryConvertible {

    package var debugDictionary: [String: Any] {
        switch self {
        case .noData:
            return ["noData": "noData"]
        case .metadata(let data):
            return [
                "deviceKey": data.deviceKey.maskedForLog(interiorCount: 5),
                "deviceGroupKey": data.deviceGroupKey.maskedForLog(interiorCount: 5),
                "deviceSecret": data.deviceSecret.maskedForLog(interiorCount: 5)
            ]
        }
    }
}

extension DeviceMetadata: CustomDebugStringConvertible {

    package var debugDescription: String {
        debugDictionary.debugDescription
    }
}

package extension CognitoIdentityProviderClientTypes.AuthenticationResultType {

    var deviceMetadata: DeviceMetadata {
        if let newDeviceMetadata,
           let deviceKey = newDeviceMetadata.deviceKey,
           let deviceGroupKey = newDeviceMetadata.deviceGroupKey {

            let data = DeviceMetadata.Data(
                deviceKey: deviceKey,
                deviceGroupKey: deviceGroupKey
            )

            return .metadata(data)
        }
        return .noData
    }

}
