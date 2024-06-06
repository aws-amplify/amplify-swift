//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

struct EndpointInformation {
    typealias Platform = (name: String, version: String)

    let model: String
    let appVersion: String
    let platform: Platform
}

protocol EndpointInformationProvider {
    func endpointInfo() async -> EndpointInformation
}

struct DefaultEndpointInformationProvider: EndpointInformationProvider {
    func endpointInfo() async -> EndpointInformation {
        let deviceInfo = await DeviceInfo.current
        let model = await deviceInfo.model
        let platform = await deviceInfo.operatingSystem
        let appVersion = Bundle.main.appVersion
        return EndpointInformation(model: model, appVersion: appVersion, platform: platform)
    }
}
