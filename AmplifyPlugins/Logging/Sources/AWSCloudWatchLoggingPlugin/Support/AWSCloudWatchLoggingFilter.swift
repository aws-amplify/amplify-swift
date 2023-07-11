//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import AWSPluginsCore

/// Provides the concrete implementation for the AWSCloudWatchLoggingFilterBehavior.
class AWSCloudWatchLoggingFilter: AWSCloudWatchLoggingFilterBehavior {
    let loggingConstraintsResolver: AWSCloudWatchLoggingConstraintsResolver

    private var loggingConstraints: LoggingConstraints {
        return loggingConstraintsResolver.getLoggingConstraints()
    }

    init(loggingConstraintsResolver: AWSCloudWatchLoggingConstraintsResolver) {
        self.loggingConstraintsResolver = loggingConstraintsResolver
    }

    /// Checks to see if the specified category, log level, and user identifier allows for logging
    ///
    /// - Returns: A boolean value of whether filter allows logging
    func canLog(withCategory category: String, logLevel: LogLevel, userIdentifier: String?) -> Bool {
        guard logLevel != .none else { return false }
        let loweredCasedCategory = category.lowercased()

        // 1. look for user constraint, is category and log level enabled for this user
        if let userConstraints = loggingConstraints.userLogLevel?.first(where: { $0.key == userIdentifier })?.value {
            if let categoryLogLevel = userConstraints.categoryLogLevel.first(where: { $0.key.lowercased() == loweredCasedCategory })?.value {
                return logLevel.rawValue <= categoryLogLevel.rawValue && categoryLogLevel != .none
            }
            return logLevel.rawValue <= userConstraints.defaultLogLevel.rawValue && userConstraints.defaultLogLevel != .none

        }
        
        // 2. look for category constraint, is category and log level enabled
        if let categoryLogLevel = loggingConstraints.categoryLogLevel?.first(where: { $0.key.lowercased() == loweredCasedCategory })?.value {
            
            return logLevel.rawValue <= categoryLogLevel.rawValue && categoryLogLevel != .none
        }
        
        // 3. look for default constraint
        return logLevel.rawValue <= loggingConstraints.defaultLogLevel.rawValue && loggingConstraints.defaultLogLevel != .none
    }

    /// Returns the default log level for a specified category and user identifier
    ///
    /// - Returns: the default LogLevel
    func getDefaultLogLevel(forCategory category: String, userIdentifier: String?) -> LogLevel {
        let loweredCasedCategory = category.lowercased()
        
        if let userConstraints = loggingConstraints.userLogLevel?.first(where: { $0.key == userIdentifier })?.value {
            if let categoryLogLevel = userConstraints.categoryLogLevel.first(where: { $0.key.lowercased() == loweredCasedCategory })?.value {
                return categoryLogLevel
            }
            return userConstraints.defaultLogLevel
        }
        
        if let categoryLogLevel = loggingConstraints.categoryLogLevel?.first(where: { $0.key.lowercased() == loweredCasedCategory })?.value {
            return categoryLogLevel
        }
        
        return loggingConstraints.defaultLogLevel
    }
}
