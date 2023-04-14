//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(InternalAmplifyPluginExtension) import AWSPluginsCore
import Foundation
import ClientRuntime

extension AWSCognitoAuthPlugin {
    @_spi(InternalAmplifyPluginExtension)
    public func add(pluginExtension: AWSPluginExtension) {
        if let customHttpEngine = pluginExtension as? HttpClientEngineProxy {
            self.httpClientEngineProxy = customHttpEngine
        }
    }
}
