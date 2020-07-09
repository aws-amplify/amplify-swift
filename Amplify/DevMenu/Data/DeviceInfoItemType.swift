//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import UIKit

/// Item types for each row in the Device Info screen
enum DeviceInfoItemType {
    case deviceName
    case systemName
    case systemVersion
    case modelName
    case localizedModelName
    case isSimulator

    var key: String {
        switch self {
        case .deviceName:
            return "Device Name"
        case  .systemName:
            return "System Name"
        case .systemVersion:
            return "System Version"
        case .modelName:
            return "Model Name"
        case .localizedModelName:
            return "Localized Model Name"
        case .isSimulator:
            return "Running on simulator"
        }
    }

    var value: String {
        switch self {
        case .deviceName:
            return UIDevice.current.name
        case  .systemName:
            return UIDevice.current.systemName
        case .systemVersion:
            return UIDevice.current.systemVersion
        case .modelName:
            return UIDevice.current.model
        case .localizedModelName:
            return UIDevice.current.localizedModel
        case .isSimulator:
            #if targetEnvironment(simulator)
            return "Yes"
            #else
            return "No"
            #endif
        }
    }
}
