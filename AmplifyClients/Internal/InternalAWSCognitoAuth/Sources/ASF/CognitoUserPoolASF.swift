//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AmplifyCognitoASF
import Foundation

/// The engine's advanced-security client. The encoding is `UserContextDataEncoder`'s, which
/// `CognitoUserContextData` shares.
package struct CognitoUserPoolASF: AdvancedSecurityBehavior {

    package init() {}

    package func userContextData(
        for username: String = "unknown",
        deviceInfo: ASFDeviceBehavior,
        appInfo: ASFAppInfoBehavior,
        configuration: UserPoolConfigurationData
    ) async throws -> String {
        let contextData = await UserContextDataEncoder.prepareUserContextData(deviceInfo: deviceInfo, appInfo: appInfo)
        return try UserContextDataEncoder.encodedData(
            username: username,
            contextData: contextData,
            userPoolId: configuration.poolId,
            clientId: configuration.clientId
        )
    }
}
