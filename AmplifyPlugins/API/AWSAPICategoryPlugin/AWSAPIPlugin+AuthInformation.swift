//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPluginsCore
import Foundation

extension AWSAPIPlugin {
    public func defaultAuthType() throws -> AWSAuthorizationType {
        try defaultAuthType(for: nil)
    }

    public func defaultAuthType(for apiName: String?) throws -> AWSAuthorizationType {
        guard let pluginConfig = pluginConfig else {
            throw PluginError.pluginConfigurationError("pluginConfig not yet configured", "")
        }
        return try pluginConfig.endpoints.getConfig(for: apiName).authorizationType
    }
}
