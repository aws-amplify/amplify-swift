//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// The mode of operation for the SDK's retry mechanism.
///
/// This may be specified using the `AWS_RETRY_MODE` environment var, or the `retry_mode` field of the AWS config file.
public enum AWSRetryMode: String {

    /// Use the retry behavior that this SDK implemented before the "Retry Behavior 2.0" spec.
    /// For the Swift SDK, this is the same behavior as standard.
    case legacy

    /// Use "Standard" retry behavior.  Initial requests are always made immediately, but retries
    /// are delayed using exponential backoff.  Retries are performed up to the specified maximum
    /// number, but may be further limited by a token system.
    case standard

    /// Use "Adaptive" retry behavior.  Like "Standard" but requests may be additionally delayed
    /// according to a rate limiting scheme that is designed to reduce congestion when throttling
    /// is taking place.
    case adaptive
}
