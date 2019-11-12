//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Protocol for the connection to make it retryable.
protocol RetryableConnection {

    /// Adds a RetryHandler for the connection. The retry handler checks the error
    /// and decides whether to retry or not.
    /// - Parameter handler
    func addRetryHandler(handler: ConnectionRetryHandler)

}

/// Protocol for connection retry handler.
protocol ConnectionRetryHandler {

    /// Check if we should retry the request or not.
    /// - Parameter error: Connection provider error.
    func shouldRetryRequest(for error: ConnectionProviderError) -> AWSAppSyncRetryAdvice

}

/// Encapsulates advice about whether a request should be retried, and if so, after how much time
struct AWSAppSyncRetryAdvice {
    let shouldRetry: Bool
    let retryInterval: DispatchTimeInterval?
}
