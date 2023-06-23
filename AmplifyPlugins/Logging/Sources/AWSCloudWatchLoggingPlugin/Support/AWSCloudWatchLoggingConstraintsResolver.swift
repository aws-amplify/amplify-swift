//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import AWSPluginsCore

class AWSCloudWatchLoggingConstraintsResolver {
    let loggingPluginConfigProvider: AWSCloudWatchLoggingPluginConfiguration
    let loggingConstraintsLocalStore: LoggingConstraintsLocalStore
    
    init(loggingPluginConfigProvider: AWSCloudWatchLoggingPluginConfiguration, loggingConstraintsLocalStore: LoggingConstraintsLocalStore = UserDefaults.standard) {
        self.loggingPluginConfigProvider = loggingPluginConfigProvider
        self.loggingConstraintsLocalStore = loggingConstraintsLocalStore
    }
    
    func getLoggingConstraints() -> LoggingConstraints {
        if let remoteConstraints = loggingConstraintsLocalStore.getLocalLoggingConstraints() {
            return remoteConstraints
        } else {
            return loggingPluginConfigProvider.loggingConstraints
        }
    }
}
