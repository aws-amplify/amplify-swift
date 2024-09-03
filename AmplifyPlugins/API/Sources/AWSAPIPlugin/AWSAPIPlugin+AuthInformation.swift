//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPluginsCore
import Foundation

public extension AWSAPIPlugin {
    func defaultAuthType() throws -> AWSAuthorizationType {
        try defaultAuthType(for: nil)
    }

    func defaultAuthType(for apiName: String?) throws -> AWSAuthorizationType {
        try pluginConfig.endpoints.getConfig(for: apiName).authorizationType
    }
}
