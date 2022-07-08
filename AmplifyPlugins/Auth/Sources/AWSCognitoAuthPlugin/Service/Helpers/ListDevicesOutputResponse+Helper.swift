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
        let id = deviceKey ?? ""
        let name = ""
        var attributes: [String: String] = [:]
        if deviceAttributes != nil {
            for attr in deviceAttributes! {
                if attr.name != nil && attr.value != nil {
                    attributes[attr.name!] = attr.value!
                }
            }
        }
        let device = AWSAuthDevice(id: id,
                                   name: name,
                                   attributes: attributes,
                                   createdDate: deviceCreateDate,
                                   lastAuthenticatedDate: deviceLastAuthenticatedDate,
                                   lastModifiedDate: deviceLastModifiedDate)
        
        return device
    }
}
