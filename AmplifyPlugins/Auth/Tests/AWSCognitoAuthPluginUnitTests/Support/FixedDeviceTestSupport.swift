//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import InternalAWSCognitoAuth

/// A device with fixed values, for unit tests. The system's device, `ASFDeviceInfo`, reads
/// `UIDevice` and `UIScreen` on the main thread; on a loaded simulator the first `UIScreen` read can block the
/// main thread for minutes, so no unit test reads it.
struct FixedASFDevice: ASFDeviceBehavior {
    let id: String
    let model = "iPhone"
    let name = "Unit Test Device"
    let platform = "iOS"
    let version = "26.0"
    let thirdPartyId: String? = "00000000-0000-4000-8000-000000000047"
    let height = "2868"
    let width = "1320"
    let locale = "en-US"
    let type = "arm64"

    func deviceInfo() async -> String {
        "Apple/\(model)/\(type)/-:\(version)/-/-:-/debug"
    }
}

/// The real advanced-security client over a `FixedASFDevice`: it encodes the context data exactly as
/// `CognitoUserPoolASF` does, but never reads the system's device.
struct FixedDeviceASF: AdvancedSecurityBehavior {
    private let base = CognitoUserPoolASF()

    /// What an engine's `makeAdvancedSecurity` is set to in unit tests.
    static let factory: UserPoolEnvironment.CognitoUserPoolASFFactory = { FixedDeviceASF() }

    func userContextData(
        for username: String,
        deviceInfo: ASFDeviceBehavior,
        appInfo: ASFAppInfoBehavior,
        configuration: UserPoolConfigurationData
    ) async throws -> String {
        try await base.userContextData(for: username, deviceInfo: deviceInfo, appInfo: appInfo, configuration: configuration)
    }

    func device(id: String) -> ASFDeviceBehavior {
        FixedASFDevice(id: id)
    }
}
