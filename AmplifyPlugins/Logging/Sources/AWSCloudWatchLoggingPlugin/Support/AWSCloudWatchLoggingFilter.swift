//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import AWSPluginsCore

class AWSCloudWatchLoggingFilter: AWSCloudWatchLoggingFilterBehavior{
    let loggingConstraintsResolver: AWSCloudWatchLoggingConstraintsResolver
    
    private var loggingConstraints: LoggingConstraints {
        return loggingConstraintsResolver.getLoggingConstraints()
    }
    
    init(loggingConstraintsResolver: AWSCloudWatchLoggingConstraintsResolver) {
        self.loggingConstraintsResolver = loggingConstraintsResolver
    }
    
    func canLog(withCategory: String, logLevel: LogLevel, userIdentifier: String?) -> Bool {
        if let userConstraints = loggingConstraints.userLogLevel.first(where: { $0.key == userIdentifier })?.value {
            // 1. look for user constraint, is category and log level enabled for this user
            if let categoryLogLevel = userConstraints.categoryLogLevel.first(where: { $0.key == withCategory })?.value {
                return logLevel.rawValue >= categoryLogLevel.rawValue
            }
            return logLevel.rawValue >= userConstraints.defaultLogLevel.rawValue
            
        } else if let categoryLogLevel = loggingConstraints.categoryLogLevel.first(where: { $0.key == withCategory })?.value {
            // 2. look for category constraint, is category and log level enabled
            return logLevel.rawValue >= categoryLogLevel.rawValue
        } else {
            // 3. look for default constraint
            return logLevel.rawValue >= loggingConstraints.defaultLogLevel.rawValue
        }
    }
}

