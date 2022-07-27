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
