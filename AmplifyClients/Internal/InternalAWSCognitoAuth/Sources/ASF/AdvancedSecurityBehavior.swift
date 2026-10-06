//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

package protocol AdvancedSecurityBehavior {

    func userContextData(
        for username: String,
        deviceInfo: ASFDeviceBehavior,
        appInfo: ASFAppInfoBehavior,
        configuration: UserPoolConfigurationData
    ) async throws -> String

    /// The device the engine describes to Cognito: in the advanced-security context data, as the confirmed
    /// device's name (`ConfirmDevice`) and in the sign-up validation data (`SignUpInput`).
    ///
    /// The system's, `ASFDeviceInfo`, by default. A unit-test double returns a fixed device, so the test never
    /// reads `UIDevice` or `UIScreen` on the main thread.
    func device(id: String) -> ASFDeviceBehavior
}

package extension AdvancedSecurityBehavior {

    func device(id: String) -> ASFDeviceBehavior {
        ASFDeviceInfo(id: id)
    }
}

package protocol ASFDeviceBehavior: Sendable {

    var id: String { get }

    var model: String { get async }

    var name: String { get async }

    var platform: String { get async }

    var version: String { get async }

    var thirdPartyId: String? { get async }

    var height: String { get async }

    var width: String { get async }

    var locale: String { get async }

    var type: String { get async }

    func deviceInfo() async -> String
}

package protocol ASFAppInfoBehavior {

    var name: String? { get }

    var targetSDK: String { get }

    var version: String { get }

}
