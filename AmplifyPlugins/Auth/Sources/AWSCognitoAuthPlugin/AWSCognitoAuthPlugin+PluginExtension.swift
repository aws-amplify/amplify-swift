//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import ClientRuntime
import Foundation
@_spi(InternalAmplifyPluginExtension) import InternalAmplifyCredentials

public extension AWSCognitoAuthPlugin {
    @_spi(InternalAmplifyPluginExtension)
    func add(pluginExtension: AWSPluginExtension) {
        if let customHttpEngine = pluginExtension as? HttpClientEngineProxy {
            httpClientEngineProxy = customHttpEngine
        }
    }
}
