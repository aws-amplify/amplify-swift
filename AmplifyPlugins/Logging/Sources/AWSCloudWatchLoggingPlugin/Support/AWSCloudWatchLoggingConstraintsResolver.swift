//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import AWSPluginsCore

/// Provides resolver to return the active/valid log constraints to use for the logging plugin
class AWSCloudWatchLoggingConstraintsResolver {
    let loggingPluginConfiguration: AWSCloudWatchLoggingPluginConfiguration
    let loggingConstraintsLocalStore: LoggingConstraintsLocalStore
    
    init(loggingPluginConfiguration: AWSCloudWatchLoggingPluginConfiguration, loggingConstraintsLocalStore: LoggingConstraintsLocalStore = UserDefaults.standard) {
        self.loggingPluginConfiguration = loggingPluginConfiguration
        self.loggingConstraintsLocalStore = loggingConstraintsLocalStore
    }
    
    /// Returns the active valid logging constraints
    ///
    /// - Returns: the LoggingConstraints
    func getLoggingConstraints() -> LoggingConstraints {
        if let remoteConstraints = loggingConstraintsLocalStore.getLocalLoggingConstraints() {
            return remoteConstraints
        } else {
            return loggingPluginConfiguration.loggingConstraints
        }
    }
}
