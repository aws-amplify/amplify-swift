//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import AWSPluginsCore

protocol LoggingConstraintsLocalStore {
    func getLocalLoggingConstraints() -> LoggingConstraints?
    func setLocalLoggingConstraints(loggingConstraints: LoggingConstraints)
    func getLocalLoggingConstraintsEtag() -> String?
    func setLocalLoggingConstraintsEtag(etag: String)
}

extension UserDefaults: LoggingConstraintsLocalStore {
    func getLocalLoggingConstraints() -> LoggingConstraints? {
        UserDefaults.standard.object(forKey: PluginConstants.awsRemoteLoggingConstraintsKey) as? LoggingConstraints
    }
    
    func setLocalLoggingConstraints(loggingConstraints: LoggingConstraints) {
        UserDefaults.standard.set(loggingConstraints, forKey: PluginConstants.awsRemoteLoggingConstraintsKey)
    }
    
    func getLocalLoggingConstraintsEtag() -> String? {
        return UserDefaults.standard.string(forKey: PluginConstants.awsRemoteLoggingConstraintsTagKey)
    }
    
    func setLocalLoggingConstraintsEtag(etag: String) {
        UserDefaults.standard.set(etag, forKey: PluginConstants.awsRemoteLoggingConstraintsTagKey)
    }
}
