//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
protocol Device {
    typealias Platform = (name: String, version: String)
    
    var model: String { get }
    var appVersion: String? { get }
    var platform: Platform { get }
}

#if canImport(UIKit)
import UIKit

extension UIDevice: Device {
    var appVersion: String? {
        return Bundle.main.appVersion
    }
    
    var platform: Platform {
        return (name: systemName, version: systemVersion)
    }
}
#endif

class DeviceProvider {
    static var current: Device {
#if canImport(UIKit)
        return UIDevice.current
#endif
    }
}
