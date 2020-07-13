//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

enum EnvironmentInfoItemType {
    case nodejsVersion
    case npmVersion
    case amplifyCLIVersion
    case podVersion
    case xcodeVersion
    case osVersion

    // Key descriptions for environment information
    var key: String {
        switch self {
        case .nodejsVersion:
            return "Node.js version"
        case .npmVersion:
            return "npm version"
        case .amplifyCLIVersion:
            return "Amplify CLI version"
        case .podVersion:
            return "CocoaPods version"
        case .xcodeVersion:
            return "Xcode version"
        case .osVersion:
            return "macOS version"
        }
    }
}
