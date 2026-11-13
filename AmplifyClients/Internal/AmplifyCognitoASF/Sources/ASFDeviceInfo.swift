//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

package struct ASFDeviceInfo: ASFDeviceBehavior {

    package let id: String

    package init(id: String) {
        self.id = id
    }

    package var model: String {
        get async {
            await MainActor.run { EngineDeviceInfo.current.model }
        }
    }

    package var name: String {
        get async {
            await MainActor.run { EngineDeviceInfo.current.name }
        }
    }

    package var type: String {
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
                ) ?? EngineDeviceInfo.current.hostName
            }
        }
    }

    package var platform: String {
        get async {
            await MainActor.run { EngineDeviceInfo.current.operatingSystem.name }
        }
    }

    package var version: String {
        get async {
            await MainActor.run { EngineDeviceInfo.current.operatingSystem.version }
        }
    }

    package var thirdPartyId: String? {
        get async {
            await MainActor.run { EngineDeviceInfo.current.identifierForVendor?.uuidString }
        }
    }

    package var height: String {
        get async {
            await MainActor.run { String(format: "%.0f", EngineDeviceInfo.current.screenBounds.height) }
        }
    }

    package var width: String {
        get async {
            await MainActor.run { String(format: "%.0f", EngineDeviceInfo.current.screenBounds.width) }
        }
    }

    package var locale: String {
        get async {
            await MainActor.run { Locale.preferredLanguages[0] }
        }
    }

    package func deviceInfo() async -> String {
        let model = await model
        let type = await type
        let version = await version
        var build = "release"
#if DEBUG
        build = "debug"
#endif
        return "Apple/\(model)/\(type)/-:\(version)/-/-:-/\(build)"
    }
}
