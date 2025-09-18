//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

struct ASFDeviceInfo: ASFDeviceBehavior {

    let id: String

    init(id: String) {
        self.id = id
    }

    var model: String {
        get async {
            await MainActor.run { DeviceInfo.current.model }
        }
    }

    var name: String {
        get async {
            await MainActor.run { DeviceInfo.current.name }
        }
    }

    var type: String {
        get async {
            await MainActor.run {
                var systemInfo = utsname()
                uname(&systemInfo)
                return String(
                    bytes: Data(
                        bytes: &systemInfo.machine,
                        count: Int(_SYS_NAMELEN)
                    ),
                    encoding: .utf8
                ) ?? DeviceInfo.current.hostName
            }
        }
    }

    var platform: String {
        get async {
            await MainActor.run { DeviceInfo.current.operatingSystem.name }
        }
    }

    var version: String {
        get async {
            await MainActor.run { DeviceInfo.current.operatingSystem.version }
        }
    }

    var thirdPartyId: String? {
        get async {
            await MainActor.run { DeviceInfo.current.identifierForVendor?.uuidString }
        }
    }

    var height: String {
        get async {
            await MainActor.run { String(format: "%.0f", DeviceInfo.current.screenBounds.height) }
        }
    }

    var width: String {
        get async {
            await MainActor.run { String(format: "%.0f", DeviceInfo.current.screenBounds.width) }
        }
    }

    var locale: String {
        get async {
            await MainActor.run { Locale.preferredLanguages[0] }
        }
    }

    func deviceInfo() async -> String {
        let model = await self.model
        let type = await self.type
        let version = await self.version
        var build = "release"
#if DEBUG
        build = "debug"
#endif
        return "Apple/\(model)/\(type)/-:\(version)/-/-:-/\(build)"
    }
}
