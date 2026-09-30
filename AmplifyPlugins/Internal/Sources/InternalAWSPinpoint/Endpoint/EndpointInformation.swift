//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

struct EndpointInformation: Sendable {
    typealias Platform = (name: String, version: String)

    let model: String
    let appVersion: String
    let platform: Platform
}

/// - Note: `Sendable` because the endpoint client awaits this from its own async setup path.
protocol EndpointInformationProvider: Sendable {
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
