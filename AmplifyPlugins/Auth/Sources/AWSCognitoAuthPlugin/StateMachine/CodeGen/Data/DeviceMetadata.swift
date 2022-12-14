//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSCognitoIdentityProvider
import Foundation

enum DeviceMetadata {

    case metadata(Data)

    case noData

    struct Data: Codable, Equatable {
        let deviceKey: String
        let deviceGroupKey: String
        let deviceSecret: String

        init(deviceKey: String,
             deviceGroupKey: String,
             deviceSecret: String = UUID().uuidString) {
            self.deviceKey = deviceKey
            self.deviceGroupKey = deviceGroupKey
            self.deviceSecret = deviceSecret
        }
    }
}

extension DeviceMetadata: Codable { }

extension DeviceMetadata: Equatable { }

extension DeviceMetadata: CustomDebugDictionaryConvertible {

    var debugDictionary: [String: Any] {
        switch self {
        case .noData:
            return ["noData": "noData"]
        case .metadata(let data):
            return [
                "deviceKey": data.deviceKey.masked(interiorCount: 5),
                "deviceGroupKey": data.deviceGroupKey.masked(interiorCount: 5),
                "deviceSecret": data.deviceSecret.masked(interiorCount: 5)
            ]
        }
    }
}

extension DeviceMetadata: CustomDebugStringConvertible {

    var debugDescription: String {
        debugDictionary.debugDescription
    }
}

extension CognitoIdentityProviderClientTypes.AuthenticationResultType {

    var deviceMetadata: DeviceMetadata {
        if let newDeviceMetadata = newDeviceMetadata,
           let deviceKey = newDeviceMetadata.deviceKey,
           let deviceGroupKey = newDeviceMetadata.deviceGroupKey {

            let data = DeviceMetadata.Data(
                deviceKey: deviceKey,
                deviceGroupKey: deviceGroupKey)

            return .metadata(data)
        }
        return .noData
    }

}
