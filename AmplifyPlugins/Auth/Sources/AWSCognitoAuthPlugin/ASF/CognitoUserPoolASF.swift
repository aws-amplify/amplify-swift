//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import UIKit

protocol CognitoUserPoolASFBehavior {

    func userContextData(deviceInfo: ASFDeviceBehavior,
                         appInfo: ASFAppInfoBehavior,
                         configuration: UserPoolConfigurationData) -> String
}

protocol ASFDeviceBehavior {

    var id: String { get }

    var model: String { get }

    var name: String { get }

    var version: String { get }

    var thirdPartyId: String? { get }

    var height: String { get }

    var width: String { get }

    func deviceInfo() -> String
}

protocol ASFAppInfoBehavior {

    var name: String? { get }

    var targetSDK: String { get }

    var version: String { get }

}
