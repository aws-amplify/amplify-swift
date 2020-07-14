//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import UIKit

/// Helper class to fetch Developer Environment Information
@available(iOS 13.0.0, *)
struct EnvironmentInfoHelper {

    static func getDeveloperEnvironmentInformation(devEnvInfo: DevEnvironmentInfo) -> [EnvironmentInfoItem] {
        return [
            EnvironmentInfoItem(type: .nodejsVersion(devEnvInfo.nodejsVersion)),
            EnvironmentInfoItem(type: .npmVersion(devEnvInfo.npmVersion)),
            EnvironmentInfoItem(type: .amplifyCLIVersion(devEnvInfo.amplifyCLIVersion)),
            EnvironmentInfoItem(type: .podVersion(devEnvInfo.podVersion)),
            EnvironmentInfoItem(type: .xcodeVersion(devEnvInfo.xcodeVersion)),
            EnvironmentInfoItem(type: .osVersion(devEnvInfo.osVersion))
        ]
    }
}
