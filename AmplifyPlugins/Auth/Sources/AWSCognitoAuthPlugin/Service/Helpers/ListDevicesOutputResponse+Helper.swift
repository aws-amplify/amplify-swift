//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import AWSCognitoIdentityProvider
import AWSPluginsCore

extension CognitoIdentityProviderClientTypes.DeviceType {

    func toAWSAuthDevice() -> AuthDevice {
        var attributes: [String: String] = [:]
        if let deviceAttributes {
            for attr in deviceAttributes {
                if let attrName = attr.name, let attrValue = attr.value {
                    attributes[attrName] = attrValue
                }
            }
        }
        return AWSAuthDevice(
            id: deviceKey ?? "",
            name: attributes["device_name", default: ""],
            attributes: attributes,
            createdDate: deviceCreateDate,
            lastAuthenticatedDate: deviceLastAuthenticatedDate,
            lastModifiedDate: deviceLastModifiedDate)
    }
}
