//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

protocol AdvancedSecurityBehavior {

    func userContextData(
        for username: String,
        deviceInfo: ASFDeviceBehavior,
        appInfo: ASFAppInfoBehavior,
        configuration: UserPoolConfigurationData
    ) async throws -> String
}

protocol ASFDeviceBehavior: Sendable {

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

protocol ASFAppInfoBehavior {

    var name: String? { get }

    var targetSDK: String { get }

    var version: String { get }

}
