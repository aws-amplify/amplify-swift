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
    let loggingPluginConfiguration: AWSCloudWatchLoggingPluginConfiguration
    let loggingConstraintsLocalStore: LoggingConstraintsLocalStore
    
    init(loggingPluginConfiguration: AWSCloudWatchLoggingPluginConfiguration, loggingConstraintsLocalStore: LoggingConstraintsLocalStore = UserDefaults.standard) {
        self.loggingPluginConfiguration = loggingPluginConfiguration
        self.loggingConstraintsLocalStore = loggingConstraintsLocalStore
    }
    
    func getLoggingConstraints() -> LoggingConstraints {
        if let remoteConstraints = loggingConstraintsLocalStore.getLocalLoggingConstraints() {
            return remoteConstraints
        } else {
            return loggingPluginConfiguration.loggingConstraints
        }
    }
}
