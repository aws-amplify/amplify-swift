//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import UIKit

/// Helper class to fetch information for Device Information Screen
@available(iOS 13.0.0, *)
struct DeviceInfoHelper {

    static func getDeviceInformation() -> [DeviceInfoItem] {
        var isSimulator = false
        #if targetEnvironment(simulator)
            isSimulator = true
        #endif
        return [
                DeviceInfoItem(type: .deviceName(UIDevice.current.name)),
                DeviceInfoItem(type: .systemName(UIDevice.current.systemName)),
                DeviceInfoItem(type: .systemVersion(UIDevice.current.systemVersion)),
                DeviceInfoItem(type: .modelName(UIDevice.current.model)),
                DeviceInfoItem(type: .localizedModelName(UIDevice.current.localizedModel)),
                DeviceInfoItem(type: .isSimulator(isSimulator))
            ]
    }
}
