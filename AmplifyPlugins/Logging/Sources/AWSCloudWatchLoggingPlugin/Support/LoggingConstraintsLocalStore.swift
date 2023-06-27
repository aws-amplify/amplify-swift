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
        if let data = UserDefaults.standard.object(forKey: PluginConstants.awsRemoteLoggingConstraintsKey) as? Data {
            return try? JSONDecoder().decode(LoggingConstraints.self, from: data)
        }
        return nil
    }
    
    func setLocalLoggingConstraints(loggingConstraints: LoggingConstraints) {
        if let encoded = try? JSONEncoder().encode(loggingConstraints) {
            UserDefaults.standard.set(encoded, forKey: PluginConstants.awsRemoteLoggingConstraintsKey)
        }
    }
    
    func getLocalLoggingConstraintsEtag() -> String? {
        return UserDefaults.standard.string(forKey: PluginConstants.awsRemoteLoggingConstraintsTagKey)
    }
    
    func setLocalLoggingConstraintsEtag(etag: String) {
        UserDefaults.standard.set(etag, forKey: PluginConstants.awsRemoteLoggingConstraintsTagKey)
    }
}
