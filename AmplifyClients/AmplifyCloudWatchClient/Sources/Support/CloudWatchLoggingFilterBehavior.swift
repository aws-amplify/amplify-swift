//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AmplifyFoundation
import Foundation

/// Defines the filtering behavior for CloudWatch logging.
protocol CloudWatchLoggingFilterBehavior: Sendable {
    func canLog(withNamespace: String?, logLevel: LogLevel, userIdentifier: String?) -> Bool
    func getDefaultLogLevel(forNamespace: String?, userIdentifier: String?) -> LogLevel
}
