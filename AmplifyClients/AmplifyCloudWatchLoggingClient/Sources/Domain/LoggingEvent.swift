//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Represents a logging event that can be observed by consumers.
@_spi(AmplifyExperimental)
public enum LoggingEvent: @unchecked Sendable {
    /// A log entry failed to be written to local storage.
    case writeLogFailure(context: String? = nil, error: Error? = nil)

    /// Log entries failed to be flushed to CloudWatch.
    case flushLogFailure(context: String? = nil, error: Error? = nil)
}
