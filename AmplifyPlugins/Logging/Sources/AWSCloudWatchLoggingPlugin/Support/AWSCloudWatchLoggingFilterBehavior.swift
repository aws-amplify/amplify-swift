//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

/// Defines the default AWSCloudWatchLoggingFilterBehavior to conforms to
protocol AWSCloudWatchLoggingFilterBehavior {
    func canLog(withCategory: String, logLevel: LogLevel, userIdentifier: String?) -> Bool
    func getDefaultLogLevel(forCategory: String, userIdentifier: String?) -> LogLevel
}
