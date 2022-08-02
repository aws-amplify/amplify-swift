//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import UIKit

struct ASFUIDeviceInfo: ASFDeviceBehavior {

    let id: String

    init(id: String) {
        self.id = id
    }

    var model: String {
        UIDevice.current.model
    }

    var name: String  {
        return UIDevice.current.name

    }

    var type: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        return String(bytes: Data(bytes: &systemInfo.machine,
                                  count: Int(_SYS_NAMELEN)),
                      encoding: .utf8) ?? ProcessInfo.processInfo.hostName
    }

    var platform: String {
        return UIDevice.current.systemName
    }

    var version: String  {
        UIDevice.current.systemVersion
    }

    var thirdPartyId: String?  {
        UIDevice.current.identifierForVendor?.uuidString
    }

    var height: String  {
        String(format: "%.0f", UIScreen.main.nativeBounds.size.height)
    }

    var width: String {
        String(format: "%.0f", UIScreen.main.nativeBounds.size.width)
    }

    var locale: String {
        return Locale.preferredLanguages[0]
    }
    
    func deviceInfo() -> String {
        var build = "release"
#if DEBUG
        build = "debug"
#endif
        return "Apple/\(model)/\(type)/-:\(version)/-/-:-/\(build)"
    }
}
