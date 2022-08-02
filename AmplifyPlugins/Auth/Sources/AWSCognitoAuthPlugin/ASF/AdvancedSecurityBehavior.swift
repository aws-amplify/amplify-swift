//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

protocol AdvancedSecurityBehavior {

    func userContextData(for username: String,
                         deviceInfo: ASFDeviceBehavior,
                         appInfo: ASFAppInfoBehavior,
                         configuration: UserPoolConfigurationData) throws -> String
}

protocol ASFDeviceBehavior {

    var id: String { get }

    var model: String { get }

    var name: String { get }

    var platform: String { get }

    var version: String { get }

    var thirdPartyId: String? { get }

    var height: String { get }

    var width: String { get }

    var locale: String { get }

    var type: String { get }

    func deviceInfo() -> String
}

protocol ASFAppInfoBehavior {

    var name: String? { get }

    var targetSDK: String { get }

    var version: String { get }

}
