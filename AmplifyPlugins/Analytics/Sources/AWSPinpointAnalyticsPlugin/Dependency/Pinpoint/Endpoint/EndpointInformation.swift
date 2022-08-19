//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

protocol EndpointInformation {
    typealias Platform = (name: String, version: String)

    var model: String { get }
    var appVersion: String { get }
    var platform: Platform { get }
}

extension DeviceInfo: EndpointInformation {
    var appVersion: String {
        Bundle.main.appVersion
    }

    var platform: Platform {
        operatingSystem
    }
}

extension EndpointInformation where Self == DeviceInfo {
    static var current: EndpointInformation {
        DeviceInfo.current
    }
}
