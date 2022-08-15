//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

struct ASFDeviceInfo: ASFDeviceBehavior {

    let id: String

    init(id: String) {
        self.id = id
    }

    var model: String {
        DeviceInfo.current.model
    }

    var name: String {
        DeviceInfo.current.name
    }

    var type: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        return String(bytes: Data(bytes: &systemInfo.machine,
                                  count: Int(_SYS_NAMELEN)),
                      encoding: .utf8) ?? DeviceInfo.current.hostName
    }

    var platform: String {
        DeviceInfo.current.operatingSystem.name
    }

    var version: String {
        DeviceInfo.current.operatingSystem.version
    }

    var thirdPartyId: String? {
        DeviceInfo.current.identifierForVendor?.uuidString
    }

    var height: String {
        String(format: "%.0f", DeviceInfo.current.screenBounds.height)
    }

    var width: String {
        String(format: "%.0f", DeviceInfo.current.screenBounds.width)
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
